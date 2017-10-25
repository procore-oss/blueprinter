require 'json'
require_relative 'blueprinter_error'
require_relative 'field'
require_relative 'serializer'
require_relative 'view'
require_relative 'view_collection'
require_relative 'optimizer'
require_relative 'serializers/association_serializer'
require_relative 'serializers/public_send_serializer'
require_relative 'serializers/block_serializer'

module Blueprinter
  class Base
    # Specify a field or method name used as an identifier. Usually, this is
    # something like :id
    #
    # Note: identifiers are always rendered and considerered their own view,
    # similar to the :default view.
    #
    # @param method [Symbol] the method or field used as an identifier that you
    #   want to set for serialization.
    # @param name [Symbol] to rename the identifier key in the JSON
    #   output. Defaults to method given.
    # @param serializer [AssociationSerializer,PublicSendSerializer]
    #   Kind of serializer to use.
    #   Either define your own or use Blueprinter's premade serializers.
    #   Defaults to PublicSendSerializer
    #
    # @example Specifying a uuid as an identifier.
    #   class UserBlueprint < Blueprinter::Base
    #     identifier :uuid
    #     # other code
    #   end
    #
    # @return [Field] A Field object
    def self.identifier(method, name: method, serializer: PublicSendSerializer)
      view_collection[:identifier] << Field.new(method, name, serializer)
    end

    # Specify a field or method name to be included for serialization.
    # Takes a required method and an option.
    #
    # @param method [Symbol] the field or method name you want to include for
    #   serialization.
    # @param options [Hash] options to overide defaults.
    # @option options [AssociationSerializer,PublicSendSerializer] :serializer
    #   Kind of serializer to use.
    #   Either define your own or use Blueprinter's premade serializers. The
    #   Default serializer is AssociationSerializer
    # @option options [Symbol] :name Use this to rename the method. Useful if
    #   if you want your JSON key named differently in the output than your
    #   object's field or method name.
    # @yield [Object] The object passed to `render` is also passed to the
    #   block.
    #
    # @example Specifying a user's first_name to be serialized.
    #   class UserBlueprint < Blueprinter::Base
    #     field :first_name
    #     # other code
    #   end
    #
    # @example Passing a block to be evaluated as the value.
    #   class UserBlueprint < Blueprinter::Base
    #     field :full_name {|obj| "#{obj.first_name} #{obj.last_name}"}
    #     # other code
    #   end
    #
    # @return [Field] A Field object
    def self.field(method, options = {}, &block)
      options = if block_given?
        {name: method, serializer: BlockSerializer, block: {method => block}}
      else
        {name: method, serializer: AssociationSerializer}
      end.merge(options)
      current_view << Field.new(method,
                                options[:name],
                                options[:serializer],
                                options)
    end

    # Specify an associated object to be included for serialization.
    # Takes a required method and an option.
    #
    # @param method [Symbol] the association name
    # @param options [Hash] options to overide defaults.
    # @option options [Symbol] :name Use this to rename the association in the
    #   JSON output.
    # @option options [Symbol] :view Specify the view to use or fall back to
    #   to the :default view.
    #
    # @example Specifying an association
    #   class UserBlueprint < Blueprinter::Base
    #     # code
    #     association :vehicles, view: :extended
    #     # code
    #   end
    #
    # @return [Field] A Field object
    def self.association(method, options = {})
      name = options.delete(:name) || method
      current_view << Field.new(method,
                                       name,
                                       AssociationSerializer,
                                       options.merge(association: true))
    end

    # Generates a JSON formatted String.
    # Takes a required object and an optional view.
    #
    # @param object [Object] the Object to serialize upon.
    # @param options [Hash] the options hash which requires a :view. Any
    #   additional key value pairs will be exposed during serialization.
    # @option options [Symbol] :view Defaults to :default.
    #   The view name that corresponds to the group of
    #   fields to be serialized.
    #
    # @example Generating JSON with an extended view
    #   post = Post.all
    #   Blueprinter::Base.render post, view: :extended
    #   # => "[{\"id\":1,\"title\":\"Hello\"},{\"id\":2,\"title\":\"My Day\"}]"
    #
    # @return [String] JSON formatted String
    def self.render(object, options = {})
      view_name = options.delete(:view) || :default
      jsonify(prepare(object, view_name: view_name, local_options: options))
    end

    # This is the magic method that converts complex objects into a simple hash
    # ready for JSON conversion.
    #
    # Note: we accept view (public interface) that is in reality a view_name,
    # so we rename it for clarity
    #
    # @api private
    def self.prepare(object, view_name:, local_options:)
      unless view_collection.has_view? view_name
        raise BlueprinterError, "View '#{view_name}' is not defined"
      end
      fields = view_collection.fields_for(view_name)
      prepared_object = Optimizer.optimize(object, fields: fields)
      prepared_object = include_associations(prepared_object, view_name: view_name)
      if prepared_object.respond_to? :map
        prepared_object.map do |obj|
          object_to_hash(obj,
                         view_name: view_name,
                         local_options: local_options)
        end
      else
        object_to_hash(prepared_object,
                       view_name: view_name,
                       local_options: local_options)
      end
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
    def self.fields(*field_names)
      field_names.each do |field_name|
        current_view << Field.new(field_name, field_name, PublicSendSerializer)
      end
    end

    # @api private
    def self.associations(view_name = :default)
      view_collection.fields_for(view_name).select { |f| f.options[:association] }
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
    def self.include_view(view_name)
      current_view.include_view(view_name)
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
    def self.exclude(field_name)
      current_view.exclude_field(field_name)
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
    def self.view(view_name)
      @current_view = view_collection[view_name]
      yield
      @current_view = view_collection[:default]
    end

    private

    def self.object_to_hash(object, view_name:, local_options:)
      view_collection.fields_for(view_name).each_with_object({}) do |field, hash|
        hash[field.name] = field.serializer.serialize(field.method,
                                                      object,
                                                      local_options,
                                                      field.options)
      end
    end
    private_class_method :object_to_hash

    def self.include_associations(object, view_name:)
      unless defined?(ActiveRecord::Base) &&
          object.is_a?(ActiveRecord::Base) &&
          object.respond_to?(:klass)
        return object
      end
      # TODO: Do we need to support more than `eager_load` ?
      fields_to_include = associations(view).select { |a|
        a.options[:include] != false
      }.map(&:method)
      if !fields_to_include.empty?
        object.eager_load(*fields_to_include)
      else
        object
      end
    end
    private_class_method :include_associations

    def self.jsonify(blob)
      if blob.respond_to? :to_json
        blob.to_json
      else
        JSON.generate(blob)
      end
    end
    private_class_method :jsonify

    def self.current_view
      @current_view ||= view_collection[:default]
    end
    private_class_method :current_view

    def self.view_collection
      @view_collection ||= ViewCollection.new
    end
    private_class_method :view_collection
  end
end
