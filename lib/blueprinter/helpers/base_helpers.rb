module Blueprinter
  module BaseHelpers
    def self.included(base)
      base.extend(SingletonMethods)
    end

    module SingletonMethods
      include TypeHelpers

      private

      def prepare_for_render(object, options)
        view_name = options.delete(:view) || :default
        root = options.delete(:root)
        meta = options.delete(:meta)
        validate_root_and_meta!(root, meta)
        prepare(object, view_name: view_name, local_options: options, root: root, meta: meta)
      end

      def prepare_data(object, view_name, local_options)
        # instead of iterating over each task in object, I'd rather say object.includes(:predecessor_ids, :)
        puts "i'm here"
        puts 'view_name is: ' + view_name.to_s
        # remove view_name == :extended
        if active_record_relation?(object) && view_name == :extended
          object_relation_to_hash(object, view_name: view_name, local_options: local_options)
        elsif array_like?(object)
          object.map do |obj|
            object_to_hash(obj,
                           view_name: view_name,
                           local_options: local_options)
          end
        else
          object_to_hash(object,
                         view_name: view_name,
                         local_options: local_options)
        end
      end

      def prepend_root_and_meta(data, root, meta)
        return data unless root
        ret = {root => data}
        meta ? ret.merge!(meta: meta) : ret
      end

      def inherited(subclass)
        subclass.send(:view_collection).inherit(view_collection)
      end

      def object_relation_to_hash(object_relation, view_name:, local_options:)
        fields_to_eager_load = view_collection.fields_for(view_name).select{|f| f.eager_load?}.map{|e| e.name&.to_sym}
        records_with_associations_loaded = object_relation.includes(fields_to_eager_load)
        result_array = Array.new(records_with_associations_loaded.size)#create array of hashes
        records_with_associations_loaded.each_with_index.map do |record, index|
          record_hash = object_to_hash(record, view_name: view_name, local_options: local_options) #non-eager loaded
          # fields_to_eager_load.each do |eager_field|
          #   record_hash[eager_field] = record.send(eager_field)
          # end
          result_array[index] = record_hash
        end
        result_array
      end

      def object_to_hash(object, view_name:, local_options:)
        result_hash = view_collection.fields_for(view_name).each_with_object({}) do |field, hash|
          next if field.skip?(field.name, object, local_options) #|| field.eager_load?
          puts 'name is: ' + field.name.to_s
          hash[field.name] = field.extract(object, local_options)
        end
        view_collection.transformers(view_name).each do |transformer|
          transformer.transform(result_hash, object, local_options)
        end
        result_hash
      end

      def validate_root_and_meta!(root, meta)
        case root
        when String, Symbol
          # no-op
        when NilClass
          raise BlueprinterError, "meta requires a root to be passed" if meta
        else
          raise BlueprinterError, "root should be one of String, Symbol, NilClass"
        end
      end

      def dynamic_blueprint?(blueprint)
        blueprint.is_a?(Proc)
      end

      def validate_blueprint!(blueprint, method)
        validate_presence_of_blueprint!(blueprint)
        unless dynamic_blueprint?(blueprint)
          validate_blueprint_has_ancestors!(blueprint, method)
          validate_blueprint_has_blueprinter_base_ancestor!(blueprint, method)
        end
      end

      def validate_presence_of_blueprint!(blueprint)
        raise BlueprinterError, 'Blueprint required' unless blueprint
      end

      def validate_blueprint_has_ancestors!(blueprint, association_name)
        # If the class passed as a blueprint does not respond to ancestors
        # it means it, at the very least, does not have Blueprinter::Base as
        # one of its ancestor classes (e.g: Hash) and thus an error should
        # be raised.
        unless blueprint.respond_to?(:ancestors)
          raise BlueprinterError, "Blueprint provided for #{association_name} "\
                                'association is not valid.'
        end
      end

      def validate_blueprint_has_blueprinter_base_ancestor!(blueprint, association_name)
        # Guard clause in case Blueprinter::Base is present in the ancestor list
        # for the blueprint class provided.
        return if blueprint.ancestors.include? Blueprinter::Base

        # Raise error describing what's wrong.
        raise BlueprinterError, "Class #{blueprint.name} does not inherit from "\
                              'Blueprinter::Base and is not a valid Blueprinter '\
                              "for #{association_name} association."
      end

      def jsonify(blob)
        Blueprinter.configuration.jsonify(blob)
      end

      def current_view
        @current_view ||= view_collection[:default]
      end

      def view_collection
        @view_collection ||= ViewCollection.new
      end

      def associations(view_name = :default)
        view_collection.fields_for(view_name).select { |f| f.options[:association] }
      end
    end
  end
end
