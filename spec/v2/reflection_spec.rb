# frozen_string_literal: true

describe "Blueprinter::V2::Reflection" do
  let(:application_blueprint) do
    Class.new(Blueprinter::V2::Base) do
      use :asdf

      partial :asdf do
        view :identity do
          view :foo
        end
      end
    end
  end

  let(:blueprint) do
    Class.new(application_blueprint) do
      view :a
      view :b do
        set :foo, 'foo'
        view :c do
          set :foo, 'bar'
          set :exclude_if_nil, true
          view :d
        end
      end
    end
  end

  it "finds all view keys" do
    view_names = blueprint.reflections.keys
    expect(view_names.sort).to eq %i(
      default
      identity
      identity.foo
      a
      b
      b.c
      b.c.d
    ).sort
  end

  it "finds all view names" do
    view_names = blueprint.reflections.values.map(&:name)
    expect(view_names.sort).to eq %i(
      default
      identity
      identity.foo
      a
      b
      b.c
      b.c.d
    ).sort
  end

  it "finds nested view keys" do
    bar_view_names = blueprint[:b].reflections.keys
    expect(bar_view_names.sort).to eq %i(
      default
      c
      c.d
    ).sort

    bar_foo_view_names = blueprint[:"b.c"].reflections.keys
    expect(bar_foo_view_names.sort).to eq %i(
      default
      d
    ).sort
  end

  it "finds nested view names" do
    bar_view_names = blueprint[:b].reflections.values.map(&:name)
    expect(bar_view_names.sort).to eq %i(
      default
      c
      c.d
    ).sort

    bar_foo_view_names = blueprint[:"b.c"].reflections.values.map(&:name)
    expect(bar_foo_view_names.sort).to eq %i(
      default
      d
    ).sort
  end

  it 'has options' do
    expect(blueprint.reflections[:default].options).to eq({})
    expect(blueprint.reflections[:b].options).to eq({ foo: 'foo' })
    expect(blueprint.reflections[:"b.c"].options).to eq({ foo: 'bar', exclude_if_nil: true })
    expect(blueprint.reflections[:"b.c.d"].options).to eq({ foo: 'bar', exclude_if_nil: true })
  end

  context 'fields and associations' do
    let(:category_blueprint) { Class.new(Blueprinter::V2::Base) }
    let(:widget_blueprint) { Class.new(Blueprinter::V2::Base) }
    let(:blueprint) do
      test = self
      Class.new(Blueprinter::V2::Base) do
        set :if, ->(_ctx) { true }
        field :name, default: 'None'
        association :category, test.category_blueprint, default: { name: 'None' }

        view :extended do
          association :widgets, [test.widget_blueprint], default: []
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

    it 'retain their original options' do
      name = blueprint.reflections[:default].fields[:name]
      expect(name.options).to eq({ default: 'None' })

      category = blueprint.reflections[:default].objects[:category]
      expect(category.options).to eq({ default: { name: 'None' } })

      widgets = blueprint.reflections[:extended].collections[:widgets]
      expect(widgets.options).to eq({ default: [] })
    end
  end
end
