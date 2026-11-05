# frozen_string_literal: true

module Blueprinter
  #
  # Stores and runs Blueprinter extensions. An extension is any object that implements one or more of the
  # extension methods:
  #
  # The Render Extension intercepts an object before rendering begins. The return value from this
  # method is what is ultimately rendered.
  #
  #   def pre_render(object, blueprint, view, options)
  #     # returns original, modified, or new object
  #   end
  #
  class Extensions
    def initialize(extensions = [])
      @extensions = extensions
    end

    def to_a
      @extensions.dup
    end

    # Appends an extension
    def <<(ext)
      @extensions << ext
      self
    end

    # Runs the object through all Render Extensions and returns the final result
    def pre_render(object, blueprint, view, options = {})
      @extensions.reduce(object) do |acc, ext|
        ext.pre_render(acc, blueprint, view, options)
      end
    end
  end
end
