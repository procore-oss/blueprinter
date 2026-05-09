# frozen_string_literal: true

module Blueprinter
  module V2
    module DSL
      module Config
        #
        # Set an option value.
        #
        # ```
        # class WidgetBlueprint < ApplicationBlueprint
        #   set :exclude_if_nil, true
        #   # ...
        #
        #   # You can override options in views
        #   view :extended do
        #     set :exclude_if_nil, false
        #     # ...
        #   end
        # end
        # ```
        #
        # == Accessing the previous value
        #
        # When overriding an option in a child view or Blueprint, sometimes you may want to check,
        # or incorporate, the previous value. You can do this with a block:
        #
        # ```
        # set :foo, "foo"
        #
        # view :extended do
        #   set :foo do |val|
        #     # the value will be "foobar"
        #     "#{val}bar"
        #   end
        # end
        # ```
        #
        # @param key [Symbol] Option name
        # @param value [Object | nil] Object value
        # @yield [Object | nil] Get the current value then return the value you want
        #
        def set(key, value = nil, &block)
          node = block ? Nodes::SetDynamicOpt.new(key, block) : Nodes::SetOpt.new(key, value)
          nodes << node
        end

        #
        # Clear the given options.
        #
        # @param *keys [Symbol]
        #
        def unset(*keys)
          keys.each { |key| nodes << Nodes::UnsetOpt.new(key) }
        end

        #
        # Adds one or more extensions.
        #
        # ```
        # class WidgetBlueprint < ApplicationBlueprint
        #   add MyExtension.new
        #
        #   view :extended do
        #     add OtherExtension.new
        #   end
        # end
        # ```
        #
        # @param *extensions [Blueprinter::Extension] Extension instances to add
        # @param prepend [true | false] Add this extension before all others
        #
        def add(*extensions, prepend: false)
          if block_given?
            raise BlueprinterError, 'Blueprinter::DSL#add does not accept a block. Did you mean to pass it to an extension?'
          end

          extensions.reverse! if prepend
          extensions.each do |ext|
            node = prepend ? Nodes::PrependExt.new(ext) : Nodes::AppendExt.new(ext)
            nodes << node
          end
        end

        #
        # Removes extensions of the given classes, or that satisfy the given block.
        #
        # @param *klasses [Class]
        # @yield [Blueprinter::Extension] Return true if the given extension should be removed
        #
        def remove(*klasses, &reject)
          klasses.each { |klass| nodes << Nodes::RemExt.new(klass) }
          nodes << Nodes::RemDynamicExt.new(reject) if reject
        end

        #
        # Define an anonymous extension and add it to the current context.
        #
        # ```
        # class WidgetBlueprint < ApplicationBlueprint
        #   extension do
        #     # Decorate Blueprint output
        #     def around_blueprint(ctx)
        #       hash = yield ctx
        #       hash[:meta] = metadata ctx.object
        #       hash
        #     end
        #
        #     def metadata(object)
        #       # ...
        #     end
        #   end
        # end
        # ```
        #
        def extension(&block)
          bp_name = blueprint_name
          add Class.new(Extension) {
            @blueprint_name = bp_name
            def self.name = "#{@blueprint_name} extension"
            class_eval(&block)
          }.new
        end
      end
    end
  end
end
