# Breaking Extension Changes

Legacy/V1 had only one extension hooks: `pre_render`. V2's closest hook is `around_result`, which runs once at the beginning of every call to `render`.

Here's an example of an extension that supports both V1 and V2:

```ruby
class MyExtension < Blueprinter::Extension
  # V1 API
  def pre_render(object, blueprint, view, options)
    modify(object, blueprint, view, options)
  end

  # V2 API
  def around_result(ctx)
    blueprint = ctx.blueprint.class
    ctx.object = modify(ctx.object, blueprint, blueprint.view_name, ctx.options)
    yield ctx
  end

  private

  def modify(object, blueprint, view, options)
    # return a modified or new object
  end
end
```

See `Blueprinter::Extension` for the full V2 extension API, or read the [Extension Guide](../../extensions/index.md).
