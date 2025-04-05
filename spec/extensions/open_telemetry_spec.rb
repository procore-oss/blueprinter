# frozen_string_literal: true

require 'opentelemetry/sdk'

describe Blueprinter::Extensions::OpenTelemetry do
  include ExtensionHelpers

  subject { described_class.new('test') }
  let(:trace_id) { OpenTelemetry::Trace.generate_trace_id }
  let(:span_id) { OpenTelemetry::Trace.generate_span_id }
  let(:attributes) { { 'library.name' => 'Blueprinter', 'library.version' => Blueprinter::VERSION } }
  let(:meta_extension) do
    Class.new(Blueprinter::Extension) do
      def self.name = 'MetaExt'

      def initialize(log) = @log = log

      def object_value(ctx)
        @log << 'object_value'
        ctx.value
      end

      def around_hook(ext, hook)
        @log << "around_hook(#{ext.class.name}##{hook}): A"
        yield
        @log << "around_hook(#{ext.class.name}##{hook}): B"
      end
    end
  end

  it 'creates a blueprinter.render span for objects' do
    ctx = prepare(blueprint, {}, Blueprinter::V2::Context::Object, { name: 'Foo' })
    expect_any_instance_of(OpenTelemetry::Internal::ProxyTracer).
      to receive(:in_span).with('blueprinter.render', attributes: { 'blueprint' => ctx.blueprint.class.to_s }.merge(attributes)).and_call_original
    called = subject.around_object_render(ctx) { :true }
    expect(called).to eq :true
  end

  it 'creates a blueprinter.render span for collections' do
    ctx = prepare(blueprint, {}, Blueprinter::V2::Context::Object, [{ name: 'Foo' }])
    expect_any_instance_of(OpenTelemetry::Internal::ProxyTracer).
      to receive(:in_span).with('blueprinter.render', attributes: { 'blueprint' => ctx.blueprint.class.to_s }.merge(attributes)).and_call_original
    called = subject.around_collection_render(ctx) { :true }
    expect(called).to eq :true
  end

  it 'creates a blueprinter.object span' do
    ctx = prepare(blueprint, {}, Blueprinter::V2::Context::Object, { foo_obj: { name: 'Bar' } })
    expect_any_instance_of(OpenTelemetry::Internal::ProxyTracer).
      to receive(:in_span).with('blueprinter.object', attributes: { 'blueprint' => ctx.blueprint.class.to_s }.merge(attributes)).and_call_original
    called = subject.around_object_serialization(ctx) { :true }
    expect(called).to eq :true
  end

  it 'creates a blueprinter.collection span' do
    ctx = prepare(blueprint, {}, Blueprinter::V2::Context::Object, { foos: [{ name: 'Bar' }] })
    expect_any_instance_of(OpenTelemetry::Internal::ProxyTracer).
      to receive(:in_span).with('blueprinter.collection', attributes: { 'blueprint' => ctx.blueprint.class.to_s }.merge(attributes)).and_call_original
    called = subject.around_collection_serialization(ctx) { :true }
    expect(called).to eq :true
  end

  it 'creates a blueprinter.extension span with an extension' do
    ctx = prepare(blueprint, {}, Blueprinter::V2::Context::Object, { foos: [{ name: 'Bar' }] })
    expect_any_instance_of(OpenTelemetry::Internal::ProxyTracer).
      to receive(:in_span).with('blueprinter.extension', attributes: { extension: 'MetaExt', hook: :field_value }.merge(attributes)).and_call_original
    called = subject.around_hook(meta_extension.new([]), :field_value) { :true }
    expect(called).to eq :true
  end

  it 'fires during render' do
    log = []
    meta_ext = meta_extension.new(log)
    blueprint.extensions << subject << meta_ext
    sub_blueprint.extensions << subject << meta_ext
    attributes = { 'library.name' => 'Blueprinter', 'library.version' => Blueprinter::VERSION }
    object = { foo: 'Foo', foo_obj: { name: 'Bar1' }, foos: [{ name: 'Bar2' }] }
    expect_any_instance_of(OpenTelemetry::Internal::ProxyTracer).
      to receive(:in_span).with('blueprinter.render', attributes: { 'blueprint' => blueprint.to_s }.merge(attributes)).and_call_original
    expect_any_instance_of(OpenTelemetry::Internal::ProxyTracer).
      to receive(:in_span).with('blueprinter.object', attributes: { 'blueprint' => blueprint.to_s }.merge(attributes)).and_call_original
    expect_any_instance_of(OpenTelemetry::Internal::ProxyTracer).
      to receive(:in_span).with('blueprinter.object', attributes: { 'blueprint' => sub_blueprint.to_s }.merge(attributes)).twice.and_call_original
    expect_any_instance_of(OpenTelemetry::Internal::ProxyTracer).
      to receive(:in_span).with('blueprinter.extension', attributes: { extension: 'MetaExt', hook: :object_value }.merge(attributes)).twice.and_call_original
    expect_any_instance_of(OpenTelemetry::Internal::ProxyTracer).
      to receive(:in_span).with('blueprinter.collection', attributes: { 'blueprint' => sub_blueprint.to_s }.merge(attributes)).twice.and_call_original
    blueprint.render(object).to_hash
  end
end
