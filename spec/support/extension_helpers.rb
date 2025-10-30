# frozen_string_literal: true

module ExtensionHelpers
  def self.included(klass)
    klass.class_eval do
      subject { described_class.new }

      let(:instances) { Blueprinter::V2::InstanceCache.new }

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

          def was(val, _ctx)
            "was #{val.inspect}"
          end

          def is?(val, expected_val)
            val == expected_val
          end

          def foo?(val, _ctx)
            is? val, 'Foo'
          end

          def name_foo?(val, _ctx)
            val[:name] == 'Foo'
          end

          def names_foo?(val, _ctx)
            val.all? { |v| v[:name] == 'Foo' }
          end
        end
      end
    end
  end

  def prepare(blueprint, options, ctx_type, *args)
    serializer = instances.serializer(blueprint, options, 1)
    ctx = Blueprinter::V2::Context::Render.new(serializer.blueprint, serializer.fields, options, 1)
    subject.around_blueprint_init(ctx) { yield ctx } if subject.respond_to?(:around_blueprint_init)
    ctx_type.new(serializer.blueprint, serializer.fields, options, *args, 1)
  end
end
