# Extensions

The V2 extension API is vastly more powerful than V1's single experimental extension hook. See the documentation for `Blueprinter::Extension`.

## Porting pre_render

V1's `pre_render` hook allowed you to modify the input object. The closest analog in V2 is `around_render` which can be used modify the input object or collection, the options passed to render, and the final output.

```ruby
class MyExtension < Blueprinter::Extension
  def around_result(ctx)
    ctx.object = modify object
    yield ctx
  end
end
```
