# YAML Serializer

This example adds YAML to Blueprinter. Why? Because we can.

```ruby
class YamlSerializerExtension < Blueprinter::Extension
  def around_result(ctx)
    case ctx.format
    when :yaml
      # Get the Hash/Array result and convert it to YAML
      result = yield ctx
      yaml = YAML.dump result
      # Return and declare that this serialization is finished
      final yaml
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

When you're adding an extension that adds a serialization format, or replaces the built-it `:json` one, make sure it's added **first**.

```ruby
class ApplicationBlueprint < Blueprinter::V2::Base
  extensions << YamlSerializerExtension.new
  extensions << OtherExtension.new
  # ...
end
```
