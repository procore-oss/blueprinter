# If/unless options

V2's `if` and `unless` options have different Proc arguments than legacy/V1. If you enable the `LegacyOptions` extension, `if`/`unless` Procs that can accept three arguments will continue to work like they did in V1:

```ruby
field :a, if: ->(field_name, object, options) { object.active? }
field :b, if: ->(field_name, object, options = {}) { object.active? }
```

Method names (Symbols or Strings) also keep working. As in V1, they refer to *class* methods that accept the same three arguments, including private ones:

```ruby
class WidgetBlueprint < ApplicationBlueprint
  field :a, if: :active?
  field :b, unless: :hidden?

  def self.active?(field_name, object, options) = object.active?

  def self.hidden?(field_name, object, options = {}) = object.hidden?
end
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

V2 method names refer to *public instance* methods that take the same single argument:

```ruby
class WidgetBlueprint < ApplicationBlueprint
  field :a, if: :active?
  field :b, unless: :hidden?

  def active?(ctx) = ctx.object.active?

  def hidden?(ctx) = ctx.object.hidden?
end
```
