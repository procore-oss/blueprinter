# frozen_string_literal: true

require 'benchmark_helper'
require 'json'
require 'open3'
require 'rbconfig'

# Compares the JSON serializers Blueprinter can be configured with: full renders/sec, encode-only
# throughput and allocations on a pre-built hash, and how each one prints a raw Time.
#
# Every configuration runs in its own process (support/serializer_probe.rb). Oj.generate and
# Oj.mimic_JSON replace JSON.generate process-wide, and ActiveSupport changes how Time is encoded,
# so measuring them side by side in one process would skew every measurement taken after them.
#
# A report, not a guard: about 40 processes take over a minute, so it only runs when
# BENCH_SERIALIZERS=1. The one assertion is that every serializer produces the same parsed output
# for an all-String payload.
module Blueprinter
  class SerializersTest < Minitest::Test
    include BenchmarkHelper

    PROBE = File.expand_path('support/serializer_probe.rb', __dir__)

    SERIALIZERS = [
      ['json', 'JSON.generate (default)'],
      ['oj_generate', 'generator = Oj (Oj.generate)'],
      ['oj_compat', 'Oj.dump(mode: :compat)'],
      ['oj_rails', 'Oj.dump(mode: :rails)'],
      ['oj_mimic_json', 'Oj.mimic_JSON'],
      ['oj_optimize_rails', 'Oj.optimize_rails'],
      ['yajl', 'generator = Yajl::Encoder']
    ].freeze

    # Oj.optimize_rails exists to accelerate ActiveSupport's encoding, so it only runs with it loaded.
    ACTIVESUPPORT_ONLY = %w[oj_optimize_rails].freeze

    PAYLOADS = [
      ['strings', '1000 objects x 6 String fields'],
      ['mixed', '1000 objects: Integer, String, Float, Boolean, nil, raw Time'],
      ['mixed_datetime_format', 'same, with datetime_format on the Time field']
    ].freeze

    ROW = '      %<label>-30s %<render>11.0f %<render_allocs>8d %<encode>11.0f %<encode_allocs>8d  %<time>s'
    HEADER = '      %<label>-30s %<render>11s %<render_allocs>8s %<encode>11s %<encode_allocs>8s  %<time>s'

    def test_serializers
      skip 'set BENCH_SERIALIZERS=1 to run the serializer comparison' unless ENV['BENCH_SERIALIZERS'] == '1'

      section('SERIALIZERS', <<~TEXT)
        Each row runs in its own process. render/s is a full Blueprinter render; encode/s and its
        allocations encode a pre-built hash only. "*" marks a row where JSON.generate was replaced
        process-wide. Ruby #{RUBY_VERSION}, json #{JSON::VERSION}#{gem_version(' Oj', 'oj')}#{gem_version(' yajl-ruby', 'yajl-ruby')}.
      TEXT

      [false, true].each do |activesupport|
        PAYLOADS.each { |(payload, description)| report(payload, description, activesupport) }
      end
    end

    private

    def report(payload, description, activesupport)
      puts
      puts "      #{description}#{' -- ActiveSupport loaded' if activesupport}"
      puts format(HEADER, label: 'serializer', render: 'render/s', render_allocs: 'allocs',
                          encode: 'encode/s', encode_allocs: 'allocs', time: 'Time output')
      divider(110)

      parsed = SERIALIZERS.filter_map do |(name, label)|
        next if ACTIVESUPPORT_ONLY.include?(name) && !activesupport

        result = probe(name, payload, activesupport)
        marker = result['json_generate_replaced'] ? '*' : ' '
        puts format(ROW, label: "#{marker}#{label}", render: result['renders_per_sec'],
                         render_allocs: result['render_allocations'], encode: result['encodes_per_sec'],
                         encode_allocs: result['encode_allocations'], time: result['sample_time'] || '-')
        [label, result['parsed']]
      end

      assert_same_output(parsed) if payload == 'strings'
    end

    def probe(name, payload, activesupport)
      command = [RbConfig.ruby, '-Ilib', '-Ispec', PROBE, name, payload, activesupport ? '1' : '0']
      output, status = Open3.capture2e(*command)
      assert status.success?, "#{name} / #{payload} probe failed:\n#{output}"

      JSON.parse(output.lines.last)
    end

    def assert_same_output(parsed)
      expected = parsed.first.last
      parsed.each do |(label, output)|
        assert_equal expected, output, "#{label} produced different JSON than #{parsed.first.first}"
      end
    end

    def gem_version(prefix, name)
      spec = Gem.loaded_specs[name]
      spec ? "#{prefix} #{spec.version}" : ''
    end
  end
end
