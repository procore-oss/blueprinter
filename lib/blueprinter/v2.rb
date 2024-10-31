# frozen_string_literal: true

require 'blueprinter/v2/fields'

module Blueprinter
  module V2
    autoload :Base, 'blueprinter/v2/base'
    autoload :DSL, 'blueprinter/v2/dsl'
    autoload :Reflection, 'blueprinter/v2/reflection'
    autoload :ViewBuilder, 'blueprinter/v2/view_builder'
  end
end
