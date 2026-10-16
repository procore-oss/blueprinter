# frozen_string_literal: true

require 'blueprint_benchmark_helper'

# Objects allocated per render, with GC disabled during measurement.
#
# Rendering a collection should allocate O(1) objects per rendered object -- essentially the one
# result Hash -- and NOT O(fields). A Hash counts as a single object however many keys it holds, so
# widening a Blueprint from 6 to 12 fields should barely move the total.
#
# Two relative assertions, both machine independent:
#
#   1. allocations per rendered object stays small (near 1)
#   2. doubling the field count does not double allocations
#
# Note these are unaffected by CPU-only optimisations. With all-String field values, JSON encoding
# allocates almost nothing; a raw Time field would add roughly one allocation per object during
# encoding, which is why the fixtures avoid them.
module Blueprinter
  class AllocationsTest < Minitest::Test
    include BlueprintBenchmarkHelper

    # Allocations per rendered object. Expected ~1 (the result Hash); bounded loosely so a differing
    # json version cannot make this flaky, while still catching per-field allocation.
    MAX_PER_OBJECT = 5

    # Doubling fields (6 -> 12) at a fixed collection size may not double allocations.
    MAX_WIDENING_GROWTH = 2

    ROW = '      %<shape>-26s %<total>14d %<per_object>14.1f'
    HEADER = '      %<shape>-26s %<total>14s %<per_object>14s'

    def test_render_allocations
      section('RENDER ALLOCATIONS', <<~TEXT)
        Objects allocated per render, with GC disabled during measurement.
        Rendering should allocate O(1) objects per rendered object -- the result Hash --
        and not O(fields), since a Hash is one object regardless of key count.
      TEXT

      totals = measure_shapes
      assert_per_object_is_constant(totals)
      assert_widening_is_cheap(totals)
    end

    private

    def measure_shapes
      totals = {}

      puts format(HEADER, shape: 'shape', total: 'allocations', per_object: 'per object')
      divider(58)

      SHAPES.each do |(label, field_count, object_count)|
        blueprint, objects = build_blueprint(field_count, object_count)
        blueprint.render(objects) # prime lazily-built caches so one-off setup is excluded
        count = allocations { blueprint.render(objects) }
        totals[label] = count

        puts format(ROW, shape: label, total: count, per_object: count.to_f / object_count)
      end

      totals
    end

    def assert_per_object_is_constant(totals)
      [[LARGE_SHAPE, 1000], [WIDE_SHAPE, 1000]].each do |(label, object_count)|
        per_object = totals[label].to_f / object_count
        assert_operator(
          per_object, :<, MAX_PER_OBJECT,
          format('%<shape>s allocated %<per_object>.1f objects per rendered object; expected ~1 ' \
                 '(the result Hash). Allocations should not scale with field count.',
                 shape: label, per_object: per_object)
        )
      end
    end

    def assert_widening_is_cheap(totals)
      six = totals[LARGE_SHAPE]
      twelve = totals[WIDE_SHAPE]

      puts
      puts format('      doubling fields at 1000 objects: %<six>d -> %<twelve>d allocations (%<factor>.2fx)',
                  six: six, twelve: twelve, factor: twelve.to_f / six)

      assert_operator(
        twelve, :<, six * MAX_WIDENING_GROWTH,
        format('Doubling the field count took allocations from %<six>d to %<twelve>d (%<factor>.2fx). ' \
               'A Hash is one object regardless of key count, so this suggests a per-field allocation.',
               six: six, twelve: twelve, factor: twelve.to_f / six)
      )
    end
  end
end
