# frozen_string_literal: true

describe "Blueprinter::V2 around_blueprint_init" do
  # Builds an extension whose `around_blueprint_init` hook runs `block`
  def init_ext(&block)
    Class.new(Blueprinter::Extension) do
      define_method(:initialize) { around_blueprint_init :run }
      define_method(:run) do |ctx, &next_hook|
        block.call(ctx)
        next_hook.call(ctx)
      end
    end.new
  end

  it "reorders fields" do
    blueprint = Class.new(Blueprinter::V2::Base) do
      field :name
      field :id
    end
    blueprint.add init_ext { |ctx| ctx.fields = ctx.fields.sort_by { |f| f.name.to_s } }

    expect(blueprint.render_as_hash({ name: 'Foo', id: 1 }).keys).to eq %i[id name]
  end

  it "renames a field without changing where it reads from" do
    blueprint = Class.new(Blueprinter::V2::Base) do
      field :name
    end
    blueprint.add init_ext { |ctx| ctx.fields.each { |f| f.name = :"v2_#{f.name}" } }

    expect(blueprint.render_as_hash({ name: 'Foo' })).to eq({ v2_name: 'Foo' })
  end

  it "removes a field" do
    blueprint = Class.new(Blueprinter::V2::Base) do
      fields :name, :secret
    end
    blueprint.add init_ext { |ctx| ctx.fields = ctx.fields.reject { |f| f.name == :secret } }

    expect(blueprint.render_as_hash({ name: 'Foo', secret: 'shh' })).to eq({ name: 'Foo' })
  end

  it "adds a field" do
    blueprint = Class.new(Blueprinter::V2::Base) do
      field :name
    end
    blueprint.add init_ext { |ctx|
      ctx.fields << Blueprinter::V2::Fields::Configurable.new(:field, :kind, :kind, {}, nil, nil, nil)
    }

    expect(blueprint.render_as_hash({ name: 'Foo', kind: 'widget' })).to eq({ name: 'Foo', kind: 'widget' })
  end

  it "changes the Blueprint's options, and they reach the fields" do
    blueprint = Class.new(Blueprinter::V2::Base) do
      field :name
    end
    blueprint.add init_ext { |ctx| ctx.options[:default] = 'N/A' }

    expect(blueprint.render_as_hash({ name: nil })).to eq({ name: 'N/A' })
  end

  it "runs once per Blueprint, not once per render" do
    runs = 0
    blueprint = Class.new(Blueprinter::V2::Base) do
      field :name
    end
    blueprint.add init_ext { |_ctx| runs += 1 }

    3.times { blueprint.render_as_hash({ name: 'Foo' }) }
    expect(runs).to eq 1
  end

  it "runs for each view with that view's own fields and options" do
    seen = {}
    blueprint = Class.new(Blueprinter::V2::Base) do
      self.blueprint_name = 'WidgetBlueprint'
      field :name

      view :extended do
        field :description
      end
    end
    blueprint.add init_ext { |ctx| seen[ctx.blueprint.blueprint_name] = ctx.fields.map(&:name) }

    blueprint.render_as_hash({ name: 'Foo' })
    blueprint[:extended].render_as_hash({ name: 'Foo', description: 'Bar' })

    expect(seen).to eq({
      'WidgetBlueprint' => %i[name],
      'WidgetBlueprint.extended' => %i[name description]
    })
  end

  it "modifies Blueprint options and field options together" do
    blueprint = Class.new(Blueprinter::V2::Base) do
      fields :id, :name, :summary, :description
    end
    blueprint.add init_ext { |ctx|
      ctx.options[:exclude_if_nil] = true
      ctx.fields.sort_by!(&:name)
      ctx.fields.find { |f| f.name == :description }.options[:exclude_if_nil] = false
    }

    expect(blueprint.render({ id: 42, name: nil, summary: 'foo', description: nil })).to eq({
      description: nil,
      id: 42,
      summary: 'foo'
    }.to_json)

    # Unlike a render hook, what it decided is now part of the Blueprint
    expect(blueprint.reflections[:default].options).to eq({ exclude_if_nil: true })
    expect(blueprint.reflections[:default].fields[:description].options).to eq({ exclude_if_nil: false })
  end

  it "is reflected by `reflections`" do
    blueprint = Class.new(Blueprinter::V2::Base) do
      field :name
      field :id
    end
    blueprint.add init_ext { |ctx| ctx.fields = ctx.fields.sort_by { |f| f.name.to_s } }

    expect(blueprint.reflections[:default].fields.keys).to eq %i[id name]
  end

  it "has no render context to read" do
    ctx_members = nil
    blueprint = Class.new(Blueprinter::V2::Base) do
      field :name
    end
    blueprint.add init_ext { |ctx| ctx_members = ctx.members }

    blueprint.render_as_hash({ name: 'Foo' }, meta: 'ignored')
    expect(ctx_members).to eq %i[blueprint fields options]
  end

  it "raises if the hook doesn't yield" do
    ext = Class.new(Blueprinter::Extension) do
      def initialize = around_blueprint_init :run

      def run(ctx); end
    end.new
    blueprint = Class.new(Blueprinter::V2::Base) do
      field :name
    end
    blueprint.add ext

    expect { blueprint.render_as_hash({ name: 'Foo' }) }.to raise_error(Blueprinter::Errors::ExtensionHook)
  end

  it "rejects an unknown hook name" do
    expect do
      Class.new(Blueprinter::Extension) do
        def initialize = around_blueprint_dls :run

        def run(ctx) = yield(ctx)
      end.new
    end.to raise_error(NoMethodError)
  end
end
