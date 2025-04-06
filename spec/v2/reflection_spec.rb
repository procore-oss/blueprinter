# frozen_string_literal: true

describe "Blueprinter::V2::Reflection" do
  let(:blueprint) do
    Class.new(Blueprinter::V2::Base) do
      view :foo
      view :bar do
        view :foo do
          view :borp
        end
      end
    end
  end

  it "finds all view keys" do
    view_names = blueprint.reflections.keys
    expect(view_names.sort).to eq %i(
      default
      foo
      bar
      bar.foo
      bar.foo.borp
    ).sort
  end

  it "finds all view names" do
    view_names = blueprint.reflections.values.map(&:name)
    expect(view_names.sort).to eq %i(
      default
      foo
      bar
      bar.foo
      bar.foo.borp
    ).sort
  end

  it "finds nested view keys" do
    bar_view_names = blueprint[:bar].reflections.keys
    expect(bar_view_names.sort).to eq %i(
      default
      foo
      foo.borp
    ).sort

    bar_foo_view_names = blueprint[:"bar.foo"].reflections.keys
    expect(bar_foo_view_names.sort).to eq %i(
      default
      borp
    ).sort
  end

  it "finds nested view names" do
    bar_view_names = blueprint[:bar].reflections.values.map(&:name)
    expect(bar_view_names.sort).to eq %i(
      default
      foo
      foo.borp
    ).sort

    bar_foo_view_names = blueprint[:"bar.foo"].reflections.values.map(&:name)
    expect(bar_foo_view_names.sort).to eq %i(
      default
      borp
    ).sort
  end

  context 'fields and associations' do
    let(:category_blueprint) { Class.new(Blueprinter::V2::Base) }
    let(:widget_blueprint) { Class.new(Blueprinter::V2::Base) }
    let(:blueprint) do
      test = self
      Class.new(Blueprinter::V2::Base) do
        field :name
        object :category, test.category_blueprint

        view :extended do
          collection :widgets, test.widget_blueprint
          field :description
        end
      end
    end

    it 'are found' do
      expect(blueprint.reflections[:default].fields.keys).to eq %i(name)
      expect(blueprint.reflections[:default].objects.keys).to eq %i(category)
      expect(blueprint.reflections[:default].collections.keys).to eq %i()

      expect(blueprint.reflections[:extended].fields.keys).to eq %i(name description)
      expect(blueprint.reflections[:extended].objects.keys).to eq %i(category)
      expect(blueprint.reflections[:extended].collections.keys).to eq %i(widgets)
    end

    it 'are in the definition order' do
      names = blueprint.reflections[:default].ordered.map(&:name)
      expect(names).to eq %i(name category)

      names = blueprint.reflections[:extended].ordered.map(&:name)
      expect(names).to eq %i(name category widgets description)
    end
  end
end
