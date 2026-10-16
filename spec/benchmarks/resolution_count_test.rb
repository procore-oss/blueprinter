# frozen_string_literal: true

require 'blueprint_benchmark_helper'

# How often per-field setup work runs during a render.
#
# Some work in Blueprinter is a property of the *field definition*, not of the object being
# rendered: resolving a field's :if/:unless condition, choosing its extractor, deciding its datetime
# format. Such work must be resolved once per field and reused, never recomputed per object.
#
# This benchmark counts invocations of a chosen method across growing collections and asserts
# scale-invariance: the count must depend only on the field count, never on the object count. That
# assertion is fully machine independent -- unlike a wall-clock threshold, it cannot be made to pass
# by faster hardware, so it holds equally on a laptop and a loaded CI runner.
#
# It is the check that would have caught the Field#skip? memoization bug, where
# `@_if_callable ||= callable_from(:if)` failed to memoize a `false` result and so re-resolved both
# conditions for every field of every object: 12,000 resolutions to render 1,000 six-field objects
# where 12 suffice.
#
# To watch a different method, add a row to WATCHED.
module Blueprinter
  class ResolutionCountTest < Minitest::Test
    include BlueprintBenchmarkHelper

    # [class, method, invocations expected per field, description]
    WATCHED = [
      [Blueprinter::Field, :callable_from, 2, 'once per :if and once per :unless']
    ].freeze

    # All at a fixed field count, so any growth is attributable to the collection size alone.
    OBJECT_COUNTS = [1, 10, 100, 1000].freeze
    FIELD_COUNT = 6

    ROW = '      %<objects>-9d %<fields>-7d %<count>13d %<per_object>12.1f   %<assessment>s'
    HEADER = '      %<objects>-9s %<fields>-7s %<count>13s %<per_object>12s   %<assessment>s'

    def test_per_field_work_does_not_repeat_per_object
      section('PER-FIELD RESOLUTION COUNT', <<~TEXT)
        Counts how often per-field setup runs during a single render.
        This work cannot change between objects, so the count should depend ONLY on
        the field count -- never on the object count.

        Expected: fields x invocations-per-field, constant across collection sizes.
      TEXT

      WATCHED.each { |(klass, method_name, per_field, description)| report(klass, method_name, per_field, description) }
    end

    private

    def report(klass, method_name, per_field, description)
      expected = FIELD_COUNT * per_field
      counts = measure(klass, method_name)

      puts format('      %<klass>s#%<method>s -- %<description>s',
                  klass: klass.name.split('::').last, method: method_name, description: description)
      puts
      puts format(HEADER, objects: 'objects', fields: 'fields', count: 'invocations',
                          per_object: 'per object', assessment: 'assessment')
      divider(64)

      counts.each do |object_count, count|
        assessment = count == expected ? 'constant (ideal)' : "#{count / expected}x the ideal #{expected}"
        puts format(ROW, objects: object_count, fields: FIELD_COUNT, count: count,
                         per_object: count.to_f / object_count, assessment: assessment)
      end

      print_verdict(counts, expected)
      assert_scale_invariant(counts, expected, klass, method_name)
    end

    # A fresh Blueprint per row: this memoisation is per Field instance, so reusing one Blueprint would
    # report zero on every subsequent row and prove nothing.
    def measure(klass, method_name)
      OBJECT_COUNTS.to_h do |object_count|
        blueprint, objects = build_blueprint(FIELD_COUNT, object_count)
        [object_count, count_calls(klass, method_name) { blueprint.render(objects) }]
      end
    end

    def print_verdict(counts, expected)
      puts
      if counts.values.uniq == [expected]
        puts '      => RESOLVED ONCE PER FIELD. Count stays flat as the collection grows.'
        return
      end

      worst = counts[OBJECT_COUNTS.last]
      puts '      => REPEATED PER OBJECT. Count grows linearly with the collection:'
      puts format('         %<worst>d invocations to render %<objects>d objects, where %<expected>d ' \
                  'suffice (%<factor>dx waste).',
                  worst: worst, objects: OBJECT_COUNTS.last, expected: expected, factor: worst / expected)
    end

    def assert_scale_invariant(counts, expected, klass, method_name)
      counts.each do |object_count, count|
        assert_equal(
          expected, count,
          "#{klass}##{method_name} ran #{count} times to render #{object_count} objects; expected " \
          "#{expected} (#{FIELD_COUNT} fields). Per-field work must be resolved once and reused, not " \
          'recomputed per object. Beware `||=` memoisation of a method that can legitimately return ' \
          'false or nil -- use a `defined?` guard instead.'
        )
      end
    end
  end
end
