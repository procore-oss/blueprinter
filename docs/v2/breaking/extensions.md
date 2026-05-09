# Breaking Extension Changes

> [!NOTE]
Most applications don't use extensions (yet) and can skip this section.

Legacy/V1 had only one extension hook: `pre_render`. V2's closest analog is `around_result`, which runs once at the beginning of every call to `render`.

Here's an example of an extension that supports both V1 and V2:

```ruby
class MyExtension < Blueprinter::Extension
  # V1 API
  def pre_render(object, blueprint_class, view, options)
    modify(object, blueprint_class, view, options)
  end

  # V2 API
  def around_result(ctx)
    blueprint_class = ctx.blueprint.class
    view = blueprint_class.view_name
    ctx.object = modify(ctx.object, blueprint_class, view, ctx.options)
    yield ctx
  end

  private

  def modify(object, blueprint_class, view, options)
    # return a modified or new object
  end
end
```

See `Blueprinter::Extension` for the full V2 extension API, or read the [Extension Guide](../../extensions/index.md).
