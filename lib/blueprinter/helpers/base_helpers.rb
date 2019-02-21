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
        symbol_or_string_or_nil?(root, :root)
        meta = options.delete(:meta)
        prepare(object, view_name: view_name, local_options: options, root: root, meta: meta)
      end

      def prepare_data(object, view_name, local_options)
        prepared_object = include_associations(object, view_name: view_name)
        if array_like?(object)
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

      def prepend_root_and_meta(data, root, meta)
        return data unless root
        ret = { root => data }
        meta ? ret.merge!(meta: meta) : ret
      end
      
      def inherited(subclass)
        subclass.send(:view_collection).inherit(view_collection)
      end

      def object_to_hash(object, view_name:, local_options:)
        view_collection.fields_for(view_name).each_with_object({}) do |field, hash|
          next if field.skip?(object, local_options)
          hash[field.name] = field.extract(object, local_options)
        end
      end

      def symbol_or_string_or_nil?(obj, key)
        case obj
        when String, Symbol, NilClass
          # no-op
        else
          raise BlueprinterError, "#{key} should be one of String, Symbol, NilClass"
        end
      end

      def include_associations(object, view_name:)
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
