# frozen_string_literal: true

# Required explicitly so this file is runnable on its own. `require 'blueprinter'` only autoloads
# Base, so Field/AutoExtractor otherwise resolve just by load-order luck from the full suite.
require 'blueprinter/base'
require 'blueprinter/field'
require 'blueprinter/extractors/auto_extractor'

describe '::Field' do
  let(:blueprint) { Class.new(Blueprinter::Base) }
  let(:extractor) { Blueprinter::AutoExtractor.new }
  let(:object) { Struct.new(:first_name).new('Meg') }

  def field(options = {})
    Blueprinter::Field.new(:first_name, :first_name, extractor, blueprint, options)
  end

  describe '#compile' do
    it 'does not resolve an :if symbol' do
      subject = field(if: :missing_predicate)
      expect(blueprint).not_to receive(:method)

      subject.compile
    end

    # The fast path re-implements AutoExtractor's Hash-vs-public_send dispatch inline. This guards
    # against the two drifting: for a plain field, the compiled closure must write exactly what the
    # full extractor path would have produced, for both Hash and object inputs.
    context 'when the field qualifies for the fast path' do
      it 'produces the same value as the full extractor path' do
        [Struct.new(:first_name).new('Meg'), { first_name: 'Meg' }, { first_name: nil }, {}].each do |input|
          subject = field
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
        subject = field(if: nil)

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
        subject = field(if: ->(_name, _object, _opts) { false })

        compiled_result = {}
        subject.compile.call(compiled_result, object, {})

        expect(compiled_result).to eq({})
      end

      it 'does not resolve :unless when :if skips the field' do
        subject = field(if: ->(_name, _object, _opts) { false }, unless: :missing_predicate)
        expect(blueprint).not_to receive(:method)

        compiled_result = {}
        subject.compile.call(compiled_result, object, {})

        expect(compiled_result).to eq({})
      end
    end

    context 'when the field has exclude_if_nil' do
      it 'drops a nil value and keeps a present one' do
        subject = field(exclude_if_nil: true)

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
