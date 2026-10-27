# frozen_string_literal: true

require 'objspace'

module PerfBench
  # Attributes one render's allocations to source lines with ObjectSpace allocation tracing (stdlib `objspace`).
  #
  # No sampling profiler (stackprof, vernier) is in the Gemfile, so wall-time attribution comes from the `breakdown`
  # sweep instead; allocation sites are exact and explain most allocation-count differences between runs.
  module Profile
    LIB = File.expand_path('../../../lib', __dir__)
    BENCH = __dir__

    module_function

    # @return [Hash] total objects, the top sites, the objects ObjectSpace can't attribute to a site, and the VM-internal
    #   (imemo) objects among them by type
    def allocation_sites(engine, input, rendered_objects, top: 12)
      job = engine.job(input.call)
      job.call # warm: first-call allocations (method caches, lazily built state) aren't per-render costs
      job = engine.job(input.call)
      counts, total, imemo = trace { job.call }
      attributed = counts.values.sum
      {
        total:, per_object: total.fdiv(rendered_objects), untracked: total - attributed, imemo:,
        top: counts.sort_by { |_, n| -n }.first(top).map do |(site, klass), n|
          { site:, class: klass, count: n, per_object: n.fdiv(rendered_objects) }
        end
      }
    end

    def trace
      GC.start
      GC.disable
      imemo_before = ObjectSpace.count_imemo_objects
      ObjectSpace.trace_object_allocations_start
      ObjectSpace.trace_object_allocations_clear
      before = GC.stat(:total_allocated_objects)
      kept = yield
      total = GC.stat(:total_allocated_objects) - before
      ObjectSpace.trace_object_allocations_stop
      imemo = ObjectSpace.count_imemo_objects.to_h { |type, n| [type, n - imemo_before.fetch(type, 0)] }
      [count_sites(kept), total, imemo.select { |_, n| n.positive? }]
    ensure
      GC.enable
    end

    def count_sites(_kept)
      counts = Hash.new(0)
      ObjectSpace.each_object do |obj|
        file = ObjectSpace.allocation_sourcefile(obj)
        next unless file

        klass = Object === obj ? obj.class.name || obj.class.inspect : 'BasicObject' # rubocop:disable Style/CaseEquality
        counts[["#{short(file)}:#{ObjectSpace.allocation_sourceline(obj)}", klass]] += 1
      end
      ObjectSpace.trace_object_allocations_clear
      counts
    end

    def short(file)
      if file.start_with?(LIB) then "lib#{file.delete_prefix(LIB)}"
      elsif file.start_with?(BENCH) then "bench#{file.delete_prefix(BENCH)}"
      elsif (m = file.match(%r{.*/gems/([^/]+)/(.+)\z})) then "#{m[1]}/#{m[2]}"
      else file
      end
    end
  end
end
