require 'oj'
require 'yajl'

describe '::Configuration' do
  describe '#generator' do
    before { Blueprinter.configure { |config| config.generator = JSON } }
    after { Blueprinter.configure { |config| 
      config.generator = JSON
      config.method = :generate
      config.sort_by_definition = false
    } }

    it 'should set the generator' do
      Blueprinter.configure { |config| config.generator = Oj }
      expect(Blueprinter.configuration.generator).to be(Oj)
    end

    it 'should set the generator and method' do
      Blueprinter.configure { |config| 
        config.generator = Yajl::Encoder
        config.method = :encode
      }
      expect(Blueprinter.configuration.generator).to be(Yajl::Encoder)
      expect(Blueprinter.configuration.method).to be(:encode)
    end

    it 'should set the sort_by_definition' do
      Blueprinter.configure { |config| 
        config.sort_by_definition = true
      }
      expect(Blueprinter.configuration.sort_by_definition).to be(true)
    end
  end
end
