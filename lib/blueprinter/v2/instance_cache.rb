# frozen_string_literal: true

require 'blueprinter/view_wrapper'

module Blueprinter
  module V2
    #
    # A simple cache for instances of classes. Allows us to re-use Blueprint, Extension, and Serializer
    # instances during a given render.
    #
    class InstanceCache
      def initialize
        @blueprints = {}.compare_by_identity
        @serializers = {}.compare_by_identity
        @extensions = {}.compare_by_identity
      end

      def blueprint(blueprint_class)
        case blueprint_class
        when ViewWrapper
          blueprint_class
        else
          @blueprints[blueprint_class] ||= blueprint_class.new
        end
      end

      def serializer(blueprint_class, options, store, initial_depth)
        @serializers[blueprint_class] ||= Serializer.new(blueprint_class, options, self, store:, initial_depth:)
      end

      def extension(ext)
        case ext
        when Extension
          ext
        when Class
          @extensions[ext] ||= ext.new
        when Proc
          @extensions[ext] ||= ext.call
        else
          raise ArgumentError, "Unsupported extension type '#{ext.class.name}'"
        end
      end
    end
  end
end
