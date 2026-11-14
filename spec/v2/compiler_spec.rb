# frozen_string_literal: true

describe Blueprinter::V2::Compiler do
  # Field names and sources are interpolated into generated Ruby, so anything that can appear in a Symbol has to
  # survive the round trip without changing the meaning of the source.
  it 'serializes fields whose names and sources need escaping' do
    names = [:"foo bar", :"a\"b", :"a'b", :'a#{1 + 1}b', :"a\\b", :"a\nb", :end, :"", :"é", :"1abc"]
    blueprint = Class.new(Blueprinter::V2::Base) do
      names.each { |n| field n }
    end
    object = names.to_h { |n| [n, "value of #{n}"] }

    expect(blueprint.render_as_hash(object)).to eq(object)
  end

  it 'reads a renamed source whose name needs escaping' do
    blueprint = Class.new(Blueprinter::V2::Base) do
      field :safe, source: :"not safe"
    end

    expect(blueprint.render_as_hash({ "not safe": 'Foo' })).to eq({ safe: 'Foo' })
  end

  it 'reads from an object by method and from a Hash by key or String key' do
    blueprint = Class.new(Blueprinter::V2::Base) do
      field :name
    end
    struct = Struct.new(:name).new('Foo')

    expect(blueprint.render_as_hash(struct)).to eq({ name: 'Foo' })
    expect(blueprint.render_as_hash({ name: 'Foo' })).to eq({ name: 'Foo' })
    expect(blueprint.render_as_hash({ 'name' => 'Foo' })).to eq({ name: 'Foo' })
  end

  it 'exposes the generated source' do
    blueprint = Class.new(Blueprinter::V2::Base) do
      field :name
    end

    source = blueprint.serializer.compiled.source
    expect(source).to include 'def _serialize(frame, object)'
    expect(source).to include 'result[:name]'
  end

  it 'names the Blueprint in backtraces from generated code' do
    blueprint = Class.new(Blueprinter::V2::Base) do
      self.blueprint_name = 'WidgetBlueprint'
      field(:name) { |_obj, _ctx| raise 'boom' }
    end

    blueprint.render_as_hash({})
  rescue RuntimeError => e
    expect(e.backtrace.join("\n")).to include '(blueprinter)WidgetBlueprint'
  end

  it 'gives a repeated value one constant slot' do
    shared = ->(_ctx) { true }
    blueprint = Class.new(Blueprinter::V2::Base) do
      field :a, if: shared
      field :b, if: shared
    end

    constants = blueprint.serializer.compiled.constants
    expect(constants.count { |v| v.equal?(shared) }).to eq 1
  end

  it 'emits nothing for options a field does not use' do
    blueprint = Class.new(Blueprinter::V2::Base) do
      field :name
    end

    source = blueprint.serializer.compiled.source
    expect(source).to_not include 'ctx.field'
    expect(source).to_not include 'catch'
    expect(source).to_not include '_d'
  end
end
