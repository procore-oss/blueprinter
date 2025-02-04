# Rendering

### Rendering to JSON

```ruby
WidgetBlueprint.render(widget).to_json
```

You may omit `.to_json` if you're calling `render json:` in a Rails controller:

```ruby
render json: WidgetBlueprint.render(widget)
```

Ruby's built-in `JSON` library is used by default. Alternatively, you can use the built-in [MultiJson extension](./dsl/extensions.md#multijson). Or for total control, implement the [json extension hook](./api/extensions.md#json) and call any serializer you like.

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

### Handling of arrays and array-like objects

By default, `.render` treats the following classes (or their subclasses) as arrays:

- `Array`
- `Set`
- `Enumerator`

You can use the [collection? extension hook](./api/extensions.md#collection) to add support for other array-like classes. For example, [blueprinter-activerecord](https://github.com/procore-oss/blueprinter-activerecord) uses it for `ActiveRecord::Relation`. Alternatively, you can be explicit with `render_object` and `render_collection`:

```ruby
WidgetBlueprint.render_object(widget).to_json

WidgetBlueprint.render_collection(Widget.all).to_json
```
