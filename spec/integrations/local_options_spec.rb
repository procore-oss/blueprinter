# frozen_string_literal: true

describe 'V1 field block keywords' do
  let(:v1_blueprint) do
    Class.new(Blueprinter::Base) do
      field(:greeting) { |_obj, view:, user:| "#{view}:#{user}" }
    end
  end

  it 'passes only view and render options to a V1 root render' do
    expect(v1_blueprint.render_as_hash({}, user: 'ada')).to eq(greeting: 'default:ada')
  end

  it 'passes only view and render options when a V2 blueprint renders a V1 association' do
    v1 = v1_blueprint
    v2 = Class.new(Blueprinter::V2::Base) do
      association :child, v1
    end
    expect(v2.render({ child: {} }, user: 'ada').to_hash).to eq(child: { greeting: 'default:ada' })
  end

  it 'keeps V2 render state across a V1 association' do
    depths = []
    ext = Class.new(Blueprinter::Extension) do
      define_method(:initialize) { around_blueprint :log }
      define_method(:log) { |ctx, &blk| depths << [ctx.blueprint.class.name, ctx.depth]; blk.call(ctx) }
    end
    leaf = Class.new(Blueprinter::V2::Base) do
      def self.name = 'Leaf'
      add ext.new
      field :id
    end
    middle = Class.new(Blueprinter::Base) do
      association :leaf, blueprint: leaf
    end
    root = Class.new(Blueprinter::V2::Base) do
      def self.name = 'Root'
      add ext.new
      association :middle, middle
    end
    root.render({ middle: { leaf: { id: 1 } } }).to_hash
    expect(depths).to eq([['Root', 1], ['Leaf', 3]])
  end
end
