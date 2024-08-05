# frozen_string_literal: true

module Blueprinter
  class V2
    module DSL
      # Define a new child view, which is a subclass of self
      def view(name, &definition)
        raise Errors::InvalidBlueprint, "View name may not contain '.'" if name.to_s =~ /\./

        view = Class.new(self)
        view.append_name(name)
        view.class_eval(&definition) if definition
        views[name.to_sym] = view
      end

      # Define a field
      # rubocop:todo Lint/UnusedMethodArgument
      def field(name, options = {})
        fields[name.to_sym] = 'TODO'
      end

      # Define an association
      def association(name, blueprint, options = {})
        fields[name.to_sym] = 'TODO'
      end

      # Exclude fields/associations
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

      # rubocop:enable Lint/UnusedMethodArgument
    end
  end
end
