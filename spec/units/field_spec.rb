# frozen_string_literal: true

# Required explicitly so this file is runnable on its own. `require 'blueprinter'` only autoloads
# Base, so Field/AutoExtractor otherwise resolve just by load-order luck from the full suite.
require 'blueprinter/base'
require 'blueprinter/field'
require 'blueprinter/extractors/auto_extractor'

describe '::Field' do
  subject(:field) { Blueprinter::Field.new(:first_name, :first_name, extractor, blueprint, options) }

  let(:options) { {} }
  let(:blueprint) { Class.new(Blueprinter::Base) }
  let(:extractor) { Blueprinter::AutoExtractor.new }
  let(:object) { Struct.new(:first_name).new('Meg') }

  describe '#skip?' do
    context 'when no :if/:unless is configured' do
      it 'does not skip the field' do
        expect(field.skip?(:first_name, object, {})).to be_falsey
      end

      # Regression guard. `callable_from` returns `false` in this (very common) case, so the previous
      # `@_if_callable ||= callable_from(:if)` memoization never took hold and re-resolved the
      # callable -- including a global config lookup -- on every field of every rendered object.
      it 'does not read global configuration again after the first call' do
        field.skip?(:first_name, object, {})

        # Any further global reads would mean resolution is still happening per call.
        expect(Blueprinter).not_to receive(:configuration)
        field.skip?(:first_name, object, {})
      end
    end

    context 'with a field-level :if proc returning false' do
      let(:options) { { if: ->(_name, _object, _opts) { false } } }

      it 'skips the field' do
        expect(field.skip?(:first_name, object, {})).to be(true)
      end
    end

    context 'with a field-level :if proc returning true' do
      let(:options) { { if: ->(_name, _object, _opts) { true } } }

      it 'does not skip the field' do
        expect(field.skip?(:first_name, object, {})).to be_falsey
      end
    end

    context 'with a field-level :if proc recording its calls' do
      let(:seen) { [] }
      let(:options) { { if: ->(name, obj, opts) { seen << [name, obj, opts] and true } } }

      it 'passes the field name, object and options through on every call' do
        field.skip?(:first_name, object, { foo: :bar })
        field.skip?(:first_name, object, { foo: :baz })

        expect(seen).to eq([[:first_name, object, { foo: :bar }], [:first_name, object, { foo: :baz }]])
      end

      it 'calls the condition on every skip? invocation' do
        3.times { field.skip?(:first_name, object, {}) }

        expect(seen.size).to eq(3)
      end
    end

    context 'with a field-level :unless proc returning true' do
      let(:options) { { unless: ->(_name, _object, _opts) { true } } }

      it 'skips the field' do
        expect(field.skip?(:first_name, object, {})).to be(true)
      end
    end

    context 'with a field-level :unless proc returning false' do
      let(:options) { { unless: ->(_name, _object, _opts) { false } } }

      it 'does not skip the field' do
        expect(field.skip?(:first_name, object, {})).to be_falsey
      end
    end

    context 'with a symbol referring to a blueprint method' do
      let(:options) { { if: :render_it? } }
      let(:blueprint) do
        Class.new(Blueprinter::Base) do
          def self.render_it?(_name, _object, _opts) = false
        end
      end

      it 'resolves the symbol against the blueprint and skips accordingly' do
        expect(field.skip?(:first_name, object, {})).to be(true)
      end

      it 'resolves the symbol only once across repeated calls' do
        expect(blueprint).to receive(:method).with(:render_it?).once.and_call_original

        3.times { field.skip?(:first_name, object, {}) }
      end
    end

    context 'with an invalid condition type' do
      let(:options) { { if: 'a string' } }

      it 'raises ArgumentError' do
        expect { field.skip?(:first_name, object, {}) }
          .to raise_error(ArgumentError, /String is passed to :if/)
      end
    end

    context 'with global configuration' do
      after { reset_blueprinter_config! }

      it 'honours a global :if set before first use' do
        Blueprinter.configure { |config| config.if = ->(_name, _object, _opts) { false } }
        expect(field.skip?(:first_name, object, {})).to be(true)
      end

      it 'honours a global :unless set before first use' do
        Blueprinter.configure { |config| config.unless = ->(_name, _object, _opts) { true } }
        expect(field.skip?(:first_name, object, {})).to be(true)
      end

      # Documents the deliberate trade-off of memoizing: conditions are snapshotted per field on
      # first use, so global config must be set before rendering. Consistent with
      # `config.sort_fields_by`, which ViewCollection snapshots at construction.
      it 'snapshots the global condition on first use' do
        expect(field.skip?(:first_name, object, {})).to be_falsey

        Blueprinter.configure { |config| config.if = ->(_name, _object, _opts) { false } }

        expect(field.skip?(:first_name, object, {})).to be_falsey
      end

      context 'with a field-level condition' do
        let(:options) { { if: ->(_name, _object, _opts) { true } } }

        it 'prefers it over the global one' do
          Blueprinter.configure { |config| config.if = ->(_name, _object, _opts) { false } }

          expect(field.skip?(:first_name, object, {})).to be_falsey
        end
      end
    end
  end

  def build_field(options = {})
    Blueprinter::Field.new(:first_name, :first_name, extractor, blueprint, options)
  end

  describe '#compile' do
    it 'does not resolve an :if symbol' do
      subject = build_field(if: :missing_predicate)
      expect(blueprint).not_to receive(:method)

      subject.compile
    end

    # The fast path re-implements AutoExtractor's Hash-vs-public_send dispatch inline. This guards
    # against the two drifting: for a plain field, the compiled closure must write exactly what the
    # full extractor path would have produced, for both Hash and object inputs.
    context 'when the field qualifies for the fast path' do
      it 'produces the same value as the full extractor path' do
        [Struct.new(:first_name).new('Meg'), { first_name: 'Meg' }, { first_name: nil }, {}].each do |input|
          subject = build_field
          compiled_result = {}
          subject.compile.call(compiled_result, input, {})

          expected = subject.extract(input, {})

          expect(compiled_result).to eq(first_name: expected)
        end
      end

      # The fast-path decision (condition_configured?) and the runtime decision (callable_from)
      # are two predicates over the same inputs. A field-level `if: nil` with a global `if` set is
      # the case where they are most likely to drift: both must treat the field as unconditional.
      it 'agrees with skip? that a field-level nil condition overrides a global one' do
        Blueprinter.configure { |config| config.if = ->(_name, _object, _opts) { false } }
        subject = build_field(if: nil)

        compiled_result = {}
        subject.compile.call(compiled_result, object, {})

        expect(subject.skip?(:first_name, object, {})).to be_falsey
        expect(compiled_result).to eq(first_name: 'Meg')
      ensure
        reset_blueprinter_config!
      end
    end

    context 'when the field has a condition' do
      it 'keeps the extractor path and honours the condition' do
        subject = build_field(if: ->(_name, _object, _opts) { false })

        compiled_result = {}
        subject.compile.call(compiled_result, object, {})

        expect(compiled_result).to eq({})
      end

      it 'does not resolve :unless when :if skips the field' do
        subject = build_field(if: ->(_name, _object, _opts) { false }, unless: :missing_predicate)
        expect(blueprint).not_to receive(:method)

        compiled_result = {}
        subject.compile.call(compiled_result, object, {})

        expect(compiled_result).to eq({})
      end
    end

    context 'when the field has exclude_if_nil' do
      it 'drops a nil value and keeps a present one' do
        subject = build_field(exclude_if_nil: true)

        present = {}
        subject.compile.call(present, object, {})
        missing = {}
        subject.compile.call(missing, { first_name: nil }, {})

        expect(present).to eq(first_name: 'Meg')
        expect(missing).to eq({})
      end
    end
  end
end
