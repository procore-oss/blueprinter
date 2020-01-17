require 'generator_helper'

require 'generators/blueprinter/initializer_generator'

RSpec.describe Blueprinter::Generators::InitializerGenerator, :type => :generator do
  include_context "generator_destination"

  it 'runs at all' do
    gen = generator
    expect(gen).to receive :ensure_initializer_dir
    expect(gen).to receive :create_initializer
    gen.invoke_all
  end

  include_context "initializer_subject" do
    describe 'generates a default initializer' do
      include_examples "generated_file"
      before do
        run_generator
      end

      it "file" do
        is_expected.to exist
      end

      it "block declaration" do
        is_expected.to contain(/Blueprinter.configure do |config|/)
      end

    end

    describe 'let user pick Oj gem' do
      include_examples "generated_file"
      before do
        run_generator  %w(--generator=oj)
      end

      it "file" do
        is_expected.to exist
      end

      it "generator declaration" do
        is_expected.to contain(/config.generator = Oj/)
      end
    end

    describe 'let user pick Yajl gem' do
      include_examples "generated_file"
      before do
        run_generator  %w(--generator=yajl)
      end

      it "generator declaration" do
        is_expected.to contain(/config.generator = Yajl::Encoder/)
      end
    end


    describe 'let user pick Yajl gem with :encode generator method' do
      include_examples "generated_file"
      before do
        run_generator  %w(--generator=yajl --method=encode)
      end

      it "method declaration" do
        is_expected.to contain(/config.method = :encode/)
        is_expected.not_to contain(/#  config.method = :encode/)
      end
    end

    describe 'field_default empty string' do
      include_examples "generated_file"
      before do
        run_generator  %w(--field_default= )
      end

      it "method declaration" do
        is_expected.to contain(/config.field_default = ""/)
      end
    end

    describe 'field_default explicit nil' do
      include_examples "generated_file"
      before do
        run_generator  %w(--field_default=)
      end

      it "method declaration" do
        is_expected.to contain(/config.field_default = ""/)
      end
    end

    describe 'field_default n/a' do
      include_examples "generated_file"
      before do
        run_generator  %w(--field_default=N/A)
      end

      it "method declaration" do
        is_expected.to contain(/config.field_default = "N\/A"/)
      end
    end

    describe 'association_default {}' do
      before do
        run_generator  %w(--association_default={})
      end

      it "method declaration" do
        is_expected.to contain(/config.association_default = {}/)
        is_expected.not_to contain(/#  config.association_default = {}/)
      end
    end

    describe 'sort_fields_by' do
      include_examples "generated_file"
      before do
        run_generator  %w(--sort_fields_by=definition)
      end

      it "method declaration" do
        is_expected.to contain(/config.sort_fields_by = :definition/)
        is_expected.not_to contain(/#  config.sort_fields_by = :definition/)
      end
    end

    describe 'whole enchilada' do
      include_examples "generated_file"
      before do
        run_generator  %w(--generator=yajl --method=encode --field_default=N/A --association_default={} --sort_fields_by=definition)
      end
    end
  end

  describe 'generates a different path / filename' do
    include_examples "generated_file"
    before do
      run_generator %w(--initializer-dir=somewhere/interesting --name=blooprinter.rb)
    end

    subject { file('somewhere/interesting/blooprinter.rb') }

    it "file" do
      is_expected.to exist
    end
  end

end
