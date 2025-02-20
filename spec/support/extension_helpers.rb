# frozen_string_literal: true

module ExtensionHelpers
  def self.included(klass)
    klass.class_eval do
      subject { described_class.new }

      let(:sub_blueprint) do
        Class.new(Blueprinter::V2::Base) do
          self.blueprint_name = 'SubBlueprint'
          field :name
        end
      end

      let(:blueprint) do
        test = self
        Class.new(Blueprinter::V2::Base) do
          self.blueprint_name = 'TestBlueprint'
          fields :foo, :bar
          object :foo_obj, test.sub_blueprint
          collection :foos, test.sub_blueprint

          field(:foo2) { |ctx| "value: #{ctx.object[:foo]}" }
          object(:foo_obj2, test.sub_blueprint) { |ctx| { name: "name: #{ctx.object[:foo_obj][:name]}" } }
          collection(:foos2, test.sub_blueprint) { |ctx| [{ name: "nums: #{ctx.object[:foos].map { |x| x[:num] }.map(&:to_s).join(',')}" }] }

          def was(ctx)
            "was #{ctx.value.inspect}"
          end

          def is?(ctx, val)
            ctx.value == val
          end

          def foo?(ctx)
            is? ctx, 'Foo'
          end

          def name_foo?(ctx)
            ctx.value[:name] == 'Foo'
          end

          def names_foo?(ctx)
            ctx.value.all? { |v| v[:name] == 'Foo' }
          end
        end
      end
    end
  end

  def prepare(blueprint, options, ctx_type, *args)
    store = {}
    instances = Blueprinter::V2::InstanceCache.new
    ctx = Blueprinter::V2::Context::Render.new(instances[blueprint], options, instances, store)
    subject.prepare ctx if subject.respond_to?(:prepare)
    ctx_type.new(instances[blueprint], options, instances, store, *args)
  end
end
