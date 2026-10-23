# frozen_string_literal: true

require 'blueprinter/view'

module Blueprinter
  # @api private
  #
  # ViewCollection manages the views defined in a Blueprint, along with their fields and transformers.
  #
  # To improve performance, the "structure" of each view is cached. Once the first view is accessed, we prewarm the
  # cache for _all_ views (while this isn't the _most_ optimal approach, the overhead is negligible, and allows the
  # caching logic to be quite simple).
  #
  # Thread Safety: view data is lazily compiled into a frozen snapshot on first access and published by one reference
  # assignment. The snapshot includes the configuration generation it was built for, so a reader cannot pair a new
  # generation with an older field list. A mutex serializes compilation. A generation change during compilation
  # discards that snapshot and compiles again. After publication, reads take no lock.
  #
  # Future optimization: a public compile! method could allow eager compilation at boot time
  # (e.g. in a Rails after_initialize hook) to move the first-render compilation cost (~10µs per
  # blueprint) out of the request path entirely.
  class ViewCollection
    attr_reader :views, :sort_by_definition

    def initialize
      @views = {
        identifier: View.new(:identifier),
        default: View.new(:default)
      }
      # Fixed at creation. sort_fields_by is not part of the generation counter: definition order is recorded only
      # while views are created with :definition, so a later write cannot rebuild this collection correctly.
      @sort_by_definition = Blueprinter.configuration.sort_fields_by.eql?(:definition)
      @cache_mutex = Mutex.new
      @cache = nil
    end

    def inherit(view_collection)
      view_collection.views.each do |view_name, view|
        self[view_name].inherit(view)
      end

      invalidate_cache!
    end

    # Clears the compiled field/transformer cache. This should be called after any mutation to a view's fields,
    # exclusions, or transformers to ensure the cache reflects the current state.
    def invalidate_cache!
      @cache = nil
    end

    # @param [String] view_name
    # @return [Boolean] true if the view exists, false otherwise
    def view?(view_name)
      views.key? view_name
    end

    # Returns an array of Field objects for the provided View.
    # @param [String] view_name
    # @return [Array<Field>]
    def fields_for(view_name)
      ensure_cached![:fields][view_name]
    end

    # Returns the compiled fields and transformers for a view from the same cache snapshot.
    # Rendering must use this instead of separate lookups so a configuration change cannot pair
    # compiled fields from one generation with transformers from another.
    #
    # Each compiled field is a closure from Field#compile that captures the field's per-field
    # decisions (extractor, datetime formatting, defaults, :if/:unless) resolved once at compile
    # time, so the render loop just calls each with (result_hash, object, local_options).
    # @param [String] view_name
    # @return [Array<(Array<Proc>, Array<Transformer>)>]
    def render_pipeline(view_name)
      ensure_cached![:pipelines][view_name]
    end

    # Returns an array of Transformer objects for the provided View.
    # @param [String] view_name
    # @return [Array<Transformer>]
    def transformers(view_name)
      ensure_cached![:transformers][view_name]
    end

    # @param [String] view_name
    # @return [View]
    def [](view_name)
      return @views[view_name] if @views.key?(view_name)

      @cache_mutex.synchronize do
        unless @views.key?(view_name)
          @views[view_name] = View.new(view_name)
          invalidate_cache!
        end
        @views[view_name]
      end
    end

    private

    def identifier_fields
      views[:identifier].fields.values
    end

    # Fast path: one reference read, then an integer comparison against the generation stored in that
    # snapshot. Global config baked into the closures (datetime_format, field_default, :if/:unless)
    # bumps Configuration.generation, which fails this check and forces a rebuild.
    def ensure_cached!
      snapshot = @cache
      return snapshot if current?(snapshot)

      @cache_mutex.synchronize { compile_snapshot }
    end

    def current?(snapshot)
      snapshot && snapshot[:generation] == Blueprinter::Configuration.generation
    end

    def compile_snapshot
      loop do
        snapshot = @cache
        return snapshot if current?(snapshot)

        generation = Blueprinter::Configuration.generation
        built = build_snapshot(generation)
        # A writer bumped the generation while the closures were being built. Those closures may
        # mix the old and new configuration, so discard them and compile against the new value.
        next if Blueprinter::Configuration.generation != generation

        @cache = built
        return built
      end
    end

    def build_snapshot(generation)
      fields = {}
      transformers = {}
      pipelines = {}

      views.each_key do |view_name|
        view_fields = build_fields_for(view_name).freeze
        view_transformers = build_transformers(view_name).freeze
        fields[view_name] = view_fields
        transformers[view_name] = view_transformers
        pipelines[view_name] = [view_fields.map(&:compile).freeze, view_transformers].freeze
      end

      {
        fields: fields.freeze,
        transformers: transformers.freeze,
        pipelines: pipelines.freeze,
        generation: generation
      }.freeze
    end

    def build_fields_for(view_name)
      return identifier_fields if view_name == :identifier

      fields, excluded_fields = sortable_fields(view_name)
      sorted_fields = sort_by_definition ? sort_by_def(view_name, fields) : fields.values.sort_by(&:name)

      (identifier_fields + sorted_fields).tap do |fields_array|
        fields_array.reject! { |field| excluded_fields.include?(field.name) }
      end
    end

    def build_transformers(view_name)
      included_transformers = gather_transformers_from_included_views(view_name).reverse
      all_transformers = [*views[:default].view_transformers, *included_transformers].uniq
      all_transformers.empty? ? Blueprinter.configuration.default_transformers : all_transformers
    end

    # @param [String] view_name
    # @return [Array<(Hash, Hash<String, NilClass>)>] fields, excluded_fields
    def sortable_fields(view_name)
      excluded_fields = {}
      fields = views[:default].fields.clone
      views[view_name].included_view_names.each do |included_view_name|
        next if view_name == included_view_name

        view_fields, view_excluded_fields = sortable_fields(included_view_name)
        fields.merge!(view_fields)
        excluded_fields.merge!(view_excluded_fields)
      end
      fields.merge!(views[view_name].fields) unless view_name == :default

      views[view_name].excluded_field_names.each { |name| excluded_fields[name] = nil }

      [fields, excluded_fields]
    end

    # select and order members of fields according to traversal of the definition_orders
    def sort_by_def(view_name, fields)
      ordered_fields = {}
      views[:default].definition_order.each do |definition|
        add_to_ordered_fields(ordered_fields, definition, fields, view_name)
      end
      ordered_fields.values
    end

    # view_name_filter allows to follow definition order all the way down starting from the view_name given to sort_by_def()
    # but include no others at the top-level
    def add_to_ordered_fields(ordered_fields, definition, fields, view_name_filter = nil)
      if definition.view?
        if view_name_filter.nil? || view_name_filter == definition.name
          views[definition.name].definition_order.each do |defined|
            add_to_ordered_fields(ordered_fields, defined, fields)
          end
        end
      else
        ordered_fields[definition.name] = fields[definition.name]
      end
    end

    def gather_transformers_from_included_views(view_name)
      current_view = views[view_name]
      already_included_transformers = current_view.included_view_names.flat_map do |included_view_name|
        next [] if view_name == included_view_name

        gather_transformers_from_included_views(included_view_name)
      end
      [*already_included_transformers, *current_view.view_transformers].uniq
    end
  end
end
