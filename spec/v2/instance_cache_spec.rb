# frozen_string_literal: true

describe Blueprinter::V2::InstanceCache do
  subject { described_class.new }
  let(:widget_blueprint) { Class.new(Blueprinter::V2::Base) }
  let(:category_blueprint) { Class.new(Blueprinter::V2::Base) }
  let(:store) { {} }

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
end
