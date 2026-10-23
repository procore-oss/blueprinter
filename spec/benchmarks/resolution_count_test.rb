# frozen_string_literal: true

require 'benchmark_helper'

# How often per-field setup work runs during a render.
#
# Some work in Blueprinter is a property of the *field definition*, not of the object being
# rendered: resolving a field's :if/:unless condition, choosing its extractor, deciding its datetime
# format. Ideally such work is resolved once per field and reused, never recomputed per object.
#
# This benchmark counts invocations of a chosen method across growing collections and prints the
# count next to the ideal (fields x invocations-per-field). Work that is resolved once per field
# shows a flat count; work that is recomputed per object shows a count that grows with the
# collection. The count is machine independent, so it compares exactly across branches.
#
# This is a report, not a guard: it prints and never fails. Compare the per-object figure
# branch-to-branch (as with the other benchmarks) and treat a count above the baseline below as a
# regression -- future memoization would only lower it.
#
# Field#callable_from is expected to grow with the collection here: with no :if/:unless on the field
# or in the global config, a field re-checks the global config on every render until a condition is
# set, so that setting one later takes effect (docs/configuration.md#when-a-change-takes-effect). The
# fixtures set none, so the baseline is fields x 2 per object.
#
# To watch a different method, add a row to WATCHED.
module Blueprinter
  class ResolutionCountTest < Minitest::Test
    include BenchmarkHelper

    # [class, method, invocations expected per field, description]
    #
    # The traced render is the first one on a fresh Blueprint, deliberately: a method that is
    # resolved once per field would read 0 on a primed Blueprint, hiding the fields x N ideal. The
    # cost is that view compilation (ViewCollection) also runs inside the traced window, so only
    # watch methods that run at render time. A method that also runs during compilation would
    # include that one-off work in its count and make the ideal/render column wrong.
    WATCHED = [
      [Blueprinter::Field, :callable_from, 2,
       'once per :if and once per :unless; per object while no condition is set (by design)']
    ].freeze

    # All at a fixed field count, so any growth is attributable to the collection size alone.
    OBJECT_COUNTS = [1, 10, 100, 1000].freeze
    FIELD_COUNT = 6

    ROW = '      %<objects>-9d %<count>13d %<ideal>13d %<per_object>12.1f'
    HEADER = '      %<objects>-9s %<count>13s %<ideal>13s %<per_object>12s'

    def test_per_field_resolution_count
      section('PER-FIELD RESOLUTION COUNT', <<~TEXT)
        Counts how often per-field setup runs during a single render of #{FIELD_COUNT}-field objects.
        Ideal: fields x invocations-per-field, constant across collection sizes.
        A count that grows with the collection means the work is recomputed per object.
      TEXT

      WATCHED.each { |(klass, method_name, per_field, description)| report(klass, method_name, per_field, description) }
    end

    private

    # A fresh Blueprint per row keeps memoised Field state independent between measurements.
    def report(klass, method_name, per_field, description)
      ideal = FIELD_COUNT * per_field

      puts format('      %<klass>s#%<method>s -- %<description>s',
                  klass: klass.name.split('::').last, method: method_name, description: description)
      puts
      puts format(HEADER, objects: 'objects', count: 'invocations', ideal: 'ideal/render', per_object: 'per object')
      divider(52)

      OBJECT_COUNTS.each do |object_count|
        blueprint, objects = build_blueprint(FIELD_COUNT, object_count)
        count = count_calls(klass, method_name) { blueprint.render(objects) }

        puts format(ROW, objects: object_count, count: count, ideal: ideal, per_object: count.to_f / object_count)
      end
    end
  end
end
