# frozen_string_literal: true

describe 'V1/V2 Compatibility' do
  let(:full_input) do
    {
      name: 'Foo',
      desc: 'Bar',
      category: { name: 'Foo', description: 'Baz', extra: 'Zorp' },
      parts: [
        { name: 'Foo', description: 'Baz', extra: 'Zorp' },
        { name: 'Foo', description: 'Baz', extra: 'Zorp' }
      ]
    }
  end

  let(:nil_input) do
    { name: 'Foo', category: nil, parts: nil }
  end

  let(:empty_input) do
    { name: 'Foo', parts: [] }
  end

  context 'V1' do
    let(:blueprint) do
      test = self
      Class.new(Blueprinter::Base) do
        field :name
        association :category, blueprint: test.v2_blueprint
        association :parts, blueprint: test.v2_blueprint

        view :extra do
          association :category, blueprint: test.v2_blueprint, view: :extended
          association :parts, blueprint: test.v2_blueprint, view: :extended
        end
      end
    end

    let(:v2_blueprint) do
      Class.new(Blueprinter::V2::Base) do
        field :description

        view :extended do
          field :extra
        end
      end
    end

    context 'default views' do
      it 'should serialize V2 objects and collections' do
        res = blueprint.render_as_hash(full_input)
        expect(res).to eq({
          name: 'Foo',
          category: { description: 'Baz' },
          parts: [
            { description: 'Baz' },
            { description: 'Baz' }
          ]
        })
      end

      it 'should serialize V2 objects and collections to JSON' do
        res = blueprint.render(full_input)
        expect(res).to eq({
          category: { description: 'Baz' },
          name: 'Foo',
          parts: [
            { description: 'Baz' },
            { description: 'Baz' }
          ]
        }.to_json)
      end

      it 'should serialize nil V2 objects and collections' do
        res = blueprint.render_as_hash(nil_input)
        expect(res).to eq({ name: 'Foo', category: nil, parts: nil })
      end

      it 'should serialize empty V2 collections' do
        res = blueprint.render_as_hash(empty_input)
        expect(res).to eq({ name: 'Foo', category: nil, parts: [] })
      end
    end

    context 'specified views' do
      it 'should serialize V1 objects and collections' do
        res = blueprint.render_as_hash(full_input, view: :extra)
        expect(res).to eq({
          name: 'Foo',
          category: { description: 'Baz', extra: 'Zorp' },
          parts: [
            { description: 'Baz', extra: 'Zorp' },
            { description: 'Baz', extra: 'Zorp' }
          ]
        })
      end
    end
  end

  context 'V2' do
    let(:blueprint) do
      test = self
      Class.new(Blueprinter::V2::Base) do
        field :name
        object :category, test.v1_blueprint
        collection :parts, test.v1_blueprint

        view :extra do
          object :category, test.v1_blueprint[:extended]
          collection :parts, test.v1_blueprint[:extended]
        end
      end
    end

    let(:v1_blueprint) do
      Class.new(Blueprinter::Base) do
        field :description

        view :extended do
          field :extra
        end
      end
    end

    context 'default views' do
      it 'should serialize V1 objects and collections' do
        res = blueprint.render(full_input).to_hash
        expect(res).to eq({
          name: 'Foo',
          category: { description: 'Baz' },
          parts: [
            { description: 'Baz' },
            { description: 'Baz' }
          ]
        })
      end

      it 'should serialize V1 objects and collections to JSON' do
        res = blueprint.render(full_input).to_json
        expect(res).to eq({
          name: 'Foo',
          category: { description: 'Baz' },
          parts: [
            { description: 'Baz' },
            { description: 'Baz' }
          ]
        }.to_json)
      end

      it 'should serialize nil V1 objects and collections' do
        res = blueprint.render(nil_input).to_hash
        expect(res).to eq({ name: 'Foo', category: nil, parts: nil })
      end

      it 'should serialize empty V1 collections' do
        res = blueprint.render(empty_input).to_hash
        expect(res).to eq({ name: 'Foo', category: nil, parts: [] })
      end
    end

    context 'specified views' do
      it 'should serialize V1 objects and collections' do
        res = blueprint[:extra].render(full_input).to_hash
        expect(res).to eq({
          name: 'Foo',
          category: { description: 'Baz', extra: 'Zorp' },
          parts: [
            { description: 'Baz', extra: 'Zorp' },
            { description: 'Baz', extra: 'Zorp' }
          ]
        })
      end
    end
  end

  context 'instance cache' do
    let(:blueprints) do
      blueprints = {}
      blueprints[:barprint] = Class.new(Blueprinter::V2::Base) do
        bp = blueprints
        options[:exclude_if_nil] = true
        field :name do |ctx|
          "#{ctx.object[:name]} - #{ctx.options[:tag]}"
        end
        view :extended do
          object :foo, bp[:fooprint][:extended]
        end
      end
      blueprints[:fooprint] = Class.new(Blueprinter::Base) do
        bp = blueprints
        field :name do |obj, opts|
          "#{obj[:name]} - #{opts[:tag]}"
        end
        view :extended do
          association :bar1, blueprint: bp[:barprint], view: :extended
          association :bar2, blueprint: bp[:barprint], view: :extended
        end
      end
      blueprints
    end

    let(:instances) do
      Blueprinter::V2::InstanceCache.new.tap do |instances|
        def instances.cache = @cache
      end
    end

    it 'should use the same V2 Serializer and Blueprint instances through V1' do
      barprint = blueprints[:barprint][:extended]
      bar_serializer = instances[Blueprinter::V2::Serializer, [barprint, { tag: 'X' }, instances]]

      res = bar_serializer.object({
        name: 'Bar 1',
        foo: {
          name: 'Foo 1',
          bar1: { name: 'Bar 2' },
          bar2: { name: 'Bar 2' }
        }
      })
      expect(res).to eq({
        name: 'Bar 1 - X',
        foo: {
          name: 'Foo 1 - X',
          bar1: { name: 'Bar 2 - X' },
          bar2: { name: 'Bar 2 - X' }
        }
      })

      barprint_serializer_instances = instances.cache.select do |(key, _val)|
        key == bar_serializer.class.object_id || (key.is_a?(Array) && key[0] == bar_serializer.class.object_id)
      end
      expect(barprint_serializer_instances.size).to eq 1

      barprint_instances = instances.cache.select do |key, _val|
        key == barprint.object_id || (key.is_a?(Array) && key[0] == barprint.object_id)
      end
      expect(barprint_instances.size).to eq 1
    end

    it 'should use the same V2 Serializer and Blueprint instances from V1' do
      def instances.cache = @cache
      def instances.log = @log ||= []
      def instances.[](obj, args = nil)
        log << [obj, *args]
        super
      end

      res = blueprints[:fooprint].render_as_hash({
        name: 'Foo 1',
        bar1: {
          name: 'Bar 1',
          foo: {
            name: 'Foo 2',
            bar1: { name: 'Bar 3' },
            bar2: { name: 'Bar 4' },
          }
        },
        bar2: {
          name: 'Bar 2',
          foo: {
            name: 'Foo 3',
            bar1: { name: 'Bar 5' },
            bar2: { name: 'Bar 6' },
          }
        }
      }, {
        view: :extended,
        v2_instances: instances,
        tag: 'X'
      })

      barprint = blueprints[:barprint][:extended]
      serializer = Blueprinter::V2::Serializer

      barprint_serializer_instances = instances.cache.select do |(key, _val)|
        key == serializer.object_id || (key.is_a?(Array) && key[0] == serializer.object_id)
      end
      expect(barprint_serializer_instances.size).to eq 1

      barprint_instances = instances.cache.select do |key, _val|
        key == barprint.object_id || (key.is_a?(Array) && key[0] == barprint.object_id)
      end
      expect(barprint_instances.size).to eq 1

      barprint_serializer_calls = instances.log.select do |(klass, arg1, _)|
        klass == serializer && arg1 == barprint
      end
      expect(barprint_serializer_calls.size).to eq 6
    end
  end
end
