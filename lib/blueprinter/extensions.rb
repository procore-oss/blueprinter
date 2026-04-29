# frozen_string_literal: true

module Blueprinter
  # Optional, built-in V2 extensions your applications can use.
  #
  # = {Blueprinter::Extensions::FieldOrder}
  #
  # Change the field order in the serialized output.
  #
  # = {Blueprinter::Extensions::MultiJson}
  #
  # Use the `multi_json` gem to swap out JSON serializers.
  #
  # = {Blueprinter::Extensions::OpenTelemetry}
  #
  # Instrument the serialization lifecycle with Open Telemetry.
  #
  # = {Blueprinter::Extensions::ViewOption}
  #
  # Add a `:view` option to `render`, like V1 has.
  #
  # = Community extensions
  #
  # Have an extension you’d like to share? Let us know and we may add it to the list!
  #
  # == blueprinter-activerecord
  #
  # {https://github.com/procore-oss/blueprinter-activerecord blueprinter-activerecord} is an official extension from the
  # Blueprinter team providing ActiveRecord integration, including automatic preloading of associations based on your
  # Blueprint definitions.
  #
  # @api public
  module Extensions
    autoload :FieldOrder, 'blueprinter/extensions/field_order'
    autoload :MultiJson, 'blueprinter/extensions/multi_json'
    autoload :OpenTelemetry, 'blueprinter/extensions/open_telemetry'
    autoload :ViewOption, 'blueprinter/extensions/view_option'
  end
end
