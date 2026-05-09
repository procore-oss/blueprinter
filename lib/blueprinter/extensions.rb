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
  # - {Blueprinter::Extensions::LegacyConditionals} Allows V1-style `if`/`unless` Procs
  # - {Blueprinter::Extensions::LegacyDefaultIf} Allows V1-style `default_if` options
  # - {Blueprinter::Extensions::LegacyDynamicOptions} Adds V1's `options` option to associations
  # - {Blueprinter::Extensions::LegacyExtractorOption} Adds V1's `extractor` field option
  # - {Blueprinter::Extensions::LegacyRenameField} Adds V1's `name` field option
  # - {Blueprinter::Extensions::LegacyTransformer} Adds V1's `name` field option
  # - {Blueprinter::Extensions::ViewOption} Adds a `view` option to `render`
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
    autoload :LegacyConditionals, 'blueprinter/extensions/legacy_conditionals'
    autoload :LegacyDefaultIf, 'blueprinter/extensions/legacy_default_if'
    autoload :LegacyDynamicOptions, 'blueprinter/extensions/legacy_dynamic_options'
    autoload :LegacyExtractorOption, 'blueprinter/extensions/legacy_extractor_option'
    autoload :LegacyRenameField, 'blueprinter/extensions/legacy_rename_field'
    autoload :LegacyTransformer, 'blueprinter/extensions/legacy_transformer'
    autoload :MultiJson, 'blueprinter/extensions/multi_json'
    autoload :OpenTelemetry, 'blueprinter/extensions/open_telemetry'
    autoload :ViewOption, 'blueprinter/extensions/view_option'
  end
end
