# frozen_string_literal: true

module Blueprinter
  module V2
    module DSL
      # Define fields, associations, and formatting.
      module Data
        # @!visibility private
        BLUEPRINT_ARRAY_OR_CLASS_ERR = 'Blueprint must be a Blueprint class or an Array containing a Blueprint class'

        #
        # Add a formatter for field values of a given class.
        #
        # When a field (not an association) returns a value of the given class, it will be passed through
        # the formatter.
        #
        # If a block is used, it will be executed in the context of the Blueprint instance, allowing the block to call
        # instance methods.
        #
        # ```
        # class WidgetBlueprint < ApplicationBlueprint
        #   format(Date) { |d| d.iso8601 }
        #   format Time, :fmt_time
        #
        #   def fmt_time(t) = t.iso8601
        # end
        # ```
        #
        # NOTE: Formatters are applied after `around_field_value` hooks run.
        #
        # @param klass [Class] The class of objects to format
        # @param formatter_method [Symbol] Name of a public instance method to call for formatting
        # @yield [Object] Do formatting in the block instead
        #
        def format(klass, formatter_method = nil, &formatter_block)
          nodes << Nodes::Format.new(klass, formatter_method&.to_sym || formatter_block)
        end

        #
        # Define a field.
        #
        # ```
        # field :name
        # field :description, default: "N/A", unless: ->(ctx) { ctx.object.description.blank? }
        # field :address do |object, ctx|
        #   if ctx.options[:full_address]
        #     "#{object.street_address}, #{object.city}, #{object.state} #{object.postal}"
        #   else
        #     "#{object.city}, #{object.state}"
        #   end
        # end
        # ```
        #
        # == Options
        #
        # Proc options for `if`, `unless`, and `default` all accept a single argument: a {Blueprinter::V2::Context::Field}.
        # It contains all the context you could possibly want to implement your logic. Alternatively you can put your logic
        # into an instance method on the Blueprint (or view) and pass its name to `if`/`unless`/`default`.
        #
        # ```
        # field :name, if: ->(ctx) { ctx.object.foo.present? }
        # field :desc, default: :field_is_empty
        #
        # def field_is_empty(ctx)
        #   "(#{ctx.field.name} is empty)"
        # end
        # ```
        #
        # The Proc (or method name) passed to `default_if` accepts two arguments: a {Blueprinter::V2::Context::Field} and the
        # field's value.
        #
        # ```
        # field :name, default: "None", default_if: ->(ctx, val) { val.blank? }
        # field :name, default: "None", default_if: :blank?
        #
        # def blank?(ctx, val) = val.blank?
        # ```
        #
        # @param name [Symbol] Name of the field
        # @param source [Symbol] Optionally specify a different method/Hash key to call to get the value for "name"
        # @option default [Object | Symbol | Proc] Value to use if the field is nil, or if `default_if` returns true
        # @option default_if [Symbol | Proc] Return true to use the value in `default`
        # @option exclude_if_nil [true | false] Don't include field if the value is nil
        # @option if [Symbol | Proc] Only include the field if the given method or Proc returns true
        # @option unless [Symbol | Proc] Include the field unless the given method or Proc returns true
        # @yield [Object, Blueprinter::V2::Context::Field] Extract and return the field value
        #
        def field(name, source: name, **options, &definition)
          name = name.to_sym
          nodes << Fields::Field.new(
            type: :field,
            name: name,
            source: source.to_sym,
            source_str: source.to_s,
            value_proc: definition,
            options: options.dup
          )
        end

        #
        # Define multiple fields at once.
        #
        # ```
        # fields :ssn, :dob, :postal_code, if: :current_user?
        #
        # def current_user?(ctx)
        #   ctx.object.id == ctx.options[:current_user]&.id
        # end
        # ```
        #
        # See {Blueprinter::V2::DSL::Data#field} for documentation and examples of all options.
        #
        # @param names [Symbol] Names of the fields
        # @option default [Object | Symbol | Proc] Value to use if the field is nil, or if `default_if` returns true
        # @option default_if [Symbol | Proc] Return true to use the value in `default`
        # @option exclude_if_nil [true | false] Don't include field if the value is nil
        # @option if [Symbol | Proc] Only include the field if the given method or Proc returns true
        # @option unless [Symbol | Proc] Include the field unless the given method or Proc returns true
        # @yield [Object, Blueprinter::V2::Context::Field] Extract and return the field value
        #
        def fields(*names, **options, &definition)
          names.each do |name|
            name = name.to_sym
            nodes << Fields::Field.new(
              type: :field,
              name: name,
              source: name,
              source_str: name.to_s,
              options: options,
              value_proc: definition
            )
          end
        end

        #
        # Defines an association to an object or collection.
        #
        # ```
        # class WidgetBlueprint < ApplicationBlueprint
        #   # An object using the :default view
        #   association :category, CategoryBlueprint
        #
        #   # An object using a view called :simple
        #   association :subcategory, CategoryBlueprint[:simple]
        #
        #   # A collection using the :default view
        #   association :parts, [PartBlueprint]
        #
        #   # A collection using a view called :simple
        #   association :subparts, [PartBlueprint[:simple]]
        #
        #   # You can dynamically use the current view's name
        #   association :category, CategoryWidget[view_name]
        #
        #   # If it's a nested view, you can refer to the whole path ('parent_view.child_view')
        #   association :category, CategoryWidget[view_path]
        #
        #   # You can also use a Proc, which accepts the object as an argument:
        #   association :category, ->(category) { category.blueprint }
        #
        #   # For collections, wrap the Proc in an array
        #   association :categories, [->(category) { category.blueprint }]
        # end
        # ```
        #
        # See {Blueprinter::V2::DSL::Data#field} for documentation and examples of all options.
        #
        # @param name [Symbol] Name of the association
        # @param blueprint [Class|Proc|Array<Class|Proc>] Blueprint class to use (V1 or V2). For a collection, wrap the
        #                  blueprint in an array. You may also pass a Proc that returns a Blueprint.
        # @param source [Symbol] Optionally specify a different method/Hash key to call to get the value for "name"
        # @option default [Object | Symbol | Proc] Value to use if the field is nil, or if `default_if` returns true
        # @option default_if [Symbol | Proc] Return true to use the value in `default`
        # @option exclude_if_nil [true | false] Don't include field if the value is nil
        # @option if [Symbol | Proc] Only include the field if the given method or Proc returns true
        # @option unless [Symbol | Proc] Include the field unless the given method or Proc returns true
        # @yield [Object, Blueprinter::V2::Context::Field] Extract and return the field value
        #
        def association(name, blueprint, source: name, **options, &definition)
          name = name.to_sym
          is_collection, blueprint_class = parse_blueprint(blueprint)
          nodes << Fields::Field.new(
            type: is_collection ? :collection : :object,
            name: name,
            blueprint: blueprint_class,
            source: source.to_sym,
            source_str: source.to_s,
            value_proc: definition,
            options: options.dup
          )
        end

        #
        # Prevents inheritance of the given fields and associations.
        #
        # ```
        # class WidgetBlueprint < ApplicationBlueprint
        #   fields :id, :name, :description
        #
        #   # Will only have id, name, and price fields
        #   view :listing do
        #     exclude :description
        #     field :price
        #   end
        # end
        # ```
        #
        # Can also be used to categorically exclude fields, options, extensions, and formatters. A Blueprint or view
        # with the following won't inherit anything:
        #
        # ```
        # exclude fields: true, options: true, extensions: true, formatters: true
        # ```
        #
        # @param names [Symbol] Fields or associations to exclude
        # @param fields [true | false] Exclude all fields
        # @param options [true | false] Exclude all options
        # @param extensions [true | false] Exclude all extensions
        # @param formatters [true | false] Exclude all formatters
        #
        def exclude(*names, fields: false, options: false, extensions: false, formatters: false)
          names.each { |name| nodes << Nodes::Exclude.new(name.to_sym) }
          nodes << Nodes::Flag.new(:exclude_fields) if fields
          nodes << Nodes::Flag.new(:exclude_options) if options
          nodes << Nodes::Flag.new(:exclude_extensions) if extensions
          nodes << Nodes::Flag.new(:exclude_formatters) if formatters
        end

        alias excludes exclude

        private

        def parse_blueprint(blueprint)
          is_collection, assoc_arg =
            if blueprint.is_a? Array
              raise ArgumentError, BLUEPRINT_ARRAY_OR_CLASS_ERR unless blueprint.size == 1

              [true, blueprint[0]]
            else
              [false, blueprint]
            end

          is_bp_class = assoc_arg.is_a?(Class) && (assoc_arg < V2::Base || assoc_arg < Blueprinter::Base)
          raise ArgumentError, BLUEPRINT_ARRAY_OR_CLASS_ERR unless is_bp_class || assoc_arg.is_a?(Proc)

          [is_collection, assoc_arg]
        end
      end
    end
  end
end
