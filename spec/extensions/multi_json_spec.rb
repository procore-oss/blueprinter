# frozen_string_literal: true

require 'multi_json'

describe Blueprinter::Extensions::MultiJson do
  let(:blueprint) do
    Class.new(Blueprinter::V2::Base) do
      fields :id, :name
    end
  end

  it 'renders JSON' do
    fields = blueprint.reflections[:default].ordered
    ctx = Blueprinter::V2::Context::Result.new(blueprint, fields, {}, { id: 42, name: 'Foo' }, :json)
    res = described_class.new.around_result(ctx, &:object)
    expect(res.value).to eq '{"id":42,"name":"Foo"}'
  end

  it 'renders JSON from a blueprint' do
    mj_blueprint = Class.new(blueprint) do
      extensions << Blueprinter::Extensions::MultiJson.new
    end
    widget = { id: 42, name: 'Foo', junk: true }

    res = mj_blueprint.render(widget).to_json
    expect(res).to eq '{"id":42,"name":"Foo"}'
  end

  it 'passes global options to MultiJson.dump' do
    mj_blueprint = Class.new(blueprint) do
      extensions << Blueprinter::Extensions::MultiJson.new({ pretty: true })
    end
    widget = { id: 42, name: 'Foo', junk: true }

    expect(MultiJson).to receive(:dump).with({ id: 42, name: 'Foo' }, { pretty: true })
    mj_blueprint.render(widget).to_json
  end

  it 'passes local options to MultiJson.dump' do
    mj_blueprint = Class.new(blueprint) do
      extensions << Blueprinter::Extensions::MultiJson.new({ pretty: true })
    end
    widget = { id: 42, name: 'Foo', junk: true }

    expect(MultiJson).to receive(:dump).with({ id: 42, name: 'Foo' }, { pretty: true, foo: true })
    mj_blueprint.render(widget, { multi_json: { foo: true } }).to_json
  end
end
