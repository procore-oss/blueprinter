# If/unless options

V2 has field-level (and Blueprint/view/partial-level) `if` and `unless` options, but the arguments differ from V1.

You can maintain backwards compatibility with the `LegacyConditionals` extension:

```ruby
class ApplicationBlueprint < Blueprinter::V2::Base
  extensions << Blueprinter::Extensions::LegacyConditionals.new
end
```

`if`/`unless` Procs with three arguments will continue to work like they did in V1:

```ruby
field :a, if: ->(field_name, object, options) { object.active? }
```

## V2 style

To upgrade a Proc to V2-style, have it accept a single `Blueprinter::V2::Context::Field` argument:

```ruby
field :a, if: ->(ctx) {
  field_name = ctx.field.source
  object = ctx.object
  options = ctx.options
  object.active?
}
```
