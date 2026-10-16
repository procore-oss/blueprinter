# frozen_string_literal: true

require 'blueprint_benchmark_helper'

# Wall time to render each shape.
#
# Reports median and best of several samples, renders/sec, and microseconds per rendered object.
# "us/object" is the figure to compare across shapes, since it divides out collection size.
#
# The assertion is relative, not absolute: per-object cost must stay roughly flat as the collection
# grows tenfold. That catches an accidentally super-linear render path (an N+1 lookup, a per-object
# recompile) without depending on how fast the machine is.
module Blueprinter
  class ThroughputTest < Minitest::Test
    include BlueprintBenchmarkHelper

    # Per-object cost at 1000 objects may not exceed this multiple of the cost at 100 objects.
    # Generous enough to absorb CI noise, tight enough to catch quadratic behaviour.
    MAX_PER_OBJECT_GROWTH = 3

    ROW = '      %<shape>-26s %<median>11.3f %<best>11.3f %<rate>13.1f %<per_object>11.2f'
    HEADER = '      %<shape>-26s %<median>11s %<best>11s %<rate>13s %<per_object>11s'

    def test_render_throughput
      section('RENDER THROUGHPUT', <<~TEXT)
        Median of 7 samples, auto-calibrated so each sample runs >= 100ms.
        "us/object" is the most comparable figure across differing shapes.
      TEXT

      per_object = measure_shapes
      assert_linear_scaling(per_object)
    end

    private

    def measure_shapes
      per_object = {}

      puts format(HEADER, shape: 'shape', median: 'median ms', best: 'best ms',
                          rate: 'renders/sec', per_object: 'us/object')
      divider(76)

      SHAPES.each do |(label, field_count, object_count)|
        blueprint, objects = build_blueprint(field_count, object_count)
        timing = sample_duration { blueprint.render(objects) }
        micros = (timing[:median] * 1_000_000) / object_count
        per_object[label] = micros

        puts format(ROW, shape: label, median: timing[:median] * 1000, best: timing[:best] * 1000,
                         rate: 1.0 / timing[:median], per_object: micros)

        assert_operator timing[:median], :>, 0, "#{label} produced a non-positive median duration"
      end

      per_object
    end

    # The 1-object shape is excluded: fixed per-render overhead dominates it, making its per-object
    # figure both much higher and much noisier than the rest.
    def assert_linear_scaling(per_object)
      small = per_object[SMALL_SHAPE]
      large = per_object[LARGE_SHAPE]

      puts
      puts format('      per-object cost: %<small>.2fus at 100 objects -> %<large>.2fus at 1000 (%<factor>.2fx)',
                  small: small, large: large, factor: large / small)

      assert_operator(
        large, :<, small * MAX_PER_OBJECT_GROWTH,
        format('Per-object cost grew %<factor>.2fx (%<small>.2fus -> %<large>.2fus) going from 100 to ' \
               '1000 objects. Rendering should scale linearly with collection size.',
               factor: large / small, small: small, large: large)
      )
    end
  end
end
