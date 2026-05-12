# Dynamic options

Associations in legacy/V1 provided an `:options` option on associations. It allowed you to define a Hash or Proc that would be merged into the render options.

It was provided as a work-around when legacy/V1 began freezing options, since options could no longer be used as an arbitrary "store" in field blocks, etc.

In V2 it's provided using the `LegacyDynamicOptions` extension:

```ruby
class WidgetBlueprint < ApplicationBlueprint
  extensions << Blueprinter::Extensions::LegacyDynamicOptions.new
    
  association :category, CategoryBlueprint, options: ->(widget) {
    # Will be merged into `ctx.options`
    { foo: widget.foo }
  }
end
```

## V2 style

V2 provides the `ctx.store` Hash for Blueprints and extensions to share information.

```ruby
class WidgetBlueprint < ApplicationBlueprint
  association :category, CategoryBlueprint do |widget, ctx|
    cxt.store[:foo] = widget.foo
    widget.category
  end
end
```
