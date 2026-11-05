# frozen_string_literal: true

module Blueprinter
  # @api private
  #
  # Compiles a view into a module whose `call(object, options)` builds the object's Hash with a Hash literal and direct
  # method calls, e.g. `{ id: object.id, name: object.name }`. Used when `Blueprinter.configuration.compile_views` is on.
  #
  # Only simple fields are compiled: values read with AutoExtractor (by method or block), optionally with if/unless and
  # exclude_if_nil, with no option outside COMPILABLE_OPTIONS. Every other field (associations, defaults, datetime
  # formats, custom extractors, options the compiler does not know) calls Field#skip? and Field#extract, exactly like
  # standard rendering.
  #
  # The result is only valid while datetime_format, field_default, association_default and the global if/unless are
  # unset; Configuration#views_compilable? checks that on every render. Blocks, callables, fields, transformers and
  # unusual names live in the module's REFS constant and are referenced by index, so user-provided text is never
  # interpolated as code.
  module ViewCompiler
    # Method names that can be called directly as `object.name`
    CALLABLE_METHOD = /\A[a-z_][a-zA-Z0-9_]*[?!]?\z/
    # Symbols that can be written as `name:` keys or `:name` literals
    LITERAL_SYMBOL = /\A[a-zA-Z_][a-zA-Z0-9_]*\z/
    # Field options the compiler reproduces. A field with any other option (default, default_if, datetime_format, or one
    # added later) uses standard rendering, so an option the compiler has not learned is never skipped.
    COMPILABLE_OPTIONS = %i[block name extractor if unless exclude_if_nil association blueprint view options].freeze

    module_function

    # The blueprint and view only name the generated code, so a backtrace from it says which view failed.
    # @return [Module] responds to `call(object, options)` and returns the object's Hash
    def compile(fields:, transformers:, blueprint:, view:)
      refs = []
      ref = ->(value) { "REFS[#{refs.push(value).size - 1}]" }
      body = body(fields:, transformers:, ref:)
      source = <<~RUBY
        def self.call(object, options)  # def self.call(object, options)
          #{body}                       #   { id: object.id, name: object.name }
        end                             # end
      RUBY

      Module.new.tap do |compiled|
        compiled.const_set(:REFS, refs.freeze)
        compiled.module_eval(source, "(blueprinter compiled #{blueprint} #{view})", 1)
      end
    end

    def body(fields:, transformers:, ref:)
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
      return nil unless (options.keys - COMPILABLE_OPTIONS).empty?
      return association_value(field, ref) if options[:association]
      return nil unless field.extractor.instance_of?(AutoExtractor)

      read(field, ref)
    end

    # Same as AssociationExtractor#extract, for associations with a static blueprint and no :options: the value goes
    # through the associated Blueprint's #hashify, which renders it with that Blueprint's compiled view. nil stays nil,
    # because association_default is unset (see Configuration#views_compilable?).
    def association_value(field, ref)
      extractor = field.extractor
      blueprint = field.options[:blueprint]
      view = field.options[:view] || :default
      return nil unless extractor.instance_of?(AssociationExtractor) &&
                        extractor.extractor.instance_of?(AutoExtractor) &&
                        blueprint.is_a?(Class) && field.options[:options].nil? && blueprint.view?(view)

      "((a = #{read(field, ref)}).nil? ? nil : " \
        "#{ref.call(blueprint)}.hashify(a, view_name: #{ref.call(view)}, local_options: options))"
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
      parts << "#{ref.call(field.if_callable)}.call(#{key}, object, options)" if field.options[:if]
      parts << "!#{ref.call(field.unless_callable)}.call(#{key}, object, options)" if field.options[:unless]
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
