# Rendering

`render` returns a JSON string by default, just like V1:

```ruby
WidgetBlueprint.render(widget)
```

To get a Hash instead, use the `:format` option:

```ruby
WidgetBlueprint.render(widget, format: :hash)
```

To get a Hash with string keys, use `:format` followed by `as_json`:

```ruby
WidgetBlueprint.render(widget, format: :hash).as_json
```

> [!NOTE]
The legacy `render_as_hash` and `render_as_json` methods are still available but are no longer the preferred approach.

## Views

V2's method of rendering a view is:

```ruby
WidgetBlueprint[:my_view].render(widget)
```

However, with the `LegacyOptions` extension you may continue using V1-style view rendering:

```ruby
WidgetBlueprint.render(widget, view: :my_view)
```
