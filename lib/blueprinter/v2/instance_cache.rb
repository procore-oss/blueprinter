# frozen_string_literal: true

module Blueprinter
  module V2
    #
    # A simple cache for instances of classes. Allows us to re-use Blueprint, Extension, and Serializer
    # instances during a given render.
    #
    # @!visibility private
    #
    class InstanceCache
      def initialize
        @instances = {}.compare_by_identity
      end

      def blueprint(blueprint_class)
        @instances[blueprint_class] ||= blueprint_class.new
      end
    end
  end
end
