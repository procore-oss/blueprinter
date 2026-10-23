# frozen_string_literal: true

require 'minitest/autorun'
require 'minitest/benchmark'
require 'blueprinter'
# Not redundant: blueprinter.rb only autoloads Base, and resolution_count_test.rb names
# Blueprinter::Field at class-body time (in WATCHED), before any Base reference triggers the autoload.
require 'blueprinter/base'

# Shared primitives for the benchmarks under spec/benchmarks.
#
# The shape-matrix benchmarks each measure one dimension over the same SHAPES:
#
#   throughput_test.rb        wall time per render and per object
#   allocations_test.rb       objects allocated per render
#   resolution_count_test.rb  how often per-field work runs, per render
#
# Their assertions are deliberately relative (across shapes or collection sizes) rather than
# absolute wall-clock thresholds, so they stay meaningful on a slow or loaded CI runner. An absolute
# bound loose enough not to be flaky is usually too loose to catch anything.
module BenchmarkHelper
  # [label, field_count, object_count]
  #
  # The 6-field rows at 100 and 1000 objects support linearity checks; the 12-field row at 1000
  # isolates the effect of field count at a fixed collection size.
  SHAPES = [
    ['   1 object  x  6 fields', 6, 1],
    [' 100 objects x  6 fields', 6, 100],
    ['1000 objects x  6 fields', 6, 1000],
    ['1000 objects x 12 fields', 12, 1000]
  ].freeze

  # Labels looked up by (field_count, object_count) rather than by position, so reordering SHAPES
  # cannot silently pair the assertions with the wrong rows.
  def self.shape_label(field_count, object_count)
    shape = SHAPES.find { |(_, fields, objects)| fields == field_count && objects == object_count }
    raise ArgumentError, "no shape with #{field_count} fields x #{object_count} objects" unless shape

    shape.first
  end

  SMALL_SHAPE = shape_label(6, 100)
  LARGE_SHAPE = shape_label(6, 1000)
  WIDE_SHAPE = shape_label(12, 1000)

  # Iterations completed in one second of wall time.
  def iterate
    start = Process.clock_gettime(Process::CLOCK_MONOTONIC)
    count = 0
    while Process.clock_gettime(Process::CLOCK_MONOTONIC) - start <= 1
      yield
      count += 1
    end
    count
  end

  # Builds a Struct + Blueprint pair with the requested number of fields, and a collection of
  # objects to render.
  #
  # Struct rather than OpenStruct: OpenStruct's method_missing dominates the profile and would mask
  # the Blueprinter overhead being measured. All values are pre-existing Strings, so results reflect
  # Blueprinter's own behaviour rather than value coercion -- a raw Time field, for instance, costs
  # several allocations of its own during JSON encoding, which would swamp the signal.
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
    count
  end

  # Auto-calibrating timer. Returns { median:, best: } in seconds per call.
  #
  # NB: deliberately not named `time` -- that shadows Minitest::Runnable#time, which minitest calls
  # internally when constructing a result, raising LocalJumpError.
  def sample_duration(samples: 7, min_sample_seconds: 0.1, &block)
    yield # warm up, and prime any lazy caches

    single = clock(&block)
    iterations = single >= min_sample_seconds ? 1 : [(min_sample_seconds / [single, 1e-9].max).ceil, 100_000].min

    durations = Array.new(samples) { clock { iterations.times(&block) } / iterations }.sort

    { median: durations[durations.size / 2], best: durations.first }
  end

  # Objects allocated during the block.
  #
  # :total_allocated_objects is a monotonic counter -- GC frees objects but never decrements it -- so
  # the count is exact whether or not a collection runs. GC is held off anyway so the block's
  # behaviour is deterministic (no finalizers or heap growth mid-measurement), and the caller's GC
  # state is restored afterwards. GC.stat(key) rather than GC.stat[key]: the latter allocates a Hash
  # that would be counted.
  def allocations
    GC.start
    was_disabled = GC.disable
    before = GC.stat(:total_allocated_objects)
    yield
    GC.stat(:total_allocated_objects) - before
  ensure
    GC.enable unless was_disabled
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

  private

  def clock
    start = Process.clock_gettime(Process::CLOCK_MONOTONIC)
    yield
    Process.clock_gettime(Process::CLOCK_MONOTONIC) - start
  end
end
