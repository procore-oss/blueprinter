# frozen_string_literal: true

module Blueprinter
  # Optional extensions for applications to pull in
  module Extensions
    autoload :FieldOrder, 'blueprinter/extensions/field_order'
    autoload :LegacyConditionals, 'blueprinter/extensions/legacy_conditionals'
    autoload :LegacyDefaultIf, 'blueprinter/extensions/legacy_default_if'
    autoload :LegacyExtractorOption, 'blueprinter/extensions/legacy_extractor_option'
    autoload :LegacyRenameField, 'blueprinter/extensions/legacy_rename_field'
    autoload :LegacyTransformer, 'blueprinter/extensions/legacy_transformer'
    autoload :MultiJson, 'blueprinter/extensions/multi_json'
    autoload :OpenTelemetry, 'blueprinter/extensions/open_telemetry'
    autoload :ViewOption, 'blueprinter/extensions/view_option'
  end
end
