# frozen_string_literal: true

require 'oj'
require 'yajl'

describe 'Blueprinter::Configuration' do
  describe '#configure' do
    before { Blueprinter.configure { |config| config.generator = JSON } }
    after { reset_blueprinter_config! }

    let(:extractor) do
      class FoodDehydrator < Blueprinter::AutoExtractor; end
    end
    let(:transform) do
      class UpcaseTransform < Blueprinter::Transformer; end
    end

    it 'should set the `generator`' do
      Blueprinter.configure { |config| config.generator = Oj }
      expect(Blueprinter.configuration.generator).to be(Oj)
    end

    it 'should set the `generator` and `method`' do
      Blueprinter.configure { |config|
        config.generator = Yajl::Encoder
        config.method = :encode
      }
      expect(Blueprinter.configuration.generator).to be(Yajl::Encoder)
      expect(Blueprinter.configuration.method).to be(:encode)
    end

    it 'should set the `sort_fields_by`' do
      Blueprinter.configure { |config|
        config.sort_fields_by = :definition
      }
      expect(Blueprinter.configuration.sort_fields_by).to be(:definition)
    end

    it 'should set the `if` option' do
      if_lambda = -> _field_name, obj, options { true }
      Blueprinter.configure { |config|
        config.if = if_lambda
      }
      expect(Blueprinter.configuration.if).to be(if_lambda)
    end

    it 'should set the `unless` option' do
      unless_lambda = -> _field_name, obj, options { false }
      Blueprinter.configure { |config|
        config.unless = unless_lambda
      }
      expect(Blueprinter.configuration.unless).to be(unless_lambda)
    end

    it 'should set the `field_default` option' do
      Blueprinter.configure { |config| config.field_default = "N/A" }
      expect(Blueprinter.configuration.field_default).to eq("N/A")
    end

    it 'should set the `deprecations` option' do
      Blueprinter.configure { |config| config.deprecations = :silence }
      expect(Blueprinter.configuration.deprecations).to eq(:silence)
    end

    it 'should set the `association_default` option' do
      Blueprinter.configure { |config| config.association_default = {} }
      expect(Blueprinter.configuration.association_default).to eq({})
    end

    it 'should set the `datetime_format` option' do
      Blueprinter.configure { |config| config.datetime_format = "%m/%d/%Y" }
      expect(Blueprinter.configuration.datetime_format).to eq("%m/%d/%Y")
    end

    it 'should set the `extractor_default` option' do
      Blueprinter.configure { |config| config.extractor_default = extractor }
      expect(Blueprinter.configuration.extractor_default).to eq(extractor)
    end

    it 'should default the `extractor_default` option' do
      Blueprinter.reset_configuration!
      expect(Blueprinter.configuration.extractor_default).to eq(Blueprinter::AutoExtractor)
    end

    it 'should set the `default_transformers` option' do
      Blueprinter.configure { |config| config.default_transformers = [transform] }
      expect(Blueprinter.configuration.default_transformers).to eq([transform])
    end
  end

  describe '#default_extractor' do
    it 'returns an instance of the default extractor' do
      expect(Blueprinter.configuration.default_extractor).to be_an_instance_of(Blueprinter::AutoExtractor)
    end

    it 'does not create a new instance on subsequent calls' do
      expect(Blueprinter.configuration.default_extractor).to eq(Blueprinter.configuration.default_extractor)
    end
  end
  describe '#valid_callable?' do
    it 'should return true for valid callables' do
      [:if, :unless].each do |option|
        actual = Blueprinter.configuration.valid_callable?(option)
        expect(actual).to be(true)
      end
    end

    it 'should return false for invalid callable' do
      actual = Blueprinter.configuration.valid_callable?(:invalid_option)
      expect(actual).to be(false)
    end
  end

  describe '#views_compilable?' do
    after { reset_blueprinter_config! }

    it 'is true when compile_views is on and no unsupported global setting is set' do
      Blueprinter.configure { |config| config.compile_views = true }

      expect(Blueprinter.configuration.views_compilable?).to be(true)
    end

    it 'is false when compile_views is off' do
      Blueprinter.configure { |config| config.compile_views = false }

      expect(Blueprinter.configuration.views_compilable?).to be_falsey
    end

    {
      datetime_format: '%Y-%m-%d',
      field_default: 'N/A',
      association_default: {},
      if: ->(_field_name, _object, _options) { true },
      unless: ->(_field_name, _object, _options) { false }
    }.each do |setting, value|
      it "is false when the global #{setting} is set" do
        Blueprinter.configure do |config|
          config.compile_views = true
          config.public_send(:"#{setting}=", value)
        end

        expect(Blueprinter.configuration.views_compilable?).to be(false)
      end
    end
  end
end
