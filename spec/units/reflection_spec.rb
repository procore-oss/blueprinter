# frozen_string_literal: true

require 'json'

describe Blueprinter::Reflection do
  let(:category_blueprint) {
    Class.new(Blueprinter::Base) do
      fields :id, :name
    end
  }

  let(:part_blueprint) {
    Class.new(Blueprinter::Base) do
      fields :id, :name

      view :extended do
        include_view :default
        field :description
      end
    end
  }

  let(:widget_blueprint) {
    cat_bp = category_blueprint
    part_bp = part_blueprint
    Class.new(Blueprinter::Base) do
      fields :id, :name
      association :category, blueprint: cat_bp

      view :extended do
        include_view :default
        association :parts, blueprint: part_bp, view: :extended
      end

      view :legacy do
        include_view :default
        association :parts, blueprint: part_bp, name: :pieces
      end
    end
  }

  it 'should list views' do
    expect(widget_blueprint.reflections.keys).to eq [
      :identifier,
      :default,
      :extended,
      :legacy,
    ]
  end

  it 'should list fields' do
    expect(part_blueprint.reflections.fetch(:extended).fields.keys).to eq [
      :id,
      :name,
      :description,
    ]
  end

  it 'should list associations' do
    associations = widget_blueprint.reflections.fetch(:default).associations
    expect(associations.keys).to eq [:category]
  end

  it 'should list associations from included views' do
    associations = widget_blueprint.reflections.fetch(:extended).associations
    expect(associations.keys).to eq [:category, :parts]
  end

  it 'should list associations using custom names' do
    associations = widget_blueprint.reflections.fetch(:legacy).associations
    expect(associations.keys).to eq [:category, :parts]
    expect(associations[:parts].display_name).to eq :pieces
  end

  it 'should get a blueprint and view from an association' do
    assoc = widget_blueprint.reflections[:extended].associations[:parts]
    expect(assoc.name).to eq :parts
    expect(assoc.display_name).to eq :parts
    expect(assoc.blueprint).to eq part_blueprint
    expect(assoc.view).to eq :extended
  end
end
