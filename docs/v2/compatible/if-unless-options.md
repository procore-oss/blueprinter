# If/unless options

V2's `if` and `unless` options have different Proc arguments than legacy/V1. If you enable the `LegacyOptions` extension, `if`/`unless` Procs that can accept three arguments will continue to work like they did in V1:

```ruby
field :a, if: ->(field_name, object, options) { object.active? }
field :b, if: ->(field_name, object, options = {}) { object.active? }
```

As in V1, `field_name` is the field's name in the result, which is its `name` option if it has one.

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
