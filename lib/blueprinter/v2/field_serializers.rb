# frozen_string_literal: true

module Blueprinter
  module V2
    module FieldSerializers
      autoload :Base, 'blueprinter/v2/field_serializers/base'
      autoload :Collection, 'blueprinter/v2/field_serializers/collection'
      autoload :Field, 'blueprinter/v2/field_serializers/field'
      autoload :Object, 'blueprinter/v2/field_serializers/object'
    end
  end
end
