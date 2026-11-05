# Breaking Extension Changes

> [!NOTE]
Most applications don't use extensions (yet) and can skip this section.

Legacy/V1 had only one extension hook: `pre_render`. Depending on what it was doing, V2 has several possible replacements:

* `around_result`: runs once at the beginning of every `render`.
* `around_serialize_object`: runs on every object serialization (`render` and associations).
* `around_serialize_collection`: runs on every collection serialization (`render` and associations).

Here's an example of an extension that supports both V1 and V2:

```ruby
class MyExtension < Blueprinter::Extension
  def initialize
    # Register 'modify_object' as a V2 around_result hook
    around_result :modify_object
  end

  # V2 API
  def modify_object(ctx)
    blueprint_class = ctx.blueprint.class
    view = blueprint_class.view_name
    ctx.object = modify(ctx.object, blueprint_class, view, ctx.options)
    yield ctx
  end
  
  # V1 API
  def pre_render(object, blueprint_class, view, options)
    modify(object, blueprint_class, view, options)
  end

  private

  def modify(object, blueprint_class, view, options)
    # return a modified or new object
  end
end
```

See `Blueprinter::Extension` for the full V2 extension API, or read the [Extension Guide](../../extensions/index.md).
