# frozen_string_literal: true

require 'json'

describe Blueprinter::V2::Render do
  let(:application_blueprint) do
    Class.new(Blueprinter::V2::Base)
  end

  let(:category_blueprint) do
    Class.new(application_blueprint) do
      self.blueprint_name = 'CategoryBlueprint'
      field :name, from: :n
    end
  end

  let(:widget_blueprint) do
    test = self
    Class.new(application_blueprint) do
      self.blueprint_name = 'WidgetBlueprint'
      field :name
      field :desc, from: :description
      association :category, test.category_blueprint

      view :extended do
        field :long_desc do |_ctx|
          'Long desc'
        end
      end

      view :with_parts do
        association :parts, [test.part_blueprint]
      end
    end
  end

  let(:part_blueprint) do
    Class.new(application_blueprint) do
      self.blueprint_name = 'PartBlueprint'
      field :number
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

    context '#store' do
      let(:blueprint) do
        Class.new(application_blueprint) do
          field(:foo) { |_obj, ctx| ctx.store[:foo] }
        end
      end

      it 'can set store before render' do
        widget = { name: 'Foo', description: 'About', category: { n: 'Bar' } }
        render = described_class.new(widget, { num: 42 }, blueprint: blueprint, collection: false, instances:)
        render.store = { foo: 'Foo' }

        expect(render.to_hash).to eq({ foo: 'Foo' })
      end

      it 'can set store values before render' do
        widget = { name: 'Foo', description: 'About', category: { n: 'Bar' } }
        render = described_class.new(widget, { num: 42 }, blueprint: blueprint, collection: false, instances:)
        render.store[:foo] = 'Foo'

        expect(render.to_hash).to eq({ foo: 'Foo' })
      end

      it 'uses the same context store throughout' do
        log = []
        ext = Class.new(Blueprinter::Extension) do
          def initialize(log) = @log = log

          def around_blueprint_init(ctx)
            ctx.store[:log] = @log
            ctx.store[:log] << "around_blueprint_init (#{ctx.blueprint})"
            yield ctx
          end

          def around_result(ctx)
            ctx.store[:log] << "around_result (#{ctx.blueprint})"
            yield ctx
          end

          def around_serialize_object(ctx)
            ctx.store[:log] << "around_serialize_object (#{ctx.blueprint})"
            yield ctx
          end

          def around_serialize_collection(ctx)
            ctx.store[:log] << "around_serialize_collection (#{ctx.blueprint})"
            yield ctx
          end

          def around_blueprint(ctx)
            ctx.store[:log] << "around_blueprint (#{ctx.blueprint})"
            yield ctx
          end

          def around_field_value(ctx)
            ctx.store[:log] << "around_field_value (#{ctx.blueprint})"
            yield ctx
          end

          def around_object_value(ctx)
            ctx.store[:log] << "around_object_value (#{ctx.blueprint})"
            yield ctx
          end

          def around_collection_value(ctx)
            ctx.store[:log] << "around_collection_value (#{ctx.blueprint})"
            yield ctx
          end
        end
        application_blueprint.extensions << ext.new(log)

        widget_blueprint[:with_parts].render({
          name: 'Widget A',
          description: 'A widget',
          category: { n: 'Stuff' },
          parts: [{ number: 42 }, { number: 101 }]
        }).to_hash

        expect(log).to eq [
          'around_blueprint_init (WidgetBlueprint.with_parts)',
          'around_result (WidgetBlueprint.with_parts)',
          'around_serialize_object (WidgetBlueprint.with_parts)',
          'around_blueprint (WidgetBlueprint.with_parts)',
          'around_field_value (WidgetBlueprint.with_parts)',
          'around_field_value (WidgetBlueprint.with_parts)',
          'around_object_value (WidgetBlueprint.with_parts)',
          'around_blueprint_init (CategoryBlueprint)',
          'around_serialize_object (CategoryBlueprint)',
          'around_blueprint (CategoryBlueprint)',
          'around_field_value (CategoryBlueprint)',
          'around_collection_value (WidgetBlueprint.with_parts)',
          'around_blueprint_init (PartBlueprint)',
          'around_serialize_collection (PartBlueprint)',
          'around_blueprint (PartBlueprint)',
          'around_field_value (PartBlueprint)',
          'around_blueprint (PartBlueprint)',
          'around_field_value (PartBlueprint)'
        ]
      end
    end
  end
end
