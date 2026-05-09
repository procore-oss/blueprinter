# Blueprint Decorator

This example adds metadata to the output of a Blueprint, similar to Legacy/V1's transformer feature.

```ruby
class DecoratorExtension < Blueprinter::Extension
  def initialize(attr, &decorator)
    @attr = attr
    @decorator = decorator
  end

  # @param ctx [Blueprinter::V2::Context::Object]
  def around_blueprint(ctx)
    result = yield ctx
    result[@attr] = @decorator.call(ctx.object)
    result
  end
end
```

Add the extension to whatever blueprints need metadata:

```ruby
class MyBlueprint < ApplicationBlueprint
  add DecoratorExtension.new(:metadata) { |object|
    # extract and return metadata from the object
  }
end
```
