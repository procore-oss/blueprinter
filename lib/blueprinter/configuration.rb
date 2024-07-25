# frozen_string_literal: true

require 'json'
require 'blueprinter/extensions'
require 'blueprinter/extractors/auto_extractor'

module Blueprinter
  class Configuration
    attr_accessor :association_default, :datetime_format, :deprecations, :field_default, :generator, :if, :method,
                  :sort_fields_by, :unless, :extractor_default, :default_transformers, :custom_array_like_classes

    VALID_CALLABLES = %i[if unless].freeze

    def initialize
      @deprecations = :stderror
      @association_default = nil
      @datetime_format = nil
      @field_default = nil
      @generator = JSON
      @if = nil
      @method = :generate
      @sort_fields_by = :name_asc
      @unless = nil
      @extractor_default = AutoExtractor
      @default_transformers = []
      @custom_array_like_classes = []
    end

    def extensions
      @extensions ||= Extensions.new
    end

    def extensions=(list)
      @extensions = Extensions.new(list)
    end

    def array_like_classes
      @array_like_classes ||= [
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
  end
end
