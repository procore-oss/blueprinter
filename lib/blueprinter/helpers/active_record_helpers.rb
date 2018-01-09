module Blueprinter
  module ActiveRecordHelpers
    def self.included(base)
      base.extend(SingletonMethods)
    end

    def active_record_relation?(object)
      self.class.active_record_relation?(object)
    end

    module SingletonMethods
      def active_record_relation?(object)
        !!(defined?(ActiveRecord::Relation) &&
          object.is_a?(ActiveRecord::Relation))
      end
    end
  end
end
