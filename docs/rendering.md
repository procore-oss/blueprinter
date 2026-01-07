# Rendering

### Rendering to JSON

```ruby
WidgetBlueprint.render(widget).to_json
```

If you're using Rails, you may omit `.to_json` when calling `render json:`

```ruby
render json: WidgetBlueprint.render(widget)
```

Ruby's built-in `JSON` library is used by default. Alternatively, you can use the built-in [MultiJson extension](./dsl/extensions.md#multijson). Or for total control, implement the [around_result](./api/extensions.md#around_result) and call any serializer you like.

### Rendering to a Hash

```ruby
WidgetBlueprint.render(widget).to_hash
```

### Rendering a view

```ruby
# Render a view
WidgetBlueprint[:extended].render(widget).to_json

# Render a nested view
WidgetBlueprint["extended.price"].render(widget).to_json

# These two both render the default view
WidgetBlueprint.render(widget).to_json
WidgetBlueprint[:default].render(widget).to_json
```

### Passing options

An options hash can be passed to `render`. Read more about [options](./dsl/options.md).

```ruby
WidgetBlueprint.render(Widget.all, exclude_if_nil: true).to_json
```

### Rendering collections

`render` will treat any `Enumerable`, except `Hash`, as an array of objects:

```ruby
WidgetBlueprint.render(Widget.all).to_json
```

If you wish to be explicit you may use `render_object` and `render_collection`:

```ruby
WidgetBlueprint.render_object(widget).to_json

WidgetBlueprint.render_collection(Widget.all).to_json
```

Whatever you pass to `render_collection` must respond to `map`, yielding zero or more serializable objects, and returning an `Enumerable` with the mapped results.
