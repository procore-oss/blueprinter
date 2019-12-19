require 'generator_helper'

require 'generators/blueprinter/blueprint_generator'

RSpec.describe Blueprinter::Generators::BlueprintGenerator, :type => :generator do
  include_context "generator_destination"

  it 'runs at all' do
    gen = generator %w(:vehicle)
    expect(gen).to receive :ensure_blueprint_dir
    expect(gen).to receive :create_blueprint
    gen.invoke_all
  end

  include_context "vehicle_subject" do
    describe 'generates an empty blueprint' do
      include_examples "generated_file"
      before do
        run_generator %W(#{model})
      end

      it "file" do
        is_expected.to exist
      end

      it "class declaration" do
        is_expected.to contain(/class VehicleBlueprint/)
      end
    end

    describe "given -d" do
      include_examples "generated_file"
      before do
        run_generator %W(#{model} -d wherevs)
      end

      subject { file('wherevs/vehicle_blueprint.rb') }

      it "file is created where we say" do
        is_expected.to exist
      end
    end

    describe "given -i" do
      include_examples "generated_file"
      before do
        run_generator %W(#{model} -i)
      end

      it "blueprint file has identifier" do
        is_expected.to contain(/identifier :id/)
      end
    end

    describe "given -i customid" do
      include_examples "generated_file"
      before do
        run_generator %W(#{model} -i customid)
      end

      it "blueprint file has customid" do
        is_expected.to contain(/customid/)
      end
    end

    describe "given --fields=yoohoo hi_there" do
      include_examples "generated_file"
      before do
        run_generator %W(#{model} --fields=yoohoo hi_there)
      end

      it "blueprint file has manual fields" do
        is_expected.to contain(/fields :yoohoo, :hi_there/)
      end
    end

    describe "given --detect_fields" do
      include_examples "generated_file"
      before do
        run_generator %W(#{model} --detect_fields)
      end

      it "blueprint file has detected fields" do
        is_expected.to contain(/:make, :model, :miles/)
      end
    end

    describe "given --detect_fields --fields=mooo" do
      include_examples "generated_file"
      before do
        run_generator %W(#{model} --detect_fields  --fields=mooo)
      end

      it "blueprint file has detected fields and manual field" do
        is_expected.to contain(/:make, :model, :miles/)
        is_expected.to contain(/:mooo/)
      end
    end

    describe "given --detect_fields --fields=make model moooo" do
      include_examples "generated_file"
      before do
        run_generator %W(#{model} --detect_fields  --fields=make model moooo)
      end

      it "blueprint file has deduped detected fields and manual fields" do
        File.open(subject) do |f|
          generated = f.read
          expect(generated.scan('make').size).to eq(1)
          expect(generated.scan('model').size).to eq(1)
        end
        is_expected.to contain(/:mooo/)
      end
    end

    describe "given -a=not_really" do
      include_examples "generated_file"
      before do
        run_generator %W(#{model} -a=not_really)
      end

      it "blueprint file has manual association" do
        is_expected.to contain(/association :not_really/)
        is_expected.to contain(/blueprint: NotReallyBlueprint/)
      end
    end

    describe "given -a=user" do
      include_examples "generated_file"
      before do
        run_generator %W(#{model} -a=user)
      end

      it "blueprint file has manual association" do
        is_expected.to contain(/association :user/)
        is_expected.to contain(/blueprint: UserBlueprint/)
      end
    end

    describe "given --detect_associations" do
      include_examples "generated_file"
      before do
        run_generator %W(#{model} --detect_associations)
      end

      it "blueprint file has detected association" do
        is_expected.to contain(/association :user/)
        is_expected.to contain(/blueprint: UserBlueprint/)
      end
    end

    describe "given --detect_associations --detect_fields --indentation=tab" do
      include_examples "generated_file"
      before do
        run_generator %W(#{model} --detect_associations --detect_fields --indentation=tab)
      end

      it "blueprint file has tab indent" do
        is_expected.to contain(/\tfields/)
        is_expected.to contain(/\tassociation/)
      end
    end

    describe "given --detect_associations --detect_fields -w 10" do
      include_examples "generated_file"
      before do
        run_generator %W(#{model} --detect_associations --detect_fields -w 10)
      end

      it "blueprint file has wrapped fields declaration" do
        is_expected.to contain(/:make,\n    :model,\n    :miles/)
      end
    end
  end

  describe "given namespaced model " do
    include_examples "generated_file"
    before do
      run_generator %w(electric/truck)
    end

    subject { file('app/blueprints/electric/truck_blueprint.rb') }

    it "blueprint file has namespace directory / class" do
      is_expected.to contain(/class Electric::TruckBlueprint/)
    end
  end

end
