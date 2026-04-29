# frozen_string_literal: true

require 'blueprinter/v2/fields'
require 'blueprinter/v2/context'

module Blueprinter
  # Blueprinter's V2 API. Interoperable with V1 associations. Key concepts are described below.
  #
  # = The Blueprinter DSL
  #
  # The DSL allows you to define your Blueprints and views. It also provides Blueprint-level options,
  # formatters, extension management, and more. See {Blueprinter::V2::DSL} for more info.
  #
  # ```
  # class WidgetBlueprint < ApplicationBlueprint
  #   field :name
  #   association :category, CategoryBlueprint
  #   association :parts, [PartBlueprint]
  #
  #   view :extended do
  #     field :description
  #     association :manufacturer, CompanyBlueprint
  #     association :vendors, [CompanyBlueprint]
  #   end
  # end
  # ```
  #
  # For information about Blueprint and view inheritance, best practices around configuration, and Blueprint
  # instance lifecycles, see {Blueprinter::V2::Base}.
  #
  # = Rendering
  #
  # Call {Blueprinter::V2::Base.render render}, {Blueprinter::V2::Base.render_object render_object}, or
  # {Blueprinter::V2::Base.render_collection render_collection} on your Blueprints to begin serializaing.
  # Then call {Blueprinter::V2::Render#to_json to_json} or {Blueprinter::V2::Render#to_hash to_hash} on the
  # result.
  #
  #   WidgetBlueprint.render(widget).to_json
  #
  # = Reflection
  #
  # You can reflect on your Blueprints using a public API. See {Blueprinter::V2::Reflection} for more info.
  #
  # ```
  # view = WidgetBlueprint.reflections[:default]
  # puts view.name
  # puts view.options
  # view.fields.each_value { |field| puts field.name }
  # view.objects.each_value { |field| puts field.name }
  # view.collections.each_value { |field| puts field.name }
  # ```
  #
  # = Extensions
  #
  # V2 has a powerful extension system, providing hooks into all aspects of the serialization lifecycle.
  # See {Blueprinter::Extension} for more info.
  #
  # Several extensions are available out of the box including an optimized JSON serializer, Open Telemetry
  # integration, and more. See {Blueprinter::Extensions} for more info.
  #
  # @api public
  module V2
    autoload :Base, 'blueprinter/v2/base'
    autoload :Context, 'blueprinter/v2/context'
    autoload :DSL, 'blueprinter/v2/dsl'
    autoload :Extensions, 'blueprinter/v2/extensions'
    autoload :Extractors, 'blueprinter/v2/extractors'
    autoload :FieldLogic, 'blueprinter/v2/field_logic'
    autoload :FieldSerializers, 'blueprinter/v2/field_serializers'
    autoload :Formatter, 'blueprinter/v2/formatter'
    autoload :InstanceCache, 'blueprinter/v2/instance_cache'
    autoload :Reflection, 'blueprinter/v2/reflection'
    autoload :Render, 'blueprinter/v2/render'
    autoload :Serializer, 'blueprinter/v2/serializer'
    autoload :ViewBuilder, 'blueprinter/v2/view_builder'
  end
end
