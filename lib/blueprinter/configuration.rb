# frozen_string_literal: true

require 'json'
require 'blueprinter/extensions'
require 'blueprinter/extractors/auto_extractor'

module Blueprinter
  class Configuration
    # Attributes baked into a Blueprint's compiled render pipeline (see Field#compile) or into
    # ViewCollection's cache. Mutating one of these must bump the generation counter, otherwise
    # those caches keep serving behaviour derived from the previous configuration.
    #
    # sort_fields_by and extractor_default are excluded. Both are read when a blueprint is defined:
    # views record definition order only while sort_fields_by is :definition, and each Field keeps
    # the extractor it was created with. A bump would rebuild the cache without changing either.
    # custom_array_like_classes is excluded too: nothing compiled depends on it, its writer only
    # has to clear the array_like_classes memo.
    #
    # @api private
    COMPILED_ATTRIBUTES = %i[
      datetime_format
      default_transformers
      field_default
      if
      unless
    ].freeze

    # Attributes re-read on every render, so they need no cache invalidation.
    #
    # @api private
    LIVE_ATTRIBUTES = %i[
      association_default
      deprecations
      generator
      method
    ].freeze

    VALID_CALLABLES = %i[if unless].freeze

    # Monotonic counter, deliberately class-level rather than per-instance: reset_configuration!
    # installs a brand new Configuration, and an instance counter would restart at zero, making a
    # cache built against the previous instance look current.
    #
    # The integer lives in a frozen one-element array published by one assignment, same as
    # ViewCollection's snapshot: a reader follows one reference and sees the whole value. The mutex
    # makes the increment atomic, so two overlapping writes cannot collapse into one bump and leave
    # a cache stamped with a generation that never observed the second write. A render that already
    # loaded the previous snapshot finishes on it; the next read sees the new generation and rebuilds.
    @generation = [0].freeze
    @generation_mutex = Mutex.new

    class << self
      # @api private
      def generation
        @generation[0]
      end

      # @api private
      def bump_generation!
        @generation_mutex.synchronize do
          @generation = [@generation[0] + 1].freeze
          @generation[0]
        end
      end
    end

    attr_accessor(*LIVE_ATTRIBUTES)
    # Read when a View or ViewCollection is created. Not part of the generation counter; see
    # COMPILED_ATTRIBUTES.
    attr_accessor :sort_fields_by
    attr_reader(*COMPILED_ATTRIBUTES, :custom_array_like_classes, :extensions, :extractor_default)

    # Writers for compiled attributes invalidate dependent caches. Defined after the attr_reader
    # calls above so these take precedence.
    COMPILED_ATTRIBUTES.each do |attribute|
      define_method(:"#{attribute}=") do |value|
        instance_variable_set(:"@#{attribute}", value)
        invalidate_compiled!
        value
      end
    end

    def initialize
      @association_default = nil
      @custom_array_like_classes = []
      @datetime_format = nil
      @default_transformers = []
      @deprecations = :stderror
      @extensions = Extensions.new
      @extractor_default = AutoExtractor
      @field_default = nil
      @generator = JSON
      @if = nil
      @method = :generate
      @sort_fields_by = :name_asc
      @unless = nil
    end

    def extensions=(list)
      @extensions = Extensions.new(list)
    end

    # Only the array_like_classes memo depends on this, so the writer clears that and leaves the
    # generation counter alone: no compiled pipeline needs rebuilding.
    def custom_array_like_classes=(classes)
      @_array_like_classes = nil
      @custom_array_like_classes = classes
    end

    def array_like_classes
      @_array_like_classes ||= [
        Array,
        defined?(ActiveRecord::Relation) && ActiveRecord::Relation,
        *custom_array_like_classes
      ].compact
    end

    def jsonify(blob)
      generator.public_send(method, blob)
    end

    def valid_callable?(callable_name)
      VALID_CALLABLES.include?(callable_name)
    end

    # @param extractor [Class<Blueprinter::AutoExtractor>]
    def extractor_default=(extractor)
      reset_default_extractor!

      @extractor_default = extractor
    end

    # @return [Blueprinter::AutoExtractor]
    def default_extractor
      @_default_extractor ||= extractor_default.new
    end

    private

    # Signals every ViewCollection to recompile on next use.
    def invalidate_compiled!
      self.class.bump_generation!
    end

    def reset_default_extractor!
      @_default_extractor = nil
    end
  end
end
