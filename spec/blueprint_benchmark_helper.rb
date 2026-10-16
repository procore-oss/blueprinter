# frozen_string_literal: true

require 'minitest/autorun'
require 'blueprinter'
require 'blueprinter/base'
require 'blueprinter/field'

# Shared primitives for the Blueprinter benchmarks.
#
# Deliberately generic: nothing here knows about any particular optimisation. Each benchmark file
# measures one dimension over the same matrix of shapes --
#
#   throughput_test.rb       wall time per render and per object
#   allocations_test.rb      objects allocated per render
#   resolution_count_test.rb how often per-field work runs, per render
#
# -- so adding a benchmark means describing what to measure and asserting its own invariant, not
# rebuilding the scaffolding.
#
# Assertions in these files are deliberately scale- or shape-relative rather than absolute
# wall-clock thresholds, so they remain meaningful on a slow or loaded CI runner. An absolute bound
# loose enough not to be flaky is usually too loose to catch anything.
module BlueprintBenchmarkHelper
  # [label, field_count, object_count]
  #
  # The 6-field rows at 100 and 1000 objects support linearity checks; the 12-field row at 1000
  # isolates the effect of field count at a fixed collection size.
  SHAPES = [
    ['1 object    x  6 fields', 6, 1],
    ['100 objects x  6 fields', 6, 100],
    ['1000 objects x  6 fields', 6, 1000],
    ['1000 objects x 12 fields', 12, 1000]
  ].freeze

  SMALL_SHAPE = '100 objects x  6 fields'
  LARGE_SHAPE = '1000 objects x  6 fields'
  WIDE_SHAPE = '1000 objects x 12 fields'

  # Builds a Struct + Blueprint pair with the requested number of fields, and a collection of
  # objects to render.
  #
  # Struct rather than OpenStruct: OpenStruct's method_missing dominates the profile and would mask
  # the Blueprinter overhead being measured. All values are pre-existing Strings, so results reflect
  # Blueprinter's own behaviour rather than value coercion -- a raw Time field, for instance, costs
  # roughly four allocations of its own during JSON encoding, which would swamp the signal.
  def build_blueprint(field_count, object_count)
    names = Array.new(field_count) { |i| :"field_#{i}" }
    struct = Struct.new(*names, keyword_init: true)

    blueprint = Class.new(Blueprinter::Base)
    names.each { |name| blueprint.field(name) }

    objects = Array.new(object_count) do |i|
      struct.new(**names.to_h { |name| [name, "#{name}-#{i}"] })
    end

    [blueprint, objects]
  end

  # Counts invocations of klass#method_name during the block.
  def count_calls(klass, method_name, &)
    count = 0
    tracer = TracePoint.new(:call) do |tp|
      count += 1 if tp.method_id == method_name && tp.defined_class == klass
    end
    tracer.enable(&)
    tracer.disable
    count
  end

  # Auto-calibrating timer. Returns { median:, best: } in seconds per call.
  #
  # NB: deliberately not named `time` -- that shadows Minitest::Runnable#time, which minitest calls
  # internally when constructing a result, raising LocalJumpError.
  def sample_duration(samples: 7, min_sample_seconds: 0.1, &block)
    yield # warm up, and prime any lazy caches

    started = Process.clock_gettime(Process::CLOCK_MONOTONIC)
    yield
    single = Process.clock_gettime(Process::CLOCK_MONOTONIC) - started
    iterations = single >= min_sample_seconds ? 1 : [(min_sample_seconds / [single, 1e-9].max).ceil, 100_000].min

    durations = Array.new(samples) do
      start = Process.clock_gettime(Process::CLOCK_MONOTONIC)
      iterations.times(&block)
      (Process.clock_gettime(Process::CLOCK_MONOTONIC) - start) / iterations
    end.sort

    { median: durations[durations.size / 2], best: durations.first }
  end

  # Objects allocated during the block, with GC held off so collection cannot skew the count.
  def allocations
    GC.start
    GC.disable
    before = GC.stat[:total_allocated_objects]
    yield
    after = GC.stat[:total_allocated_objects]
    GC.enable
    after - before
  end

  def section(title, explanation)
    puts
    puts title
    explanation.each_line { |line| puts "      #{line.rstrip}" }
    puts
  end

  def divider(width)
    puts format('      %s', '-' * width)
  end
end
