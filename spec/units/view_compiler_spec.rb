# frozen_string_literal: true

require 'blueprinter/view_compiler'

describe Blueprinter::ViewCompiler do
  let(:item_class) { Struct.new(:id, :name, :status, :child, keyword_init: true) }
  let(:item) { item_class.new(id: 1, name: 'Leak', status: 'open') }

  before do
    reset_blueprinter_config!
    Blueprinter.configuration.compile_views = true
  end

  after { reset_blueprinter_config! }

  def blueprint(&body)
    Class.new(Blueprinter::Base, &body)
  end

  def generated_body(blueprint)
    collection = blueprint.view_collection
    described_class.body(fields: collection.fields_for(:default), transformers: collection.transformers(:default),
                         ref: ->(_) { 'REFS[0]' })
  end

  it 'compiles plain fields into a Hash literal with direct method calls' do
    plain = blueprint do
      identifier :id
      fields :status, :name
    end

    expect(generated_body(plain)).to eq('{ :id => object.id, :name => object.name, :status => object.status }')
    expect(plain.render_as_hash(item)).to eq(id: 1, name: 'Leak', status: 'open')
  end

  it "compiles simple associations into a call to the associated Blueprint's hashify" do
    child = blueprint { identifier :id }
    parent = blueprint { association :child, blueprint: child }

    expect(generated_body(parent)).to include('.hashify(a, view_name: REFS[')
    expect(parent.render_as_hash(item_class.new(child: item_class.new(id: 2)))).to eq(child: { id: 2 })
    expect(parent.render_as_hash(item_class.new)).to eq(child: nil)
  end

  it 'uses standard rendering for a field or association with an option the compiler does not know' do
    child = blueprint { identifier :id }
    annotated = blueprint do
      identifier :id
      field :name, description: 'The item name'
      association :child, blueprint: child, description: 'The child item'
    end

    expect(generated_body(annotated)).to eq(
      "h = { :id => object.id }\n" \
      "if !REFS[0].skip?(:child, object, options)\nh[:child] = REFS[0].extract(object, options)\nend\n" \
      "if !REFS[0].skip?(:name, object, options)\nh[:name] = REFS[0].extract(object, options)\nend\nh"
    )
    expect(annotated.render_as_hash(item_class.new(id: 1, name: 'Leak', child: item_class.new(id: 2))))
      .to eq(id: 1, child: { id: 2 }, name: 'Leak')
  end

  it 'names the blueprint and view in a backtrace from compiled code' do
    stub_const('ItemBlueprint', blueprint { view(:extended) { field :missing } })

    expect { ItemBlueprint.render_as_hash(item, view: :extended) }.to raise_error(NoMethodError) { |error|
      expect(error.backtrace.first).to start_with('(blueprinter compiled ItemBlueprint extended):')
    }
  end

  it 'recompiles when the view cache is invalidated' do
    changing = blueprint do
      identifier :id
      view(:extended) { field :name }
    end
    expect(changing.render_as_hash(item, view: :extended)).to eq(id: 1, name: 'Leak')

    changing.class_eval { view(:extended) { field :status } }

    expect(changing.render_as_hash(item, view: :extended)).to eq(id: 1, name: 'Leak', status: 'open')
  end

  it 'compiles safely when many threads render for the first time' do
    threaded = blueprint do
      identifier :id
      fields :name, :status
      view(:extended) { field(:upcased) { |record, _options| record.name.upcase } }
    end

    results = Array.new(16) do |i|
      Thread.new { threaded.render_as_hash([item], view: i.even? ? :default : :extended) }
    end.map(&:value)

    expect(results.uniq).to contain_exactly([{ id: 1, name: 'Leak', status: 'open' }],
                                            [{ id: 1, name: 'Leak', status: 'open', upcased: 'LEAK' }])
  end

  it 'never evaluates names or method names as code' do
    $blueprinter_view_compiler_injected = false
    payload = '#{$blueprinter_view_compiler_injected = true}"); $blueprinter_view_compiler_injected = true; ("'
    target = Struct.new(:id) do
      define_method(payload) { 'value' }
    end
    unusual = blueprint do
      identifier :id, name: payload.to_sym
      field payload.to_sym
    end

    expect(unusual.render_as_hash(target.new(1))).to eq(payload.to_sym => 'value')
    expect($blueprinter_view_compiler_injected).to be(false)
  end
end
