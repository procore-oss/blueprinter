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

  # The generation counter is what makes compiled/memoized state (Field conditions, ViewCollection
  # caches) safe: anything that mutates a configuration value those caches depend on bumps it, so a
  # later render re-resolves instead of serving behaviour derived from the old configuration.
  describe '.generation' do
    after { reset_blueprinter_config! }

    Blueprinter::Configuration::COMPILED_ATTRIBUTES.each do |attribute|
      it "bumps when the compiled attribute ##{attribute} is written" do
        expect { Blueprinter.configuration.public_send(:"#{attribute}=", nil) }
          .to change(Blueprinter::Configuration, :generation).by(1)
      end
    end

    Blueprinter::Configuration::LIVE_ATTRIBUTES.each do |attribute|
      it "does not bump when the live attribute ##{attribute} is written" do
        expect { Blueprinter.configuration.public_send(:"#{attribute}=", nil) }
          .not_to change(Blueprinter::Configuration, :generation)
      end
    end

    # Both are read when a blueprint is defined. A bump would rebuild the cache without applying
    # the new value: definition order is already recorded, and existing fields keep their extractor.
    it 'does not bump when sort_fields_by is written' do
      expect { Blueprinter.configuration.sort_fields_by = :definition }
        .not_to change(Blueprinter::Configuration, :generation)
    end

    it 'does not bump when the default extractor is changed' do
      extractor = Class.new(Blueprinter::AutoExtractor)
      expect { Blueprinter.configuration.extractor_default = extractor }
        .not_to change(Blueprinter::Configuration, :generation)
    end

    # Nothing compiled depends on it; the writer only has to clear the array_like_classes memo.
    it 'does not bump when custom_array_like_classes is written, but refreshes array_like_classes' do
      expect(Blueprinter.configuration.array_like_classes).not_to include(Set)

      expect { Blueprinter.configuration.custom_array_like_classes = [Set] }
        .not_to change(Blueprinter::Configuration, :generation)

      expect(Blueprinter.configuration.array_like_classes).to include(Set)
    end

    # reset_configuration! installs a brand new Configuration whose defaults differ from whatever
    # was in effect, so it must invalidate compiled caches too.
    it 'bumps on reset_configuration!' do
      expect { Blueprinter.reset_configuration! }
        .to change(Blueprinter::Configuration, :generation).by(1)
    end
  end
end
