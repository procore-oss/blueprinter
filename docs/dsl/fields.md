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

Blueprinter is pretty smart about extracting field values from objects, but there are ways to customize the behavior if needed.

### Default behavior

- For Hashes, Blueprinter will look for a key matching the field name - first with a Symbol, then a String.
- For anything else, Blueprinter will look for a public method matching the field name.
- The [from](./options.md#from) field option can be used to specify a different method or Hash key name.

### Field blocks

Return whatever you want from a block. It will be passed a [Field context](../api/context-objects.md#field-context) argument containing the object being rendered, among other things.

```ruby
field :description do |ctx|
  ctx.object.description.upcase
end

# Blocks can call instance methods defined on your Blueprint
collection :parts, PartBlueprint do |ctx|
  active_parts ctx.object
end

def active_parts(object)
  object.parts.select(&:active?)
end
```

### Custom extractors

Define your own extraction behavior with a [custom extractor](../api/extractors.md).

```ruby
# For an entire Blueprint or view
extensions << MyCustomExtractor.new

# For a single field
object :bar, extractor: MyCustomExtractor
```
