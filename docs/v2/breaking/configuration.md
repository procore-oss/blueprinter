# Breaking Configuration Changes

While the previous changes are essentially cosmetic, configuration in V2 uses a completely different paradigm. There is *no global configuration* in V2.
All configuration happens in Blueprints, views, or even in partials.

Because of this approach, different parts of your system can be configured to behave in very different ways. Configuration is inherited from parent
Blueprints and views, and can be overridden in child Blueprints and views.

The following configuration options were previously defined using `Blueprinter.global`. They look different now, and they can be added to any
Blueprint, view, or partial. To make them "global", simply add them to your base Blueprint (e.g. `ApplicationBlueprint`).

### `association_default` / `field_default`

Define the `:default` option in your base Blueprint. It will be passed a `Blueprinter::V2::Context::Field` object, containing the current field,
the current object, and a lot more.

```ruby
options[:default] = ->(ctx) {
  case ctx.field.type
  when :field then "N/A"
  when :object then {}
  when :collection then []
  end
}
```

### `if` / `unless`

Define the `:if` and `:unless` options in your base Blueprint. They will be passed a `Blueprinter::V2::Context::Field` object, containing the
current field, the current object, and a lot more.

```ruby
options[:if] = ->(ctx) {
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

The bundled `Blueprinter::Extensions::LegacyExtractorOption` extension can be enabled to offer backwards-compatibility with legacy/V1's extractors:

```ruby
extensions << Blueprinter::Extensions::LegacyExtractorOption.new

# Can be set on Blueprint/view/partial options or individual fields
options[:extractor] = MyDefaultExtractor
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

Transformers can be implemented using V2s `around_blueprint` extension hook (See `Blueprinter::Extension` for full Extension API docs).

```ruby
class MyTransformer < Blueprinter::Extension
  # @param ctx [Blueprinter::V2::Context::Object]
  def around_blueprint(ctx)
    hash = yield ctx
    hash.transform_keys! { |key| key.to_s.camelize(:lower) }
    hash
  end
end

class ApplicationBlueprint < Blueprinter::V2::Base
  extensions << MyTransformer.new
end
```

### `generator` / `method`

To use a different JSON serializer you can use the `Blueprinter::Extensions::MultiJson` extension. (You'll need the `multi_json` gem installed and
configured).

```ruby
class ApplicationBlueprint < Blueprinter::V2::Base
  # Be sure this is the FIRST extension you add
  extensions << Blueprinter::Extensions::MultiJson.new
end
```

If `multi_json` doesn't support your serializer, you can use the `around_result` extension hook:

```ruby
class MyJsonExtension < Blueprinter::Extension
  def around_result(ctx)
    case ctx.format
    when :json
      # change the format to Hash, get the result, then serialize it
      ctx.format = :hash
      result = yield ctx
      MySerializer.dump result
    else
      # let Blueprinter, or other extensions, handle other formats
      yield ctx
    end
  end
end

class ApplicationBlueprint < Blueprinter::V2::Base
  # Be sure this is the FIRST extension you add
  extensions << Blueprinter::Extensions::MyJsonExtension.new
end
```

### `sort_fields_by`

By default V2 serializes fields in the order they were defined. If you want another order, use the `Blueprinter::Extensions::FieldOrder` extension or
the `around_blueprint_init` extension hook.

The following example will replicate legacy/V1's default field order (alphabetical except _id_ is first):

```ruby
extensions << Blueprinter::Extensions::FieldOrder.new do |a, b|
  if a.name == :id
    -1
  elsif b.name == :id
    1
  else
    a.name <=> b.name
  end
end
```

### `extensions`

Adding extensions is pretty much the same. It just happens inside your base blueprint:

```ruby
extensions << MyExtension.new
```

But the V2 extension _API_ is quite different. See the documentation for `Blueprinter::Extension` or read the [Extension Guide](../../extensions/index.md).
