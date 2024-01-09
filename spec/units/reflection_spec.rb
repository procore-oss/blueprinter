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
        association :parts, blueprint: part_bp, view: :extended
      end

      view :extended_plus do
        include_view :extended
        field :foo
        association :foos, blueprint: part_bp
      end

      view :extended_plus_plus do
        include_view :extended_plus
        field :bar
        association :bars, blueprint: part_bp
      end

      view :legacy do
        association :parts, blueprint: part_bp, name: :pieces
      end
    end
  }

  it 'should list views' do
    expect(widget_blueprint.reflections.keys.sort).to eq [
      :identifier,
      :default,
      :extended,
      :extended_plus,
      :extended_plus_plus,
      :legacy,
    ].sort
  end

  it 'should list fields' do
    expect(part_blueprint.reflections.fetch(:extended).fields.keys.sort).to eq [
      :id,
      :name,
      :description,
    ].sort
  end

  it 'should list fields from included views' do
    expect(widget_blueprint.reflections.fetch(:extended_plus_plus).fields.keys.sort).to eq [
      :id,
      :name,
      :foo,
      :bar,
    ].sort
  end

  it 'should list associations' do
    associations = widget_blueprint.reflections.fetch(:default).associations
    expect(associations.keys).to eq [:category]
  end

  it 'should list associations from included views' do
    associations = widget_blueprint.reflections.fetch(:extended_plus_plus).associations
    expect(associations.keys.sort).to eq [:category, :parts, :foos, :bars].sort
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
