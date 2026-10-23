# frozen_string_literal: true

require 'benchmark_helper'

# Objects allocated per render, with GC disabled during measurement.
#
# Rendering a collection should allocate O(1) objects per rendered object -- essentially the one
# result Hash -- and NOT O(fields). A Hash counts as a single object however many keys it holds, so
# widening a Blueprint from 6 to 12 fields should barely move the total.
#
# Both assertions are machine independent, and unaffected by CPU-only optimisations. With all-String
# field values, JSON encoding allocates almost nothing; a raw Time field would add allocations per
# object during encoding, which is why the fixtures avoid them.
module Blueprinter
  class AllocationsTest < Minitest::Test
    include BenchmarkHelper

    # Allocations per rendered object. Expected ~1 (the result Hash); one object of headroom so a
    # differing json version cannot make this flaky, while still catching any per-field allocation.
    MAX_PER_OBJECT = 2

    # Extra allocations per rendered object when widening from 6 to 12 fields. Compared as a
    # difference, not a ratio: the fixed result Hash keeps (1 + 12k) / (1 + 6k) below 2 for any
    # per-field leak k, so a ratio bound could never fail.
    MAX_WIDENING_DELTA = 0.5

    ROW = '      %<shape>-26s %<total>14d %<per_object>14.1f'
    HEADER = '      %<shape>-26s %<total>14s %<per_object>14s'

    def test_render_allocations
      section('RENDER ALLOCATIONS', <<~TEXT)
        Objects allocated per render, with GC disabled during measurement.
        Rendering should allocate O(1) objects per rendered object -- the result Hash --
        and not O(fields), since a Hash is one object regardless of key count.
      TEXT

      per_object = measure_shapes

      # Only the 1000-object shapes are asserted. Rendering has a fixed allocation overhead (~9
      # objects) that is independent of collection size, so on the smaller shapes it dominates the
      # per-object figure (the 1-object shape alone sits around 10/object) and would trip MAX_PER_OBJECT
      # without any per-field leak. At 1000 objects that overhead is amortised to nearly nothing.
      [LARGE_SHAPE, WIDE_SHAPE].each do |label|
        assert_operator per_object[label], :<, MAX_PER_OBJECT,
                        "#{label} allocated #{per_object[label].round(1)} objects per rendered object; " \
                        'expected ~1 (the result Hash). Allocations should not scale with field count.'
      end

      delta = per_object[WIDE_SHAPE] - per_object[LARGE_SHAPE]
      puts
      puts format('      doubling fields at 1000 objects: %<delta>+.2f allocations per object', delta: delta)

      assert_operator delta, :<, MAX_WIDENING_DELTA,
                      "Doubling the field count added #{delta.round(2)} allocations per object. A Hash is one " \
                      'object regardless of key count, so this suggests a per-field allocation.'
    end

    private

    # Returns allocations per rendered object, keyed by shape label.
    def measure_shapes
      puts format(HEADER, shape: 'shape', total: 'allocations', per_object: 'per object')
      divider(58)

      SHAPES.to_h do |(label, field_count, object_count)|
        blueprint, objects = build_blueprint(field_count, object_count)
        blueprint.render(objects) # prime lazily-built caches so one-off setup is excluded
        count = allocations { blueprint.render(objects) }
        per_object = count.to_f / object_count

        puts format(ROW, shape: label, total: count, per_object: per_object)
        [label, per_object]
      end
    end
  end
end
