# frozen_string_literal: true

# Measures rendering across one-factor-at-a-time sweeps and realistic profiles. Runs V1 always, and V2 and V2+Legacy
# when `Blueprinter::V2` is defined.
#
#   bundle exec rake engines
#   SWEEPS=input_kind,size SAMPLES=5 SIZES=1,100 bundle exec rake engines
#   RUBYOPT=--yjit bundle exec rake engines
#   BASELINE=benchmarks/results/engines-before.json bundle exec rake engines
#
# Knobs: SWEEPS (comma-separated names, default all), SAMPLES (max samples per engine, default 40), SIZES (the size
# sweep's values, `object` for a single object), SAMPLE_MS, BUDGET_S, GC_MS, WARMUP_MS, SEED, PROFILE=0 to skip
# allocation-site tracing, LIST=1 to list sweeps, OUT_DIR (default benchmarks/results), BASELINE (a results JSON file
# to print the change against).

require 'blueprinter'
require 'oj'

Blueprinter::Base # `Blueprinter::Extractor` is only loaded along with Base

# Optional gems. Scenarios that need one are skipped, with the reason listed in the report, when it isn't installed.
multi_json = begin
  require 'multi_json'
  true
rescue LoadError
  false
end
opentelemetry = begin
  require 'opentelemetry-api'
  true
rescue LoadError
  false
end

require_relative 'harness'
EngineBench.provide(:multi_json, multi_json)
EngineBench.provide(:opentelemetry, opentelemetry)
require_relative 'fixtures'
require_relative 'records'
require_relative 'blueprints'
require_relative 'runner'
require_relative 'report'
require_relative 'profile'
require_relative 'compare'
Dir[File.join(__dir__, 'sweeps', '*.rb')].each { |f| require f }

module EngineBench
  ORDER = %w[input_kind size width depth fanout association_kind repeated_children sparsity defaults value_types
             field_kinds conditions views transform hooks render_options output lifecycle concurrency breakdown
             profiles].freeze

  PROFILED = [
    ['input_kind', 'Hash (Symbol keys)'],
    %w[input_kind ActiveRecord],
    ['field_kinds', 'block (1 arg)'],
    ['value_types', 'Time, formatted (global)'],
    ['profiles', 'AR orders: 100 orders to a Hash, depth 4'],
    ['profiles', 'Hash export: 5,000 rows, 12 fields, no associations']
  ].freeze

  class << self
    def selected_sweeps
      names = ENV.fetch('SWEEPS', '').split(',').map(&:strip).reject(&:empty?)
      names = (ORDER & sweeps.keys) + (sweeps.keys - ORDER) if names.empty?
      unknown = names - sweeps.keys
      abort "Unknown sweeps: #{unknown.join(', ')}. Known: #{sweeps.keys.join(', ')}" unless unknown.empty?
      names.map { |n| sweeps.fetch(n) }
    end

    def main
      if ENV['LIST']
        sweeps.each_value { |s| puts "#{s.name.ljust(20)} #{s.title} (#{s.scenarios.size} scenarios)" }
        return
      end

      abort "BASELINE not found: #{ENV['BASELINE']}" if ENV['BASELINE'] && !File.file?(ENV['BASELINE'])

      MultiJson.use(:oj) if feature?(:multi_json)
      runner = Runner.new(Runner.knobs_from_env)
      report = Report.new(runner.knobs)
      selected_sweeps.each do |sweep|
        warn "sweep #{sweep.name}"
        results = sweep.custom ? sweep.custom.call(runner) : sweep.scenarios.map { |s| run_scenario(runner, s) }
        report.add_sweep(sweep, results)
      end
      profile(report) unless ENV['PROFILE'] == '0'
      path = report.finish!
      puts report.markdown
      puts "\nJSON: #{path}"
      compare(ENV.fetch('BASELINE'), path) if ENV['BASELINE']
    end

    def compare(baseline, current)
      puts "\n#{Compare.new(baseline, current).markdown}"
    end

    def run_scenario(runner, scenario)
      warn "  #{scenario.label}"
      started = Process.clock_gettime(Process::CLOCK_MONOTONIC)
      result = runner.run(scenario)
      result[:seconds] = (Process.clock_gettime(Process::CLOCK_MONOTONIC) - started).round(2)
      result
    end

    def profile(report)
      PROFILED.each do |sweep_name, label|
        scenario = sweeps.fetch(sweep_name).scenarios.find { |s| s.label == label } or raise "no scenario #{label}"
        warn "profile #{sweep_name}/#{label}"
        report.add_profile(profile_scenario(scenario, "#{sweep_name} / #{label}"))
      end
    end

    def profile_scenario(scenario, name)
      Blueprinter.reset_configuration!
      scenario.v1_config&.call(Blueprinter.configuration)
      setup = scenario.build.call
      input = Runner.input_for(setup, scenario)
      engines = setup.engines.to_h { |e| [e.name, e] }
      gate = Gate.new(engines, input).check
      engines = engines.except(*gate.excluded.keys)
      { scenario: name, description: 'Top allocation sites for one warm render.',
        engines: engines.transform_values { |eng| Profile.allocation_sites(eng, input, gate.rendered_objects) } }
    ensure
      Blueprinter.reset_configuration!
    end
  end
end

EngineBench.main
