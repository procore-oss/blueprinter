require 'oj'
require 'yajl'

describe 'Blueprinter' do
  describe '#configure' do
    before { Blueprinter.configure { |config| config.generator = JSON } }
    after { Blueprinter.reset_configuration! }

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
      if_lambda = -> obj, options { true }
      Blueprinter.configure { |config|
        config.if = if_lambda
      }
      expect(Blueprinter.configuration.if).to be(if_lambda)
    end

    it 'should set the `unless` option' do
      unless_lambda = -> obj, options { false }
      Blueprinter.configure { |config|
        config.unless = unless_lambda
      }
      expect(Blueprinter.configuration.unless).to be(unless_lambda)
    end
  end

  describe '#reset_configuration!' do
    before { Blueprinter.configure do |config|
        config.generator = Oj
        config.if = :foo_method
        config.method = :foobar_generate
        config.sort_fields_by = :name_desc
        config.unless = :bar_method
      end
    }
    after { Blueprinter.reset_configuration! }

    it 'should set the configuration options to default values' do
      expected_defaults = {
        generator: JSON,
        if: nil,
        method: :generate,
        sort_fields_by: :name_asc,
        unless: nil,
      }
      Blueprinter.reset_configuration!

      expected_defaults.keys.each do |option|
        actual = Blueprinter.configuration.public_send(option)
        expect(actual).to be(expected_defaults[option])
      end
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
