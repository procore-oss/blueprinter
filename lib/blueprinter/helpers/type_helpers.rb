module Blueprinter
  module TypeHelpers
    private
    def active_record_relation?(object)
      !!(defined?(ActiveRecord::Relation) &&
        object.is_a?(ActiveRecord::Relation))
    end

    def array_like?(object)
      object.is_a?(Enumerable) || active_record_relation?(object)
    end
  end
end
