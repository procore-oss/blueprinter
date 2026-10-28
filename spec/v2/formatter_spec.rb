# frozen_string_literal: true

require 'date'

describe Blueprinter::V2::Formatter do
  let(:blueprint) do
    Class.new(Blueprinter::V2::Base) do
      format(Date) { |date| date.iso8601 }
      format TrueClass, :yes
      format(Numeric) { |n| "num #{n}" }
      format(Integer) { |n| "int #{n}" }
      format(Comparable) { |x| "cmp #{x}" }

      def yes(_)
        "Yes"
      end
    end
  end

  let(:formatter) do
    blueprint.reflections
    described_class.new(blueprint.spec.formatters)
  end

  it 'calls proc formatters' do
    value = Date.new(2024, 10, 1)
    expect(formatter.call(blueprint.new, value)).to eq '2024-10-01'
  end

  it 'calls instance method formatters' do
    value = true
    expect(formatter.call(blueprint.new, value)).to eq "Yes"
  end

  it "passes through values it doesn't know about" do
    value = { foo: 1 }
    expect(formatter.call(blueprint.new, value)).to eq({ foo: 1 })
    expect(formatter.call(blueprint.new, nil)).to be_nil
  end

  it 'uses formatters for parent classes' do
    value = DateTime.new(2024, 10, 1, 12, 30)
    expect(formatter.call(blueprint.new, value)).to eq '2024-10-01T12:30:00+00:00'
    expect(formatter.call(blueprint.new, 1.5)).to eq 'num 1.5'
  end

  it 'uses formatters for included modules' do
    expect(formatter.call(blueprint.new, "foo")).to eq "cmp foo"
  end

  it 'uses the nearest ancestor' do
    parent = Class.new
    child = Class.new(parent)
    grandchild = Class.new(child)
    blueprint.format(parent) { |_| 'parent' }
    blueprint.format(child) { |_| 'child' }

    expect(formatter.call(blueprint.new, 42)).to eq 'int 42'
    expect(formatter.call(blueprint.new, grandchild.new)).to eq 'child'
    expect(formatter.call(blueprint.new, parent.new)).to eq 'parent'
  end

  it 'caches lookups, including misses' do
    blueprint_instance = blueprint.new
    expect(DateTime).to receive(:ancestors).once.and_call_original
    expect(Hash).to receive(:ancestors).once.and_call_original
    3.times do
      expect(formatter.call(blueprint_instance, DateTime.new(2024, 10, 1))).to eq '2024-10-01T00:00:00+00:00'
      expect(formatter.call(blueprint_instance, { foo: 1 })).to eq({ foo: 1 })
    end
  end

  it "doesn't look up ancestors for exact matches" do
    expect(Date).not_to receive(:ancestors)
    expect(formatter.call(blueprint.new, Date.new(2024, 10, 1))).to eq '2024-10-01'
  end

  it "doesn't cache anonymous classes, which it would keep alive forever" do
    blueprint_instance = blueprint.new
    100.times { formatter.call(blueprint_instance, Class.new(Date).new(2024, 10, 1)) }
    expect(cache_size).to eq blueprint.spec.formatters.size
  end

  it 'stops caching at CACHE_LIMIT' do
    blueprint_instance = blueprint.new
    stub_const "#{described_class}::CACHE_LIMIT", 10
    20.times do |i|
      klass = Class.new(Date)
      Object.const_set :"FormatterSpecDate#{i}", klass
      expect(formatter.call(blueprint_instance, klass.new(2024, 10, 1))).to eq '2024-10-01'
    end
    expect(cache_size).to eq 10
  ensure
    20.times { |i| Object.send :remove_const, :"FormatterSpecDate#{i}" }
  end

  it 'never exposes a partially built cache to other threads' do
    blueprint_instance = blueprint.new
    results = 4.times.map do
      Thread.new do
        200.times.map { formatter.call(blueprint_instance, DateTime.new(2024, 10, 1)) }
      end
    end.flat_map(&:value)

    expect(results.uniq).to eq ['2024-10-01T00:00:00+00:00']
  end

  def cache_size = formatter.instance_variable_get(:@cache).size
end
