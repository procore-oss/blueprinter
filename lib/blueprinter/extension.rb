# frozen_string_literal: true

module Blueprinter
  #
  # Base class for all extensions.
  #
  # V2 hook call order:
  #
  # - around_hook (called around any other extension hook)
  # - around_result
  #   - around_blueprint_init
  #     - around_serialize_object | around_serialize_collection
  #       - around_field_value | around_object_value | around_collection_value
  #         - around_blueprint_init …
  #
  # V1 hook call order:
  #  - pre_render
  #
  class Extension
    HOOKS = %i[
      around_hook
      around_result
      around_blueprint_init
      around_serialize_object
      around_serialize_collection
      around_field_value
      around_object_value
      around_collection_value
      pre_render
    ].freeze

    # @return [Array<Symbol>] The names of the hooks implemented in this extension
    def self.hooks
      @_hooks ||= (public_instance_methods(true) & HOOKS).freeze
    end

    # If this returns true, around_hook will not be called when this extension's hooks are run. Used by core extensions.
    def hidden? = false

    # Skip the current field and halt further field hooks
    def skip! = throw V2::Serializer::SIGNAL, V2::Serializer::SIG_SKIP

    # Helper for around_result hooks to declare that a result is "final"
    def final(val) = V2::Context::Final.new(val)

    # Helper for around_result hooks to check if a previous hook has declared a result "final"
    def final?(val) = val.is_a? V2::Context::Final
  end
end
