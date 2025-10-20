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

      def around_object_value(_ctx)
        @log << 'around_object_value'
        yield
      end

      def around_hook(ctx)
        @log << "around_hook(#{ctx.extension.class.name}##{ctx.hook}): A"
        yield
        @log << "around_hook(#{ctx.extension.class.name}##{ctx.hook}): B"
      end
    end
  end

  it 'creates a blueprinter.object span' do
    ctx = prepare(blueprint, {}, Blueprinter::V2::Context::Object, { foo_obj: { name: 'Bar' } })
    expect_any_instance_of(OpenTelemetry::Internal::ProxyTracer).
      to receive(:in_span).with('blueprinter.object', attributes: { 'blueprint' => ctx.blueprint.class.to_s }.merge(attributes)).and_call_original
    called = subject.around_serialize_object(ctx) { :true }
    expect(called).to eq :true
  end

  it 'creates a blueprinter.collection span' do
    ctx = prepare(blueprint, {}, Blueprinter::V2::Context::Object, { foos: [{ name: 'Bar' }] })
    expect_any_instance_of(OpenTelemetry::Internal::ProxyTracer).
      to receive(:in_span).with('blueprinter.collection', attributes: { 'blueprint' => ctx.blueprint.class.to_s }.merge(attributes)).and_call_original
    called = subject.around_serialize_collection(ctx) { :true }
    expect(called).to eq :true
  end

  it 'creates a blueprinter.extension span with an extension' do
    ctx = prepare(blueprint, {}, Blueprinter::V2::Context::Object, { foos: [{ name: 'Bar' }] })
    expect_any_instance_of(OpenTelemetry::Internal::ProxyTracer).
      to receive(:in_span).with('blueprinter.extension', attributes: { extension: 'MetaExt', hook: :around_field_value }.merge(attributes)).and_call_original
    hook_ctx = Blueprinter::V2::Context::Hook.new(ctx.blueprint, [], ctx.options, meta_extension.new([]), :around_field_value)
    called = subject.around_hook(hook_ctx) { :true }
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
      to receive(:in_span).with('blueprinter.object', attributes: { 'blueprint' => blueprint.to_s }.merge(attributes)).and_call_original
    expect_any_instance_of(OpenTelemetry::Internal::ProxyTracer).
      to receive(:in_span).with('blueprinter.object', attributes: { 'blueprint' => sub_blueprint.to_s }.merge(attributes)).twice.and_call_original
    expect_any_instance_of(OpenTelemetry::Internal::ProxyTracer).
      to receive(:in_span).with('blueprinter.extension', attributes: { extension: 'MetaExt', hook: :around_object_value }.merge(attributes)).twice.and_call_original
    expect_any_instance_of(OpenTelemetry::Internal::ProxyTracer).
      to receive(:in_span).with('blueprinter.collection', attributes: { 'blueprint' => sub_blueprint.to_s }.merge(attributes)).twice.and_call_original
    blueprint.render(object).to_hash
  end
end
