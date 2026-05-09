# YAML Serializer

This example adds YAML to Blueprinter. Why? Because we can.

```ruby
class YamlSerializerExtension < Blueprinter::Extension
  def around_result(ctx)
    # check if YAML was requested
    case ctx.format
    when :yaml
      # change the format to :hash, get the result, then convert to YAML
      ctx.format = :hash
      result = yield ctx
      YAML.dump result
    else
      # let Blueprinter or another extension handle other formats
      yield ctx
    end
  end
end
```

You can serialize to your custom format using the `to` method:

```ruby
MyBlueprint.render(object).to(:yaml)
```
