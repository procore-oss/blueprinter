module Blueprinter
  module BaseHelpers
    def self.included(base)
      base.extend(SingletonMethods)
    end

    module SingletonMethods
      private
      def active_record_relation?(object)
        !!(defined?(ActiveRecord::Relation) &&
          object.is_a?(ActiveRecord::Relation))
      end

      def prepare_for_render(object, options)
        view_name = options.delete(:view) || :default
        root = options.delete(:root)
        meta = options.delete(:meta)
        validate_root_and_meta(root, meta)
        prepare(object, view_name: view_name, local_options: options, root: root, meta: meta)
      end

      def prepare_data(object, view_name, local_options)
        if array_like?(object)
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
        ret = { root => data }
        meta ? ret.merge!(meta: meta) : ret
      end

      def inherited(subclass)
        subclass.send(:view_collection).inherit(view_collection)
      end

      def object_to_hash(object, view_name:, local_options:)
        fields = view_collection.fields_for view_name do |name|
          name.is_a?(Proc) ? name.call(object, local_options) : name
        end
        fields.each_with_object({}) do |field, hash|
          next if field.skip?(field.name, object, local_options)
          hash[field.name] = field.extract(object, local_options)
        end
      end

      def validate_root_and_meta(root, meta)
        case root
        when String, Symbol
          # no-op
        when NilClass
          raise BlueprinterError, "meta requires a root to be passed" if meta
        else
          raise BlueprinterError, "root should be one of String, Symbol, NilClass"
        end
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

      def array_like?(object)
        object.is_a?(Array) || active_record_relation?(object)
      end

      def associations(view_name = :default)
        view_collection.fields_for(view_name).select { |f| f.options[:association] }
      end
    end
  end
end
