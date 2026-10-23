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
end
