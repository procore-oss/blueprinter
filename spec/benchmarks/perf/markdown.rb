# frozen_string_literal: true

module PerfBench
  module Markdown
    module_function

    # @return [Array<String>] the lines of a GFM table
    def table(head, rows)
      ["| #{cells(head)} |", "|#{head.map { ' --- |' }.join}", *rows.map { |r| "| #{cells(r)} |" }]
    end

    def cells(row) = row.map { |c| escape(c.to_s) }.join(' | ')

    # Backslashes first, so an escaped pipe isn't re-escaped
    def escape(text) = text.gsub('\\', '\\\\\\\\').gsub('|', '\\|')

    def num(value)
      return 'n/a' if value.nil?
      return value.to_s if value.is_a?(Integer)

      if value >= 100 then format('%.0f', value)
      elsif value >= 10 then format('%.1f', value)
      elsif value >= 0.1 then format('%.2f', value)
      else format('%.4f', value)
      end
    end

    def pct(value) = value ? format('%.0f%%', value * 100) : 'n/a'
  end
end
