# frozen_string_literal: true

require_relative 'association'
require_relative 'extractors/association_extractor'
require_relative 'field'
require_relative 'reflection'
require_relative 'rendering'
require_relative 'view_collection'

module Blueprinter
  class Base
    extend Reflection
    extend Rendering

    class << self
      # Specify a field or method name used as an identifier. Usually, this is
      # something like `:id`.
      #
      # Note: identifiers are always rendered and considered their own view,
      # similar to the :default view.
      #
      # @param method [Symbol] the method or field used as an identifier that you
      #   want to set for serialization.
      # @param name [Symbol] to rename the identifier key in the JSON
      #   output. Defaults to method given.
      # @param extractor [AssociationExtractor,AutoExtractor,BlockExtractor,HashExtractor,PublicSendExtractor]
      # @yield [object, options] The object and the options passed to render are
      #   also yielded to the block.
      #
      #   Kind of extractor to use.
      #   Either define your own or use Blueprinter's premade extractors.
      #   Defaults to AutoExtractor
      #
      # @example Specifying a uuid as an identifier.
      #   class UserBlueprint < Blueprinter::Base
      #     identifier :uuid
      #     # other code
      #   end
      #
      # @example Passing a block to be evaluated as the value.
      #   class UserBlueprint < Blueprinter::Base
      #     identifier :uuid do |user, options|
      #       options[:current_user].anonymize(user.uuid)
      #     end
      #   end
      #
      # @return [Field] A Field object
      def identifier(method, name: method, extractor: Blueprinter.configuration.extractor_default.new, &block)
        view_collection[:identifier] << Field.new(
          method,
          name,
          extractor,
          self,
          block:
        )
      end

      # Specify a field or method name to be included for serialization.
      # Takes a required method and an option.
      #
      # @param method [Symbol] the field or method name you want to include for
      #   serialization.
      # @param options [Hash] options to overide defaults.
      # @option options [AssociationExtractor,BlockExtractor,HashExtractor,PublicSendExtractor] :extractor
      #   Kind of extractor to use.
      #   Either define your own or use Blueprinter's premade extractors. The
      #   Default extractor is AutoExtractor
      # @option options [Symbol] :name Use this to rename the method. Useful if
      #   if you want your JSON key named differently in the output than your
      #   object's field or method name.
      # @option options [String,Proc] :datetime_format Format Date or DateTime object
      #   If the option provided is a String, the object will be formatted with given strftime
      #   formatting.
      #   If this option is a Proc, the object will be formatted by calling the provided Proc
      #   on the Date/DateTime object.
      # @option options [Symbol,Proc] :if Specifies a method, proc or string to
      #   call to determine if the field should be included (e.g.
      #   `if: :include_name?, or if: Proc.new { |_field_name, user, options| options[:current_user] == user }).
      #   The method, proc or string should return or evaluate to a true or false value.
      # @option options [Symbol,Proc] :unless Specifies a method, proc or string
      #   to call to determine if the field should be included (e.g.
      #   `unless: :include_name?, or unless: Proc.new { |_field_name, user, options| options[:current_user] != user }).
      #   The method, proc or string should return or evaluate to a true or false value.
      # @yield [object, options] The object and the options passed to render are
      #   also yielded to the block.
      #
      # @example Specifying a user's first_name to be serialized.
      #   class UserBlueprint < Blueprinter::Base
      #     field :first_name
      #     # other code
      #   end
      #
      # @example Passing a block to be evaluated as the value.
      #   class UserBlueprint < Blueprinter::Base
      #     field :full_name do |object, options|
      #       "options[:title_prefix] #{object.first_name} #{object.last_name}"
      #     end
      #     # other code
      #   end
      #
      # @example Passing an if proc and unless method.
      #   class UserBlueprint < Blueprinter::Base
      #     def skip_first_name?(_field_name, user, options)
      #       user.first_name == options[:first_name]
      #     end
      #
      #     field :first_name, unless: :skip_first_name?
      #     field :last_name, if: ->(_field_name, user, options) { user.first_name != options[:first_name] }
      #     # other code
      #   end
      #
      # @return [Field] A Field object
      def field(method, options = {}, &block)
        method = method.to_sym

        current_view << Field.new(
          method,
          options.fetch(:name) { method },
          options.fetch(:extractor) { Blueprinter.configuration.extractor_default.new },
          self,
          options.merge(block:)
        )
      end

      # Specify an associated object to be included for serialization.
      # Takes a required method and an option.
      #
      # @param method [Symbol] the association name
      # @param options [Hash] options to overide defaults.
      # @option options [Symbol] :blueprint Required. Use this to specify the
      #   blueprint to use for the associated object.
      # @option options [Symbol] :name Use this to rename the association in the
      #   JSON output.
      # @option options [Symbol] :view Specify the view to use or fall back to
      #   to the :default view.
      # @yield [object, options] The object and the options passed to render are
      #   also yielded to the block.
      #
      # @example Specifying an association
      #   class UserBlueprint < Blueprinter::Base
      #     # code
      #     association :vehicles, view: :extended, blueprint: VehiclesBlueprint
      #     # code
      #   end
      #
      # @example Passing a block to be evaluated as the value.
      #   class UserBlueprint < Blueprinter::Base
      #     association :vehicles, blueprint: VehiclesBlueprint do |user, opts|
      #       user.vehicles + opts[:additional_vehicles]
      #     end
      #   end
      #
      # @return [Association] An object
      # @raise [Blueprinter::Errors::InvalidBlueprint] if provided blueprint is not valid
      def association(method, options = {}, &block)
        raise ArgumentError, ':blueprint must be provided when defining an association' unless options[:blueprint]

        method = method.to_sym
        current_view << Association.new(
          method:,
          name: options.fetch(:name) { method },
          extractor: options.fetch(:extractor) { AssociationExtractor.new },
          blueprint: options.fetch(:blueprint),
          parent_blueprint: self,
          view: options.fetch(:view, :default),
          options: options.except(:name, :extractor, :blueprint, :view).merge(block:)
        )
      end

      # Specify one or more field/method names to be included for serialization.
      # Takes at least one field or method names.
      #
      # @param method [Symbol] the field or method name you want to include for
      #   serialization.
      #
      # @example Specifying a user's first_name and last_name to be serialized.
      #   class UserBlueprint < Blueprinter::Base
      #     fields :first_name, :last_name
      #     # other code
      #   end
      #
      # @return [Array<Symbol>] an array of field names
      def fields(*field_names)
        field_names.each do |field_name|
          field(field_name)
        end
      end

      # Specify one transformer to be included for serialization.
      # Takes a class which extends Blueprinter::Transformer
      #
      # @param class name [Class] which implements the method transform to include for
      #   serialization.
      #
      #
      # @example Specifying a DynamicFieldTransformer transformer for including dynamic fields to be serialized.
      #   class User
      #     def custom_columns
      #       dynamic_fields # which is an array of some columns
      #     end
      #
      #     def custom_fields
      #       custom_columns.each_with_object({}) { |col,result| result[col] = send(col) }
      #     end
      #   end
      #
      #   class UserBlueprint < Blueprinter::Base
      #     fields :first_name, :last_name
      #     transform DynamicFieldTransformer
      #     # other code
      #   end
      #
      #   class DynamicFieldTransformer < Blueprinter::Transformer
      #     def transform(hash, object, options)
      #       hash.merge!(object.dynamic_fields)
      #     end
      #   end
      #
      # @return [Array<Class>] an array of transformers
      def transform(transformer)
        current_view.add_transformer(transformer)
      end

      # Specify another view that should be mixed into the current view.
      #
      # @param view_name [Symbol] the view to mix into the current view.
      #
      # @example Including a normal view into an extended view.
      #   class UserBlueprint < Blueprinter::Base
      #     # other code...
      #     view :normal do
      #       fields :first_name, :last_name
      #     end
      #     view :extended do
      #       include_view :normal # include fields specified from above.
      #       field :description
      #     end
      #     #=> [:first_name, :last_name, :description]
      #   end
      #
      # @return [Array<Symbol>] an array of view names.
      def include_view(view_name)
        current_view.include_view(view_name)
      end

      # Specify additional views that should be mixed into the current view.
      #
      #  @param view_name [Array<Symbol>] the views to mix into the current view.
      #
      # @example Including the normal and special views into an extended view.
      #   class UserBlueprint < Blueprinter::Base
      #     # other code...
      #     view :normal do
      #       fields :first_name, :last_name
      #     end
      #     view :special do
      #       fields :birthday, :company
      #     end
      #     view :extended do
      #       include_views :normal, :special # include fields specified from above.
      #       field :description
      #     end
      #     #=> [:first_name, :last_name, :birthday, :company, :description]
      #   end
      #
      # @return [Array<Symbol>] an array of view names.
      def include_views(*view_names)
        current_view.include_views(view_names)
      end

      # Exclude a field that was mixed into the current view.
      #
      # @param field_name [Symbol] the field to exclude from the current view.
      #
      # @example Excluding a field from being included into the current view.
      #   view :normal do
      #     fields :position, :company
      #   end
      #   view :special do
      #     include_view :normal
      #     field :birthday
      #     exclude :position
      #   end
      #   #=> [:company, :birthday]
      #
      # @return [Array<Symbol>] an array of field names
      def exclude(field_name)
        current_view.exclude_field(field_name)
      end

      # When mixing multiple views under a single view, some fields may required to be excluded from
      # current view
      #
      # @param [Array<Symbol>] the fields to exclude from the current view.
      #
      # @example Excluding mutiple fields from being included into the current view.
      #   view :normal do
      #     fields :name,:address,:position,
      #           :company, :contact
      #   end
      #   view :special do
      #     include_view :normal
      #     fields :birthday,:joining_anniversary
      #     excludes :position,:address
      #   end
      #   => [:name, :company, :contact, :birthday, :joining_anniversary]
      #
      # @return [Array<Symbol>] an array of field names
      def excludes(*field_names)
        current_view.exclude_fields(field_names)
      end

      # Specify a view and the fields it should have.
      # It accepts a view name and a block. The block should specify the fields.
      #
      # @param view_name [Symbol] the view name
      # @yieldreturn [#fields,#field,#include_view,#exclude] Use this block to
      #   specify fields, include fields from other views, or exclude fields.
      #
      # @example Using views
      #   view :extended do
      #     fields :position, :company
      #     include_view :normal
      #     exclude :first_name
      #   end
      #
      # @return [View] a Blueprinter::View object
      def view(view_name)
        self.view_scope = view_collection[view_name]
        view_collection[:default].track_definition_order(view_name)
        yield
        self.view_scope = view_collection[:default]
      end

      # Check whether or not a Blueprint supports the supplied view.
      # It accepts a view name.
      #
      # @param view_name [Symbol] the view name
      #
      # @example With the following Blueprint
      #
      # class ExampleBlueprint < Blueprinter::Base
      #  view :custom do
      #  end
      # end
      #
      #  ExampleBlueprint.view?(:custom) => true
      #  ExampleBlueprint.view?(:doesnt_exist) => false
      #
      # @return [Boolean] a boolean value indicating if the view is
      # supported by this Blueprint.
      def view?(view_name)
        view_collection.view?(view_name)
      end

      def view_collection
        @_view_collection ||= ViewCollection.new
      end

      private

      attr_accessor :view_scope

      # Returns the current view during Blueprint definition based on the view_scope.
      def current_view
        view_scope || view_collection[:default]
      end

      def inherited(subclass)
        subclass.send(:view_collection).inherit(view_collection)
      end
    end
  end
end
