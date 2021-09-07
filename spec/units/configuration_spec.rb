require 'oj'
require 'yajl'

describe 'Blueprinter' do
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
      expect(Blueprinter.configuration.extractor_default).to eq(Blueprinter::AutoExtractor)
    end

    it 'should set the `default_transformers` option' do
      Blueprinter.configure { |config| config.default_transformers = [transform] }
      expect(Blueprinter.configuration.default_transformers).to eq([transform])
    end
  end

  describe "::Configuration" do
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
  end
end
