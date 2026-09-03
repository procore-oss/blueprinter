# frozen_string_literal: true

module Blueprinter
  # Optional, built-in V2 extensions your applications can use.
  #
  # = {Blueprinter::Extensions::FieldOrder}
  #
  # Changes the field order in the serialized output.
  #
  # = {Blueprinter::Extensions::MultiJson}
  #
  # Uses the `multi_json` gem instead of `json`.
  #
  # = {Blueprinter::Extensions::OpenTelemetry}
  #
  # Instruments the serialization lifecycle with Open Telemetry.
  #
  # == V1 Compatibility Extensions
  #
  # - {Blueprinter::Extensions::LegacyOptions} Enables some V1-compatible options
  # - {Blueprinter::Extensions::LegacyTransformer} Add V1-compatible transformers
  #
  # == Community extensions
  #
  # Have an extension you’d like to share? Let us know and we may add it to the list!
  #
  # === blueprinter-activerecord
  #
  # {https://github.com/procore-oss/blueprinter-activerecord blueprinter-activerecord} is an official extension from the
  # Blueprinter team providing ActiveRecord integration, including automatic preloading of associations based on your
  # Blueprint definitions.
  #
  # @api public
  module Extensions
    autoload :FieldOrder, 'blueprinter/extensions/field_order'
    autoload :LegacyDynamicOptions, 'blueprinter/extensions/legacy_dynamic_options'
    autoload :LegacyOptions, 'blueprinter/extensions/legacy_options'
    autoload :LegacyTransformer, 'blueprinter/extensions/legacy_transformer'
    autoload :MultiJson, 'blueprinter/extensions/multi_json'
    autoload :OpenTelemetry, 'blueprinter/extensions/open_telemetry'
  end
end
