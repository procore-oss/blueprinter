# Blueprint Decorator

This example adds metadata to the output of a Blueprint, similar to Legacy/V1's transformer feature.

```ruby
class DecoratorExtension < Blueprinter::Extension
  def initialize(attr, &decorator)
    @attr = attr
    @decorator = decorator
  end
  
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
  extensions << DecoratorExtension.new(:metadata) do |object|
    # extract and return metadata from the object
  end
end
```
