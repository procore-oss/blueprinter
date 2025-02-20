# frozen_string_literal: true

require 'blueprinter/v2/fields'
require 'blueprinter/v2/context'

module Blueprinter
  module V2
    autoload :Base, 'blueprinter/v2/base'
    autoload :Context, 'blueprinter/v2/context'
    autoload :DSL, 'blueprinter/v2/dsl'
    autoload :Extensions, 'blueprinter/v2/extensions'
    autoload :Formatter, 'blueprinter/v2/formatter'
    autoload :InstanceCache, 'blueprinter/v2/instance_cache'
    autoload :Reflection, 'blueprinter/v2/reflection'
    autoload :Render, 'blueprinter/v2/render'
    autoload :Serializer, 'blueprinter/v2/serializer'
    autoload :ViewBuilder, 'blueprinter/v2/view_builder'
  end
end
