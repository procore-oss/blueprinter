# Fields

```ruby
# Use field for scalar values, arrays of scalar values, or even a Hash
field :name
field :tags

# Add multiple fields at once
fields :description, :price

# Use object to render an object or Hash using another blueprint
object :category, CategoryBlueprint

# Use collection to render an array-like collection of objects
collection :parts, PartBlueprint
```

## Options

Fields accept a wide array of built-in options, and [extensions](./extensions.md) can define even more. [Find all built-in options here.](./options.md)

```ruby
field :description, default: "No description"
collection :parts, PartBlueprint, exclude_if_empty: true
```

## Extracting field values

Blueprinter is pretty smart about extracting field values from objects and Hashes, but there are ways to customize the behavior if needed.

### Default behavior

- For Hashes, Blueprinter will look for a key matching the field name - first with a Symbol, then a String.
- For anything else, Blueprinter will look for a public method matching the field name.
- The [from](./options.md#from) field option can be used to specify a different method name or Hash key.

### Field blocks

If you pass a block to your field, the default behavior will be bypassed and the block's return value will be used. It will be passed the current object and a [Field context](../api/context-objects.md#field-context) object.

```ruby
field :description do |object, ctx|
  object.description.upcase
end

# Blocks can call instance methods defined on your Blueprint
collection :parts, PartBlueprint do |object, ctx|
  active_parts object
end

def active_parts(object)
  object.parts.select(&:active?)
end
```

### Extracting with extensions

The [around_field_value](../api/extensions.md#around_field_value), [around_object_value](../api/extensions.md#around_object_value), and [around_collection_value](../api/extensions.md#around_collection_value) middleware hooks can intercept extraction and return whatever values they want. [Learn more about using extensions](./extensions.md).

```ruby
class MyExtractor < Blueprinter::Extension
  def around_field_value(ctx)
    if ctx.field.options[:my_extractor] || ctx.blueprint.class.options[:my_extractor]
      # If the field or blueprint has the "my_extractor" option, use custom extraction
      my_custom_extraction(ctx.object, ctx.field)
    else
      # Otherwise use the default behavior
      yield ctx
    end
  end

  private

  def my_custom_extraction(object, field)
    # ...
  end
end
```
