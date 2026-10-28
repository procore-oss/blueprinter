# frozen_string_literal: true

module Blueprinter
  module V2
    # An interface for formatting values
    # @!visibility private
    class Formatter
      # Max number of classes to cache. A backstop against apps that put instances of huge numbers of classes
      # through a Blueprint.
      CACHE_LIMIT = 1000

      # @return [Array<Blueprinter::V2::DSL::Nodes::Format>]
      def initialize(formatters)
        @formatters = formatters.dup.compare_by_identity.freeze
        @cache = build_cache @formatters
      end

      def any? = @formatters.any?

      # @param blueprint [Blueprinter::V2::Base] Blueprint instance
      # @param value
      def call(blueprint, value)
        fmt = @cache[value.class]
        case fmt
        when false
          value
        when Proc
          blueprint.instance_exec(value, &fmt)
        when Symbol, String
          blueprint.public_send(fmt, value)
        end
      end

      private

      # Maps a value's class to the formatter for it or its nearest ancestor (false if none). Pre-seeded with exact
      # matches and filled in lazily by `store`.
      def build_cache(entries)
        Hash.new { |_, klass| store klass }.compare_by_identity.merge!(entries).freeze
      end

      # Cache the formatter for klass and return it.
      #
      # The cache is replaced rather than mutated so that concurrent renders only ever read a complete Hash. Two
      # threads racing here just do the same work twice and arrive at the same answer.
      #
      # Anonymous classes aren't cached: the cache would be the only thing keeping them alive, so an app that
      # generates classes at runtime would leak every one of them.
      def store(klass)
        fmt = lookup klass
        # Hash#merge keeps the default_proc and identity comparison
        @cache = @cache.merge(klass => fmt).freeze if klass.name && @cache.size < CACHE_LIMIT
        fmt
      end

      # Find the formatter for the nearest ancestor of klass
      def lookup(klass)
        ancestor = klass.ancestors.find { |k| @formatters.key? k }
        ancestor ? @formatters[ancestor] : false
      end
    end
  end
end
