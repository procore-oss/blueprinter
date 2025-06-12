# frozen_string_literal: true

describe Blueprinter::V2::InstanceCache do
  subject { described_class.new }
  let(:widget_blueprint) { Class.new(Blueprinter::V2::Base) }
  let(:category_blueprint) { Class.new(Blueprinter::V2::Base) }

  context "#blueprint" do
    it "returns a new instance of a Blueprint subclass" do
      expect(subject.blueprint(widget_blueprint)).to be_a widget_blueprint
      expect(subject.blueprint(category_blueprint)).to be_a category_blueprint
    end

    it "returns the same instance of a Blueprint subclass" do
      blueprint1 = subject.blueprint widget_blueprint
      blueprint2 = subject.blueprint widget_blueprint
      expect(blueprint2).to be blueprint1
    end
  end

  context '#serializer' do
    it "returns a new instance of Serializer"  do
      widget_serializer = subject.serializer(widget_blueprint, { foo: true }, 1)
      expect(widget_serializer).to be_a Blueprinter::V2::Serializer
      expect(widget_serializer.blueprint.class).to be widget_blueprint
      expect(widget_serializer.options).to eq({ foo: true })
      expect(widget_serializer.instances).to be subject

      category_serializer = subject.serializer(category_blueprint, { foo: false }, 1)
      expect(category_serializer).to be_a Blueprinter::V2::Serializer
      expect(category_serializer.blueprint.class).to be category_blueprint
      expect(category_serializer.options).to eq({ foo: false })
      expect(category_serializer.instances).to be subject
    end

    it "returns the same instance of Serializer" do
      widget_serializer1 = subject.serializer(widget_blueprint, { foo: true }, 1)
      widget_serializer2 = subject.serializer(widget_blueprint, { foo: false }, 1)
      expect(widget_serializer2).to be widget_serializer1
    end
  end

  context "#extension" do
    let(:extension_a) { Class.new(Blueprinter::Extension) }
    let(:extension_b) { Class.new(Blueprinter::Extension) }

    it "returns an existing extension instance" do
      ext = extension_a.new
      expect(subject.extension(ext)).to be ext
    end

    it "returns a new instance of an Extension subclass" do
      expect(subject.extension(extension_a)).to be_a extension_a
      expect(subject.extension(extension_b)).to be_a extension_b
    end

    it "returns the same instance of a Blueprint subclass" do
      ext1 = subject.extension extension_a
      ext2 = subject.extension extension_a
      expect(ext2).to be ext1
    end

    it "returns a new instance of an Extension subclass from a proc" do
      expect(subject.extension(-> { extension_a.new })).to be_a extension_a
      expect(subject.extension(-> { extension_b.new })).to be_a extension_b
    end

    it "returns the same instance of a Blueprint subclass from a proc" do
      p = -> { extension_a.new }
      ext1 = subject.extension p
      ext2 = subject.extension p
      expect(ext2).to be ext1
    end
  end
end
