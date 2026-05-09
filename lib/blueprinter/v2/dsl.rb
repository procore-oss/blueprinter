# frozen_string_literal: true

require 'set'

module Blueprinter
  module V2
    #
    # Methods for defining your Blueprints and views.
    #
    # You can also use the Blueprinter DSL in your own Ruby modules, then include them in your Blueprints:
    #
    # ```ruby
    # module MySharedBlueprinterCode
    #   extend Blueprinter::DSL
    #
    #   set :some_option, true
    #
    #   field :foo
    #
    #   partial :my_partial do
    #     # ...
    #   end
    #
    #   view :my_view do
    #     # ...
    #   end
    # end
    #
    # class MyBlueprint < ApplicationBlueprint
    #   include MySharedBlueprinterCode
    #
    #   # ...
    # end
    # ```
    #
    module DSL
      # @!visibility private
      module Nodes
        Use = Struct.new(:name, :exclusions, :callsite)
        Exclude = Struct.new(:name)
        Partial = Struct.new(:name, :block)
        View = Struct.new(:name, :block)
        Format = Struct.new(:klass, :fmt)
        SetOpt = Struct.new(:key, :val)
        SetDynamicOpt = Struct.new(:key, :block)
        UnsetOpt = Struct.new(:key)
        AppendExt = Struct.new(:ext)
        PrependExt = Struct.new(:ext)
        RemExt = Struct.new(:klass)
        RemDynamicExt = Struct.new(:block)
        Flag = Struct.new(:name)
      end

      autoload :Config, 'blueprinter/v2/dsl/config'
      autoload :Data, 'blueprinter/v2/dsl/data'
      autoload :Views, 'blueprinter/v2/dsl/views'

      # @!visibility private
      def self.extended(mod)
        mod.class_eval do
          extend DSL::Config
          extend DSL::Data
          extend DSL::Views

          class << self
            attr_reader :nodes

            def included(klass_or_mod)
              klass_or_mod.nodes.concat(nodes) if klass_or_mod.respond_to? :nodes
            end
          end
          @nodes = []
        end
      end
    end
  end
end
