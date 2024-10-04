# frozen_string_literal: true

require 'blueprinter/helpers/type_helpers'
require 'blueprinter/view_collection'

module Blueprinter
  module BaseHelpers
    def self.included(base)
      base.extend(SingletonMethods)
    end

    module SingletonMethods
      include TypeHelpers

      private

      def prepare_for_render(object, options)
        view_name = options.fetch(:view, :default) || :default
        root = options[:root]
        meta = options[:meta]
        validate_root_and_meta!(root, meta)
        prepare(
          object,
          view_name: view_name,
          local_options: options.except(
            :view,
            :root,
            :meta
          ),
          root: root,
          meta: meta
        )
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
        result_hash = view_collection.fields_for(view_name).each_with_object({}) do |field, hash|
          next if field.skip?(field.name, object, local_options)

          value = field.extract(object, local_options)

          next if value.nil? && field.options[:exclude_if_nil]

          hash[field.name] = value
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
          raise BlueprinterError, 'meta requires a root to be passed' if meta
        else
          raise BlueprinterError, 'root should be one of String, Symbol, NilClass'
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

      def associations(view_name = :default)
        view_collection.fields_for(view_name).select { |f| f.options[:association] }
      end
    end
  end
end
