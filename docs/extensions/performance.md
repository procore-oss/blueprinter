# Performance

Any use of extensions has _some_ performance implications, irrespective of what the extension code is doing. This can range anywhere from "essentially zero" to "noticible". (See `Blueprinter::Extension` for documentation about which hooks are the most and least expensive.)

Given the number of extension hooks available, there are frequently multiple ways to implement a given behavior. Some of these will be more efficient than others.

## Example: Camel case converter

Let's say your source objects store fields in camelCase, but you want to serialize them using snake_case. You could define every field in your Blueprints like this:

```ruby
field :some_field, source: :someField
```

But that's tedious and error-prone. Let's write an extension to do it for us.

### Manually extract each field

The `around_field_value` hook and friends are the simplest way to implement it, by extracting the value ourselves:

```ruby
class CamelCaseExtractor < Blueprinter::Extension
  def initialize
    around_field_value :extract
    around_object_value :extract
    around_collection_value :extract
  end

  # @param ctx [Blueprinter::V2::Context::Field]
  def extract(ctx)
    attr = ctx.field.source_str.camelize
    ctx.object.public_send(attr)
  end
end
```

But what about the performance? These hooks will run for _every field_ on the Blueprint. If you're adding this extension only to specific Blueprints that might be fine.
But what if your entire application needs it? That's a lot of overhead for something so basic.

### Transform each Blueprint's result

The `around_blueprint` hook allows you to intercept and modify the serialized hash output of each Blueprint. If we define our Blueprints in camel case:

```ruby
field :someField
```

Then we can convert the output to snake case:

```ruby
class SnakeCaseTransformer < Blueprinter::Extension
  def initialize
    around_blueprint :transform
  end
  
  # @param ctx [Blueprinter::V2::Context::Object]
  def transform(ctx)
    result = yield ctx
    snake_case result
    result
  end

  def snake_case(hash)
    hash.transform_keys! { |k| k.to_s.underscore }
    hash.each_value { |v| snake_case v if v.is_a? Hash }
  end
end
```

This runs only once per serialized object, so it's a big improvement. But that could still be hundreds of times, or more, in a large result. Can we do better?

### Change field config before render

What if we could alter the field definitions programatically, before anything is serialized? The `around_blueprint_init` hook runs only _once per Blueprint_ during a render. It's quite cheap, and it can alter field definitions.

```ruby
class SourceCamelizer < Blueprinter::Extension
  def initialize
    around_blueprint_init :camelize_sources
  end

  # @param ctx [Blueprinter::V2::Context::Init]
  def camelize_sources(ctx)
    ctx.fields.each do |field|
      # Camelize the `source` attribute of each field
      field.source = field.source_str.camelize(:lower).to_sym
    end
    yield ctx
  end
end
```
