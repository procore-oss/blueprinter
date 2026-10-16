# frozen_string_literal: true

require 'benchmark_helper'
require 'blueprinter'
require 'ostruct'

# Proves that Field#skip? resolves its :if/:unless callables once per field, rather than once per
# field *per rendered object*.
#
# Before the `defined?` guard in Field#if_callable/#unless_callable, `callable_from` returned `false`
# for the common "no condition configured" case, which `||=` refuses to memoize. Resolution --
# including a global `Blueprinter.configuration` lookup -- therefore ran on every field of every
# object, accounting for ~25% of total render wall time (measured with stackprof).
#
# The assertion here is scale-invariance: resolution count must not grow with the collection size.
class Blueprinter::FieldSkipMemoizationTest < Minitest::Test
  include BenchmarkHelper

  FIELD_COUNT = 6
  CONDITIONS_PER_FIELD = 2 # :if and :unless

  def setup
    @blueprinter = Class.new(Blueprinter::Base) do
      identifier :id
      field :name
      field :email
      field :status
      field :score
      field :active
    end
    @objects = build_objects(1000)
  end

  def build_objects(count)
    count.times.map do |i|
      OpenStruct.new(id: i, name: "obj #{i}", email: "u#{i}@x.com", status: 'active', score: i * 1.5, active: true)
    end
  end

  # Counts Field#callable_from invocations during a block.
  def count_resolutions
    count = 0
    tracer = TracePoint.new(:call) do |tp|
      count += 1 if tp.method_id == :callable_from && tp.defined_class == Blueprinter::Field
    end
    tracer.enable { yield }
    tracer.disable
    count
  end

  def test_callable_resolution_is_scale_invariant
    # A fresh Blueprint per sample: memoization is per Field instance, so reusing one would
    # trivially report zero on the second sample and prove nothing.
    counts = [1, 10, 1000].to_h do |n|
      blueprint = Class.new(Blueprinter::Base) do
        identifier :id
        field :name
        field :email
        field :status
        field :score
        field :active
      end
      objects = build_objects(n)
      [n, count_resolutions { blueprint.render(objects) }]
    end

    expected = FIELD_COUNT * CONDITIONS_PER_FIELD

    puts "\nField#callable_from invocations per render (#{FIELD_COUNT} fields):"
    counts.each do |n, count|
      puts format('  %5d objects -> %5d resolutions (%.1f per object)', n, count, count.to_f / n)
    end
    puts "  expected (fields x conditions): #{expected}"
    puts "  before fix, 1000 objects cost: #{expected * 1000} resolutions"

    counts.each do |n, count|
      assert_equal(
        expected, count,
        "Expected #{expected} callable resolutions for #{n} objects, got #{count}. " \
        'Field#if_callable/#unless_callable must memoize falsey results (use a `defined?` guard, not `||=`).'
      )
    end
  end

  def test_render_throughput
    result = iterate { @blueprinter.render(@objects) }
    puts "\nMemoized skip? IPS (1000 objects x #{FIELD_COUNT} fields): #{result}"
    assert_operator(result, :>, 0)
  end
end
