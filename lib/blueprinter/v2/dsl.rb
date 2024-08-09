# frozen_string_literal: true

require 'blueprinter/v2/association'
require 'blueprinter/v2/field'

module Blueprinter
  class V2
    # Methods for defining Blueprint fields and views
    module DSL
      #
      # Define a new child view, which is a subclass of self.
      #
      # @param name [Symbol] Name of the view
      # @yield Define the view in the block
      # @return [Class] An annonymous subclass of Blueprinter::V2
      #
      def view(name, &definition)
        raise Errors::InvalidBlueprint, "View name may not contain '.'" if name.to_s =~ /\./

        view = Class.new(self)
        view.append_name(name)
        view.class_eval(&definition) if definition
        views[name.to_sym] = view
      end

      #
      # Define a field.
      #
      # @param name [Symbol] Name of the field
      # @param from [Symbol] Optionally specify a different method to call to get the value for "name"
      # @param if [Proc] Only include this field if the Proc evaluates to truthy
      # @yield [TODO] Generate the value from the block
      # @return [Blueprinter::V2::Field]
      #
      def field(name, from: name, **options, &definition)
        fields[name.to_sym] = Field.new(
          name: name,
          from: from,
          if_cond: options.delete(:if),
          value_proc: definition,
          custom_options: options
        )
      end

      #
      # Define an association.
      #
      # @param name [Symbol] Name of the association
      # @param blueprint [Class|Proc] Blueprint class to use, or one defined with a Proc
      # @param view [Symbol] Only for use with legacy (not V2) blueprints
      # @param from [Symbol] Optionally specify a different method to call to get the value for "name"
      # @param if [Proc] Only include this association if the Proc evaluates to truthy
      # @yield [TODO] Generate the value from the block
      # @return [Blueprinter::V2::Association]
      #
      def association(name, blueprint, from: name, view: nil, **options, &definition)
        raise ArgumentError, 'The :view argument may not be used with V2 Blueprints' if view && blueprint.is_a?(V2)

        fields[name.to_sym] = Association.new(
          name: name,
          blueprint: blueprint,
          legacy_view: view,
          from: from,
          if_cond: options.delete(:if),
          value_proc: definition,
          custom_options: options
        )
      end

      # Exclude parent fields/associations from inheritance
      def exclude(*names)
        unknown = []
        names.each do |name|
          name_sym = name.to_sym
          if fields.key? name_sym
            fields.delete name_sym
          else
            unknown << name.to_s
          end
        end
        raise Errors::InvalidBlueprint, "Unknown excluded fields in '#{self}': #{unknown.join(', ')}" if unknown.any?
      end
    end
  end
end
