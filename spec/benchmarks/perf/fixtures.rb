# frozen_string_literal: true

require 'bigdecimal'
require 'date'

module PerfBench
  # Builds input trees as Symbol-keyed Hashes, then converts them to the other in-memory input kinds. Every tree is
  # deterministic, so repeated builds render identically.
  module Fixtures
    BASE_TIME = Time.utc(2024, 5, 6, 7, 8, 9)
    BASE_DATE = Date.new(2024, 5, 6)

    module_function

    def field_names(width, prefix: 'f')
      Array.new(width) { |i| :"#{prefix}#{i.to_s.rjust(2, '0')}" }
    end

    # A value of the given type for field `i` of object `n`. `:mixed` alternates strings and integers.
    def value(type, n, i)
      case type
      when :mixed then i.even? ? "value #{n}-#{i}" : (n * 100) + i
      when :string then "value #{n}-#{i}"
      when :integer then (n * 100) + i
      when :time then BASE_TIME + (n * 3600) + i
      when :date then BASE_DATE + n + i
      when :decimal then BigDecimal("#{n}.#{i.to_s.rjust(2, '0')}")
      else raise ArgumentError, "unknown value type #{type.inspect}"
      end
    end

    # @param nil_ratio [Float] fraction of fields (the first ones by index) whose value is nil
    def attributes(n, width:, type: :mixed, nil_ratio: 0.0, prefix: 'f')
      nil_count = (width * nil_ratio).round
      field_names(width, prefix:).each_with_index.to_h do |name, i|
        [name, i < nil_count ? nil : value(type, n, i)]
      end
    end

    def company(n) = { id: n, name: "Company #{n}", city: "City #{n % 7}" }

    def part(widget_n, i) = { id: (widget_n * 1000) + i, name: "Part #{widget_n}-#{i}", number: i }

    # The baseline shape: `width` plain fields, one object association (company), one collection (parts).
    #
    # @param companies [Integer, nil] when set, widgets share this many company objects (repeated children)
    def widgets(count, width: 20, parts: 3, type: :mixed, nil_ratio: 0.0, companies: nil, company: true)
      shared = companies && Array.new(companies) { |c| company(c + 1) }
      Array.new(count) do |idx|
        n = idx + 1
        widget = { id: n }.merge!(attributes(n, width:, type:, nil_ratio:))
        widget[:company] = shared ? shared[idx % companies] : company(n) if company
        widget[:parts] = Array.new(parts) { |i| part(n, i + 1) } if parts
        widget
      end
    end

    # A tree `depth` levels deep: each node has 5 fields and `fanout` children (a collection association).
    def tree(count, depth:, fanout:)
      Array.new(count) { |idx| node(idx + 1, depth, fanout) }
    end

    def node(n, depth, fanout)
      result = { id: n }.merge!(attributes(n, width: 4))
      result[:children] = Array.new(fanout) { |i| node((n * 10) + i, depth - 1, fanout) } if depth > 1
      result
    end

    # Converts a Hash tree to plain Ruby objects (`:poro`) or Structs (`:struct`), preserving shared references.
    # `:hash` returns the tree unchanged.
    def convert(tree, kind, memo = {}.compare_by_identity)
      return tree if kind == :hash

      case tree
      when Array then tree.map { |v| convert(v, kind, memo) }
      when Hash
        memo[tree] ||= begin
          values = tree.transform_values { |v| convert(v, kind, memo) }
          kind == :struct ? struct_class(values.keys).new(*values.values) : poro_class(values.keys).new(values)
        end
      else tree
      end
    end

    def struct_class(keys)
      (@_structs ||= {})[keys] ||= Struct.new(*keys)
    end

    def poro_class(keys)
      (@_poros ||= {})[keys] ||= Class.new do
        attr_reader(*keys)

        define_method(:initialize) do |values|
          values.each { |k, v| instance_variable_set(:"@#{k}", v) }
        end
      end
    end

    # The input as a single object when `size` is `:object`, otherwise an Array.
    def sized(list, size) = size == :object ? list.first : list
  end
end
