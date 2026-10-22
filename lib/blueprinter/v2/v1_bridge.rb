# frozen_string_literal: true

module Blueprinter
  module V2
    #
    # Carries V2 render state (instance cache, depth, store) through V1 renders. V1 field blocks receive
    # local_options as keyword arguments, so the state can't travel in local_options.
    #
    # @!visibility private
    #
    module V1Bridge
      KEY = :_blueprinter_v2_render_state
      State = Struct.new(:instances, :depth, :store)

      def self.with(instances:, depth: 1, store: nil)
        previous = Thread.current[KEY]
        Thread.current[KEY] = State.new(instances, depth, store)
        yield
      ensure
        Thread.current[KEY] = previous
      end

      # @return [State] The state of the enclosing V2 render, or a fresh root state if there isn't one
      def self.current = Thread.current[KEY] || State.new(InstanceCache.new, 1, nil)
    end
  end
end
