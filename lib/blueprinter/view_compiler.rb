# frozen_string_literal: true

module Blueprinter
  # @api private
  #
  # Compiles a view into a module whose `call(object, options)` builds the object's Hash with a Hash literal and direct
  # method calls, e.g. `{ id: object.id, name: object.name }`. Used when `Blueprinter.configuration.compile_views` is on.
  #
  # Only simple fields are compiled: values read with AutoExtractor (by method or block), optionally with if/unless and
  # exclude_if_nil. Every other field (associations, defaults, datetime formats, custom extractors) calls Field#skip? and
  # Field#extract, exactly like standard rendering.
  #
  # The result is only valid while datetime_format, field_default and the global if/unless are unset;
  # Rendering#prepare_data checks that on every render. Blocks, callables, fields, transformers and unusual names live in
  # the module's REFS constant and are referenced by index, so user-provided text is never interpolated as code.
  module ViewCompiler
    # Method names that can be called directly as `object.name`
    CALLABLE_METHOD = /\A[a-z_][a-zA-Z0-9_]*[?!]?\z/
    # Symbols that can be written as `name:` keys or `:name` literals
    LITERAL_SYMBOL = /\A[a-zA-Z_][a-zA-Z0-9_]*\z/

    module_function

    # @return [Module] responds to `call(object, options)` and returns the object's Hash
    def compile(fields, transformers)
      refs = []
      ref = ->(value) { "REFS[#{refs.push(value).size - 1}]" }
      body = body(fields, transformers, ref)

      Module.new.tap do |compiled|
        compiled.const_set(:REFS, refs.freeze)
        compiled.module_eval(<<~RUBY, __FILE__, __LINE__ + 1)
          def self.call(object, options)  # def self.call(object, options)
            #{body}                       #   { id: object.id, name: object.name }
          end                             # end
        RUBY
      end
    end

    def body(fields, transformers, ref)
      literal = []
      statements = []
      keys = {}

      fields.each do |field|
        key = key_for(field.name, ref)
        value = simple_value(field, ref)
        # A repeated name keeps its first position and its last value, like assigning a Hash key twice
        if value && statements.empty? && literal_field?(field, keys)
          literal << "#{key} => #{value}"
        else
          statements << statement(field, key, value, ref)
        end
        keys[field.name] = true
      end
      transformers.each { |transformer| statements << "#{ref.call(transformer)}.transform(h, object, options)" }

      statements.empty? ? "{ #{literal.join(', ')} }" : "h = { #{literal.join(', ')} }\n#{statements.join("\n")}\nh"
    end

    # The value expression for a field compiled directly, or nil for a field that uses standard rendering
    def simple_value(field, ref)
      options = field.options
      return nil if options[:datetime_format] || options[:default_if] || options.key?(:default)
      return association_value(field, ref) if options[:association]
      return nil unless field.extractor.instance_of?(AutoExtractor)

      read(field, ref)
    end

    # Same as AssociationExtractor#extract + the associated Blueprint's #hashify, for associations with a static
    # blueprint and no :options. nil stays nil, because association_default is unset (see Rendering#compiled_view).
    def association_value(field, ref)
      extractor = field.extractor
      blueprint = field.options[:blueprint]
      view = field.options[:view] || :default
      return nil unless extractor.instance_of?(AssociationExtractor) &&
                        extractor.instance_variable_get(:@extractor).instance_of?(AutoExtractor) &&
                        blueprint.is_a?(Class) && field.options[:options].nil? && blueprint.view?(view)

      "((a = #{read(field, ref)}).nil? ? nil : ::Blueprinter::ViewCompiler.render_association(a, " \
        "#{ref.call(blueprint)}, #{ref.call(view)}, options))"
    end

    # Same as AutoExtractor reading a value: BlockExtractor's calling convention, or PublicSendExtractor
    def read(field, ref)
      block = field.options[:block]
      if block
        call_args = block.parameters == [[:req], [:rest]] ? 'object' : 'object, **options'
        "#{ref.call(block)}.call(#{call_args})"
      elsif field.method.to_s.match?(CALLABLE_METHOD)
        "object.#{field.method}"
      else
        "object.public_send(#{ref.call(field.method)})"
      end
    end

    # The steps of Rendering#hashify after its view check (done at compile time): extensions, then the same work as
    # prepare_data. The global settings were already checked for this render, so the child's compiled view is used
    # directly; options are only copied when the view differs, since their content would be the same.
    def render_association(value, blueprint, view, options)
      config = Blueprinter.configuration
      value = config.extensions.pre_render(value, blueprint, view, options) unless config.extensions.empty?
      options = options.merge(view:) unless options[:view] == view
      compiled = blueprint.view_collection.compiled(view)

      if config.array_like_classes.any? { |klass| value.is_a?(klass) }
        value.map { |item| render_one(item, blueprint, view, options, compiled) }
      else
        render_one(value, blueprint, view, options, compiled)
      end
    end

    # Hashes use standard rendering, like in Rendering#prepare_data
    def render_one(object, blueprint, view, options, compiled)
      return compiled.call(object, options) unless object.is_a?(Hash)

      blueprint.__send__(:object_to_hash, object, view_name: view, local_options: options)
    end

    def statement(field, key, value, ref)
      unless value
        # Standard rendering for this field
        field_ref = ref.call(field)
        value = "#{field_ref}.extract(object, options)"
        condition = "!#{field_ref}.skip?(#{key}, object, options)"
      end
      condition ||= field_conditions(field, key, ref)
      store = field.options[:exclude_if_nil] ? "v = #{value}\nh[#{key}] = v unless v.nil?" : "h[#{key}] = #{value}"
      condition ? "if #{condition}\n#{store}\nend" : store
    end

    # Same as Field#skip? for field-level if/unless (global ones are excluded by Rendering#prepare_data)
    def field_conditions(field, key, ref)
      parts = []
      parts << "#{ref.call(field.send(:if_callable))}.call(#{key}, object, options)" if field.options[:if]
      parts << "!#{ref.call(field.send(:unless_callable))}.call(#{key}, object, options)" if field.options[:unless]
      parts.empty? ? nil : parts.join(' && ')
    end

    # Unconditional fields that are always stored and whose name is not repeated can go in the Hash literal
    def literal_field?(field, keys)
      !field.options[:if] && !field.options[:unless] && !field.options[:exclude_if_nil] && !keys.key?(field.name)
    end

    def key_for(name, ref)
      name.is_a?(Symbol) && name.to_s.match?(LITERAL_SYMBOL) ? ":#{name}" : ref.call(name)
    end
  end
end
