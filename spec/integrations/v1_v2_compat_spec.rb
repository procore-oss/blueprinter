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
end
