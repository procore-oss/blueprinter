# frozen_string_literal: true

module Blueprinter
  module V2
    Field = Struct.new(
      :name,
      :from,
      :from_str,
      :value_proc,
      :options,
      keyword_init: true
    )

    ObjectField = Struct.new(
      :name,
      :blueprint,
      :from,
      :from_str,
      :value_proc,
      :options,
      keyword_init: true
    )

    Collection = Struct.new(
      :name,
      :blueprint,
      :from,
      :from_str,
      :value_proc,
      :options,
      keyword_init: true
    )

    #
    # The Context struct is used for most extension hooks, all extractor methods, and field blocks.
    # Some fields are always present, others are context-dependant. Each hook and extractor
    # method will separately document which fields to expect and any special meanings.
    #
    # blueprint = Instance of the current Blueprint class (always)
    # field = Field | ObjectField | Collection (optional)
    # value = The current value of `field` or the Blueprint output (optional)
    # object = The object currently being evaluated (e.g. passed to `render` or from an association) (optional)
    # options = Options passed to `render` (always)
    # instances = An InstanceCache instance for sharing instances of Blueprints and Extractors during a render (always)
    # store = A Hash to for extensions, etc to cache render data in (always)
    #
    Context = Struct.new(:blueprint, :field, :value, :object, :options, :instances, :store)
  end
end
