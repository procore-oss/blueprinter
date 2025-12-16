# frozen_string_literal: true

require 'json'

describe Blueprinter::V2::Render do
  let(:category_blueprint) do
    Class.new(Blueprinter::V2::Base) do
      field :name, from: :n
    end
  end

  let(:widget_blueprint) do
    test = self
    Class.new(Blueprinter::V2::Base) do
      field :name
      field :desc, from: :description
      object :category, test.category_blueprint

      view :extended do
        field :long_desc do |_ctx|
          'Long desc'
        end
      end
    end
  end

  let(:instances) { Blueprinter::V2::InstanceCache.new }

  it 'renders an object to a hash' do
    widget = { name: 'Foo', description: 'About', category: { n: 'Bar' } }
    render = described_class.new(widget, {}, blueprint: widget_blueprint, collection: false, instances:)

    expect(render.to_hash).to eq({
      name: 'Foo',
      desc: 'About',
      category: { name: 'Bar' }
    })
  end

  it 'renders a collection to a hash' do
    widgets = [
      { name: 'Foo', description: 'About', category: { n: 'Bar' } },
      { name: 'Foo 2', description: 'About 2', category: { n: 'Bar 2' } },
    ]
    render = described_class.new(widgets, {}, blueprint: widget_blueprint, collection: true, instances:)

    expect(render.to_hash).to eq([
      {
        name: 'Foo',
        desc: 'About',
        category: { name: 'Bar' }
      },
      {
        name: 'Foo 2',
        desc: 'About 2',
        category: { name: 'Bar 2' }
      },
    ])
  end

  it 'renders an object to JSON' do
    widget = { name: 'Foo', description: 'About', category: { n: 'Bar' } }
    render = described_class.new(widget, {}, blueprint: widget_blueprint, collection: false, instances:)

    expect(render.to_json).to eq({
      name: 'Foo',
      desc: 'About',
      category: { name: 'Bar' }
    }.to_json)
  end

  it 'renders a collection to JSON' do
    widget = { name: 'Foo', description: 'About', category: { n: 'Bar' } }
    render = described_class.new([widget], {}, blueprint: widget_blueprint, collection: true, instances:)

    expect(render.to_json).to eq([{
      name: 'Foo',
      desc: 'About',
      category: { name: 'Bar' }
    }].to_json)
  end

  it 'renders to JSON and ignores the arg (for Rails `render json:`)' do
    widget = { name: 'Foo', description: 'About', category: { n: 'Bar' } }
    render = described_class.new([widget], {}, blueprint: widget_blueprint, collection: true, instances:)

    expect(render.to_json({ junk: 'junk' })).to eq([{
      name: 'Foo',
      desc: 'About',
      category: { name: 'Bar' }
    }].to_json)
  end

  context 'around_result' do
    it 'runs around the entire result' do
      widget_blueprint.extension do
        def around_result(ctx)
          case ctx.format
          when :json
            ctx.format = :hash
            result = yield(ctx).merge({ foo: 'bar' })
            JSON.dump result
          else
            yield ctx
          end
        end
      end
      widget = { name: 'Foo', description: 'About', category: { n: 'Bar' } }
      render = described_class.new(widget, {}, blueprint: widget_blueprint, collection: false, instances:)

      expect(render.to_json).to eq({
        name: 'Foo',
        desc: 'About',
        category: { name: 'Bar' },
        foo: 'bar'
      }.to_json)
    end

    it 'can change the blueprint (class)' do
      widget_blueprint.extension do
        def around_result(ctx)
          ctx.blueprint = Class.new(Blueprinter::V2::Base) { field :name }
          yield ctx
        end
      end
      widget = { name: 'Foo', description: 'About', category: { n: 'Bar' } }
      render = described_class.new(widget, {}, blueprint: widget_blueprint, collection: false, instances:)

      expect(render.to_json).to eq({ name: 'Foo' }.to_json)
    end

    it 'can change the blueprint (instance)' do
      widget_blueprint.extension do
        def around_result(ctx)
          ctx.blueprint = Class.new(Blueprinter::V2::Base) { field :name }.new
          yield ctx
        end
      end
      widget = { name: 'Foo', description: 'About', category: { n: 'Bar' } }
      render = described_class.new(widget, {}, blueprint: widget_blueprint, collection: false, instances:)

      expect(render.to_json).to eq({ name: 'Foo' }.to_json)
    end

    it 'can change the object' do
      widget_blueprint.extension do
        def around_result(ctx)
          ctx.object = ctx.object.merge({ name: 'Bar' })
          yield ctx
        end
      end
      widget = { name: 'Foo', description: 'About', category: { n: 'Bar' } }
      render = described_class.new(widget, {}, blueprint: widget_blueprint, collection: false, instances:)

      expect(render.to_json).to eq({
        name: 'Bar',
        desc: 'About',
        category: { name: 'Bar' },
      }.to_json)
    end

    it 'can change the object (different blueprint)' do
      widget_blueprint.extension do
        def around_result(ctx)
          ctx.blueprint = Class.new(Blueprinter::V2::Base) { field :name }
          ctx.object = ctx.object.merge({ name: 'Bar' })
          yield ctx
        end
      end
      widget = { name: 'Foo', description: 'About', category: { n: 'Bar' } }
      render = described_class.new(widget, {}, blueprint: widget_blueprint, collection: false, instances:)

      expect(render.to_json).to eq({ name: 'Bar' }.to_json)
    end

    it 'can change the options' do
      widget_blueprint.extension do
        def around_result(ctx)
          num = ctx.options[:num] || 0
          ctx.options = ctx.options.merge({ num: num + 1 })
          yield ctx
        end
      end
      widget_blueprint.extension do
        def around_result(ctx)
          res = yield ctx
          res.merge({ num: ctx.options[:num] })
        end
      end
      widget = { name: 'Foo', description: 'About', category: { n: 'Bar' } }
      render = described_class.new(widget, { num: 42 }, blueprint: widget_blueprint, collection: false, instances:)

      expect(render.to_hash).to eq({
        name: 'Foo',
        desc: 'About',
        category: { name: 'Bar' },
        num: 43,
      })
    end

    it 'can change the options (different blueprint)' do
      widget_blueprint.extension do
        def around_result(ctx)
          num = ctx.options[:num] || 0
          ctx.options = ctx.options.merge({ num: num + 1 })
          ctx.blueprint = Class.new(Blueprinter::V2::Base) do
            field :name do |obj, ctx|
              "#{obj[:name]} #{ctx.options[:num]}"
            end
          end
          yield ctx
        end
      end
      widget = { name: 'Foo', description: 'About', category: { n: 'Bar' } }
      render = described_class.new(widget, { num: 42 }, blueprint: widget_blueprint, collection: false, instances:)

      expect(render.to_hash).to eq({ name: 'Foo 43' })
    end

    it 'can change the format' do
      widget_blueprint.extension do
        def around_result(ctx)
          ctx.format = :yaml
          yield ctx
        end
      end
      widget = { name: 'Foo', description: 'About', category: { n: 'Bar' } }
      render = described_class.new(widget, { num: 42 }, blueprint: widget_blueprint, collection: false, instances:)

      expect { render.to_hash }.to raise_error(Blueprinter::BlueprinterError, 'Unrecognized serialization format `:yaml`')
    end

    it 'can change the format (different blueprint)' do
      widget_blueprint.extension do
        def around_result(ctx)
          ctx.format = :yaml
          ctx.blueprint = Class.new(Blueprinter::V2::Base) { field :name }
          yield ctx
        end
      end
      widget = { name: 'Foo', description: 'About', category: { n: 'Bar' } }
      render = described_class.new(widget, { num: 42 }, blueprint: widget_blueprint, collection: false, instances:)

      expect { render.to_hash }.to raise_error(Blueprinter::BlueprinterError, 'Unrecognized serialization format `:yaml`')
    end
  end
end
