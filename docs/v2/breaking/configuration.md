# Breaking Configuration Changes

Configuration in V2 uses a completely different paradigm. There is *no global configuration* in V2. All configuration happens in Blueprints,
views, or partials by setting options or adding extensions.

Options and extensions are inherited from parent Blueprints and views and can be overridden by their children. This allows different parts of your system
to be configured differently. "Global" configuration should be placed in your application's base Blueprint, e.g. `ApplicationBlueprint`.

Each legacy/V1 global configuration option is listed below, along with its V2 equivalent.

### `association_default` / `field_default`

Set the `:default` option in your base Blueprint. It will be passed a `Blueprinter::V2::Context::Field` object, containing the current field,
the current object, and a lot more.

```ruby
set :default, ->(ctx) {
  case ctx.field.type
  when :field then "N/A"
  when :object then {}
  when :collection then []
  end
}
```

### `if` / `unless`

Set the `:if` and `:unless` options in your base Blueprint. They will be passed a `Blueprinter::V2::Context::Field` object, containing the
current field, the current object, and a lot more.

```ruby
set :if, ->(ctx) {
  # extract the V1 args from ctx
  field_name = ctx.field.source
  object = ctx.object
  options = ctx.options
  # ...
}
```

### `custom_array_like_classes`

V2 doesn't have a direct replacement for this. `render` has sensible heuristics for detecting what's a "collection" or not: any `Enumerable`
except for `Hash`.

If that logic doesn't work for something, use one of these methods in place of `render`:

```ruby
# Force `arg` to be treated like a collection (must respond to `map` with an Enumerable)
array = WidgetBlueprint.render_collection(arg).to_hash
```

```ruby
# Force `arg` to be treated like an object
hash = WidgetBlueprint.render_object(arg).to_hash
```

### `extractor_default`

"Extractors" are not a discrete concept in V2's, but they can be implemented using the `around_field_value`, `around_object_value`, and `around_collection_value`
extension hooks.

The bundled `LegacyExtractorOption` extension can be enabled to offer backwards-compatibility with legacy/V1's extractors:

```ruby
# Add the extension
add Blueprinter::Extensions::LegacyExtractorOption.new

# Set the `extractor` option
set :extractor, MyExtractor
```

### `datetime_format`

Formatting can now be applied to any class. Format dates, times, booleans, or anything else. Define them in your blueprints, views, or partials.

```ruby
# You can define them with blocks
format(TrueClass) { |val| "Y" }
format(FalseClass) { |val| "N" }

# Or with method names
format Date, :iso8601
format Time, :iso8601

def iso8601(val) = val.iso8601
```

See the Documentation for `Blueprinter::V2::DSL#format`.

### `default_transformers`

Transformations can be done using V2's `around_blueprint` extension hook (See `Blueprinter::Extension` for full Extension API docs).

However, the bundled `LegacyTransformer` extension offers compatibility with legacy/V1 transformer classes:

```ruby
add Blueprinter::Extensions::LegacyTransformer.new(
  MyTransformer, OtherTransformer
)
```

### `generator` / `method`

To use a different JSON serializer you can use the `Blueprinter::Extensions::MultiJson` extension. (You'll need the `multi_json` gem installed and
configured).

```ruby
# Be sure this is the FIRST extension you add
add Blueprinter::Extensions::MultiJson.new
```

If `multi_json` doesn't support your serializer, you can use the `around_result` extension hook:

```ruby
class MyJsonExtension < Blueprinter::Extension
  def around_result(ctx)
    case ctx.format
    when :json
      result = yield ctx
      json = MySerializer.dump result
      # The `serialized` helper tells Blueprinter we've already JSONified the result
      serialized json
    else
      yield ctx
    end
  end
end
```

```ruby
class ApplicationBlueprint < Blueprinter::V2::Base
  # Be sure this is the FIRST extension you add
  add MyJsonExtension.new
end
```

### `sort_fields_by`

By default V2 serializes fields in the order they were defined. If you want another order, use the bundled `FieldOrder` extension or
the `around_blueprint_init` extension hook.

The following replicates legacy/V1's default field order of "alphabetical with _id_ first":

```ruby
add Blueprinter::Extensions::FieldOrder.new { |a, b|
  if a.name == :id
    -1
  elsif b.name == :id
    1
  else
    a.name <=> b.name
  end
}
```

### `extensions`

Adding extensions is now done in your Blueprints, views, or partials.

```ruby
add MyExtension.new
```

By default, `add` appends the extension. You can also prepend it:

```ruby
add MyExtensionThatMustBeFirst.new, prepend: true
```

You can remove all extensions of a given class:

```ruby
remove ExtensionIDontWant
```

Or you can remove them all:

```ruby
remove_all
```

#### V2 Extension Hook API

V2 has a completely different, and much more poweful, hook system. Be sure your extension supports the V2 API!

Read [Breaking Extension Changes](./extensions.md), the [Extension Guide](../../extensions/index.md), or the documentation for `Blueprinter::Extension` for more info.
