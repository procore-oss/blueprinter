# Rendering

You can read the full [rendering documentation here](../rendering.md). This page highlights the main differences between V1 and V2.

### Rendering to JSON

If you're using Rails's `render json:`, V2 blueprints should continue to work like Legacy/V1:

```ruby
render json: WidgetBlueprint.render(widget)
```

Otherwise, it now looks like this:

```ruby
WidgetBlueprint.render(widget).to_json
```

### Rendering to Hash

```ruby
WidgetBlueprint.render(widget).to_hash
```

### Views

V2's preferred method of rendering views is:

```ruby
WidgetBlueprint[:extended].render(widget).to_json
```

However, the [ViewOption](../dsl/extensions.md#viewoption) extension can be enabled to allow V1-style view rendering:

```ruby
WidgetBlueprint.render(widget, view: :extended).to_json
```
