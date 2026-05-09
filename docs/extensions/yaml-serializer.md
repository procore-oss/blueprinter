# YAML Serializer

This example adds YAML to Blueprinter. Why? Because we can.

```ruby
class YamlSerializerExtension < Blueprinter::Extension
  def around_result(ctx)
    case ctx.format
    when :yaml
      # Get the Hash/Array result
      result = yield ctx
      
      # Convert it to YAML
      yaml = YAML.dump result
      
      # Return YAML, declaring it as already serialized
      serialized yaml
    else
      # Let Blueprinter or another extension handle other formats
      yield ctx
    end
  end
end
```

You can serialize to your custom format using the `to` method:

```ruby
MyBlueprint.render(object).to(:yaml)
```

### Extensions that serialize should be added FIRST

When you're adding an extension that adds a serialization format, or replaces the built-it `:json` or `:hash` ones, be sure it's listed **first**.

```ruby
class ApplicationBlueprint < Blueprinter::V2::Base
  add YamlSerializerExtension.new, OtherExtension.new
end
```
