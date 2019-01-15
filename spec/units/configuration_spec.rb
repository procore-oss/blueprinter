require 'oj'
require 'yajl'

describe '::Configuration' do
  describe '#generator' do
    before { Blueprinter.configure { |config| config.generator = JSON } }
    after { Blueprinter.configure { |config|
      config.generator = JSON
      config.if = nil
      config.method = :generate
      config.sort_fields_by = :name_asc
      config.unless = nil
    } }

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
end
