# frozen_string_literal: true

require 'blueprinter/v2/fields'
require 'blueprinter/v2/context'

module Blueprinter
  module V2
    autoload :Base, 'blueprinter/v2/base'
    autoload :Conditionals, 'blueprinter/v2/conditionals'
    autoload :Context, 'blueprinter/v2/context'
    autoload :Defaults, 'blueprinter/v2/defaults'
    autoload :DSL, 'blueprinter/v2/dsl'
    autoload :ExtensionHelpers, 'blueprinter/v2/extension_helpers'
    autoload :Extensions, 'blueprinter/v2/extensions'
    autoload :FieldLogic, 'blueprinter/v2/field_logic'
    autoload :FieldSerializer, 'blueprinter/v2/field_serializer'
    autoload :Formatter, 'blueprinter/v2/formatter'
    autoload :InstanceCache, 'blueprinter/v2/instance_cache'
    autoload :Presenters, 'blueprinter/v2/presenters'
    autoload :Reflection, 'blueprinter/v2/reflection'
    autoload :Render, 'blueprinter/v2/render'
    autoload :Serializer, 'blueprinter/v2/serializer'
    autoload :Serializer3, 'blueprinter/v2/serializer3'
    autoload :ViewBuilder, 'blueprinter/v2/view_builder'
  end
end
