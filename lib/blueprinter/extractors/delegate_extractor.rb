module Blueprinter
  # @api private
  class DelegateExtractor < Extractor
    DelegateArgumentError = Class.new(BlueprinterError)

    def extract(field_name, object, _local_options, options = {})
      delegate_options = options[:delegate]
      raise(DelegateArgumentError, "#{field_name}: delegate[:to] need to define") unless delegate_options.has_key?(:to)
      delegated_object = object.public_send(delegate_options[:to])
      return nil if delegated_object.nil?
      raise(DelegateArgumentError, "#{field_name}: delegate[:source] need to define") unless delegate_options.has_key?(:source)
      delegated_object.public_send(delegate_options[:source])
    end
  end
end
