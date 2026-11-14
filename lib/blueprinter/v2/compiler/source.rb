# frozen_string_literal: true

module Blueprinter
  module V2
    class Compiler
      #
      # Builds Ruby source a line at a time, keeping track of indentation.
      #
      # This exists so the field compilers can say *what* to emit without juggling newlines, indentation, or
      # `end` keywords. It knows nothing about Blueprints.
      #
      # @!visibility private
      class Source
        def initialize
          @lines = []
          @depth = 0
        end

        # Emits one statement
        def line(text)
          @lines << (('  ' * @depth) + text)
          self
        end

        # Emits `target = expr`
        def assign(target, expr)
          line "#{target} = #{expr}"
        end

        # Emits `header`, the block's output indented one level, then `end`
        #
        #   open('if foo') { line 'bar' }  #=>  if foo
        #                                         bar
        #                                       end
        def open(header)
          line header
          @depth += 1
          yield
          @depth -= 1
          line 'end'
        end

        # Emits `if condition ... end`. A nil condition emits the body on its own, with no `if` at all, which
        # lets callers write `if_(maybe_nil) { ... }` instead of branching.
        def if_(condition, &)
          condition ? open("if #{condition}", &) : yield
        end

        # Emits `unless condition ... end`. A nil condition behaves like {#if_}.
        def unless_(condition, &)
          condition ? open("unless #{condition}", &) : yield
        end

        def to_s = "#{@lines.join("\n")}\n"
      end
    end
  end
end
