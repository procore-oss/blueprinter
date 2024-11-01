# frozen_string_literal: true

require 'blueprinter/v2/fields'
require 'blueprinter/v2/context'

module Blueprinter
  module V2
    autoload :Base, 'blueprinter/v2/base'
    autoload :Context, 'blueprinter/v2/context'
    autoload :DSL, 'blueprinter/v2/dsl'
    autoload :Formatter, 'blueprinter/v2/formatter'
    autoload :InstanceCache, 'blueprinter/v2/instance_cache'
    autoload :Reflection, 'blueprinter/v2/reflection'
    autoload :ViewBuilder, 'blueprinter/v2/view_builder'
  end
end
