# If/unless options

V2's `if` and `unless` options have different Proc arguments than legacy/V1.

You can maintain backwards compatibility using the bundled `LegacyConditionals` extension:

```ruby
class ApplicationBlueprint < Blueprinter::V2::Base
  add Blueprinter::Extensions::LegacyConditionals.new
end
```

`if`/`unless` Procs with three arguments will continue to work like they did in V1:

```ruby
field :a, if: ->(field_name, object, options) { object.active? }
```

## V2 style

V2-style `if`/`unless` Procs will continue to work. They accept a single `Blueprinter::V2::Context::Field` argument:

```ruby
field :a, if: ->(ctx) {
  field_name = ctx.field.source
  object = ctx.object
  options = ctx.options
  object.active?
}
```
