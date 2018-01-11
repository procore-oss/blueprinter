require 'oj'

describe '::Configuration' do
  describe '#generator' do
    before { Blueprinter.configure { |config| config.generator = JSON } }
    after { Blueprinter.configure { |config| config.generator = JSON } }

    it 'should set the generator' do
      Blueprinter.configure { |config| config.generator = Oj }
      expect(Blueprinter.configuration.generator).to be(Oj)
    end
  end
end
