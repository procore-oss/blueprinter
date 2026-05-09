# frozen_string_literal: true

module Blueprinter
  module V2
    # Methods for defining your Blueprint and views.
    #
    # == options
    #
    # Blueprints, view, and partials accept some of the same options that fields do: `if`, `unless`, `default`,
    # `default_if`, and `exclude_if_nil`.
    #
    # See {Blueprinter::V2::DSL#field} for more info about how to use each one.
    #
    # ```
    # class WidgetBlueprint < ApplicationBlueprint
    #   options[:exclude_if_nil] = true
    #   # ...
    #
    #   view :extended do
    #     options[:exclude_if_nil] = false
    #     # ...
    #   end
    # end
    # ```
    #
    # == extensions
    #
    # Extensions can be added to Blueprints, views, and partials. Check out Blueprinter's {Blueprinter::Extensions built-in}
    # extensions or {Blueprinter::Extension build your own}.
    #
    # ```
    # class WidgetBlueprint < ApplicationBlueprint
    #   extensions << MyExtension.new
    #
    #   view :extended do
    #     # It's a regular array, so you can alter it however you like
    #     extensions.clear
    #   end
    # end
    # ```
    #
    module DSL
      # @!visibility private
      BLUEPRINT_ARRAY_OR_CLASS_ERR = 'Blueprint must be a Blueprint class or an Array containing a Blueprint class'

      # @!attribute [rw] options
      #   @return [Hash] Set options on this Blueprint, view, or partial

      # @!attribute [rw] extensions
      #   @return [Array<Blueprinter::Extension>] extensions set on this Blueprint or view

      #
      # Define a child view, which inherits everything from the parent including fields, associations,
      # formatters, options, partials, and extensions.
      #
      # Views can be nested to an arbitrary depth. They can define fields, associations, formatters, options,
      # extensions, partials, and nested views.
      #
      # If a view with this name already exists, the definition will be appended.
      #
      # ```
      # class WidgetBlueprint < ApplicationBlueprint
      #   fields :id, :name
      #
      #   # This view will contain :id, :name, and :description
      #   view :extended do
      #     field :description
      #
      #     # This view (:"extended.plus") will contain :id, :name, :description, and :parts
      #     view :plus do
      #       collection :parts, [PartBlueprint]
      #     end
      #   end
      #
      #   # This view will only contain :id
      #   view :id_only, empty: true do
      #     field :id
      #   end
      # end
      # ```
      #
      # @param name [Symbol] Name of the view
      # @param empty [true | false] Don't inherit fields from ancestors
      # @yield Define the view in the block. It has access to the full DSL.
      #
      def view(name, empty: false, &definition)
        raise Errors::InvalidBlueprint, "View name may not contain '.'" if name.to_s =~ /\./

        name = name.to_sym
        partials[name] = definition
        views[name] = ViewBuilder::Def.new(definition:, empty:)
      end

      #
      # Define a partial. Partials can define anything Blueprints or views can: fields,
      # associations, formatters, options, extensions, views, and other partials. But they're not
      # views. Rather, views can `use` partials as shared functionality, similar to how Ruby classes
      # can include modules.
      #
      # If a partial with this name already exists, it will be **replaced**.
      #
      # ```
      # class WidgetBlueprint < ApplicationBlueprint
      #   fields :id, :name
      #
      #   view :short do
      #     use :associations
      #     field(:description) { |ctx| ctx.object.description[0..50] }
      #   end
      #
      #   view :expanded do
      #     use :associations
      #     field :description
      #   end
      #
      #   partial :associations do
      #     association :category, CategoryBlueprint
      #     association :parts, [PartBlueprint]
      #   end
      # end
      # ```
      #
      # NOTE: Nested partials are not _addressable_ from outside. Whatever views _use_ the outer partial will each define
      # their own nested partials. Only those views can use them.
      #
      # NOTE: Using the DSL you **cannot** use a partial from a different _Blueprint_. If you really need that
      # you can define your "shared" partials in a shared Ruby parent class or an includable module.
      #
      # @param name [Symbol] Name of the partial to create or import
      # @yield Define the partial in the block. It has access to the full DSL.
      #
      def partial(name, &definition)
        partials[name.to_sym] = definition
      end

      #
      # Append one or more partials to the current view.
      #
      # Because it's appended, the partial will have a chance to override the view's fields, options, extensions,
      # formatters, and nested views. If you want different behavior, consider `use!`.
      #
      # ```
      # view :foo do
      #   use :my_partial
      # end
      # ```
      #
      # NOTE: Anytime you create a view, a partial of the same name is also created. This allows views to `use`
      # other views just like partials.
      #
      # @param *names [Symbol] One or more partial names
      #
      def use(*names)
        names.each { |name| appended_partials << name.to_sym }
      end

      #
      # Insert one or more partials at the current line.
      #
      # ```
      # view :foo do
      #   use! :my_partial
      # end
      # ```
      #
      # Because it's inserted at the call site, `use!` allows the caller to decide which parts of the view can be
      # overridden by the partial, and what the view can override from the partial.
      #
      # ```
      # view :foo do
      #   # things defined here can be overridden by the partial below
      #
      #   use! :my_partial
      #
      #   # things defined here can override things defined by the partial above
      # end
      # ```
      #
      # NOTE: Anytime you create a view, a partial of the same name is also created. This allows views to `use!`
      # other views just like partials.
      #
      # @param *names [Symbol] One or more partial names
      #
      def use!(*names)
        names.each(&method(:apply_partial!))
      end

      #
      # Add a formatter for field values.
      #
      # When a `field` (not `object` or `collection`) returns a value of the given class, it will be passed through
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
        formatters[klass] = formatter_method || formatter_block
      end

      #
      # Define an anonymous extension and add it to the current context.
      #
      # ```
      # class WidgetBlueprint < ApplicationBlueprint
      #   extension do
      #     # modify every object before serialization
      #     def around_serialize_object(ctx)
      #       ctx.object = modify ctx.object
      #       yield ctx
      #     end
      #   end
      # end
      # ```
      #
      def extension(&block)
        bp_name = blueprint_name
        extensions << Class.new(Extension) do
          @blueprint_name = bp_name
          def self.name = "#{@blueprint_name} extension"
          class_eval(&block)
        end.new
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
      # Proc options for `if`, `unless`, and `default` all accept a single argument: a {Blueprinter::V2::Context::Field}. It
      # contains all the context you could possibly want to implement your logic. Alternatively you can put your logic into
      # an instance method on the Blueprint (or view) and pass its name to `if`/`unless`/`default`.
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
      # NOTE: To ease with the transition from Legacy/V1, `if`/`unless` Procs that accept exactly **three** arguments will continue to work
      # like they did in Legacy/V1. This may be removed in the future.
      #
      # The Proc (or method name) passed to `default_if` accepts two arguments: a {Blueprinter::V2::Context::Field} and the
      # field's value.
      #
      # ```ruby
      # field :name, default: "None", default_if: ->(ctx, val) { val.blank? }
      # field :name, default: "None", default_if: :blank?
      #
      # def blank?(ctx, val) = val.blank?
      # ```
      #
      #
      # @param name [Symbol] Name of the field
      # @param source [Symbol] Optionally specify a different method/Hash key to call to get the value for "name"
      # @param default [Object | Symbol | Proc] Value to use if the field is nil, or if `default_if` returns true
      # @param default_if [Symbol | Proc] Return true to use the value in `default`
      # @param exclude_if_nil [true | false] Don't include field if the value is nil
      # @param if [Symbol | Proc] Only include the field if the given method or Proc returns true
      # @param unless [Symbol | Proc] Include the field unless the given method or Proc returns true
      # @yield [Object, Blueprinter::V2::Context::Field] Extract and return the field value
      #
      def field(name, source: name, **options, &definition)
        name = name.to_sym
        schema[name] = Fields::Field.new(
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
      # See {Blueprinter::V2::DSL#field} for documentation and examples of all options.
      #
      # @param *names [Symbol] Names of the fields
      # @param default [Object | Symbol | Proc] Value to use if the field is nil, or if `default_if` returns true
      # @param default_if [Symbol | Proc] Return true to use the value in `default`
      # @param exclude_if_nil [true | false] Don't include field if the value is nil
      # @param if [Symbol | Proc] Only include the field if the given method or Proc returns true
      # @param unless [Symbol | Proc] Include the field unless the given method or Proc returns true
      # @yield [Object, Blueprinter::V2::Context::Field] Extract and return the field value
      #
      def fields(*names, **options, &definition)
        names.each do |name|
          name = name.to_sym
          schema[name] = Fields::Field.new(
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
      #   # If you're referencing the same view, juse use `self`
      #   association :subwidget, self
      #
      #   # You can also use a Proc. This is REQUIRED if you're referencing a different
      #   # view from the same Blueprint.
      #   association :subwidget, -> { WidgetBlueprint[:extended] }
      #
      #   # The Proc can accept on arg: the object
      #   association :categories, [->(category) { category.blueprint }]
      # end
      # ```
      #
      # See {Blueprinter::V2::DSL#field} for documentation and examples of all options.
      #
      # @param name [Symbol] Name of the association
      # @param blueprint [Class|Proc|Array<Class|Proc>] Blueprint class to use (V1 or V2). For a collection, wrap the blueprint in
      #                  an array. You may also pass a Proc that returns a Blueprint.
      # @param source [Symbol] Optionally specify a different method/Hash key to call to get the value for "name"
      # @param default [Object | Symbol | Proc] Value to use if the field is nil, or if `default_if` returns true
      # @param default_if [Symbol | Proc] Return true to use the value in `default`
      # @param exclude_if_nil [true | false] Don't include field if the value is nil
      # @param if [Symbol | Proc] Only include the field if the given method or Proc returns true
      # @param unless [Symbol | Proc] Include the field unless the given method or Proc returns true
      # @yield [Object, Blueprinter::V2::Context::Field] Extract and return the field value
      #
      def association(name, blueprint, source: name, **options, &definition)
        name = name.to_sym
        is_collection, blueprint_class = parse_blueprint(blueprint)
        schema[name] = Fields::Field.new(
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
      # Exclude parent fields and associations from this view.
      #
      # ```
      # class WidgetBlueprint < ApplicationBlueprint
      #   fields :id, :name, :description
      #
      #   views :listing do
      #     exclude :description
      #     field :price
      #   end
      # end
      # ```
      #
      # @param *names [Symbol] One or more fields or associations to exclude
      #
      def exclude(*names)
        self.exclusions += names.map(&:to_sym)
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
