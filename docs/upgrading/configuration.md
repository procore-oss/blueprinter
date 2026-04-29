# Configuration

Blueprinter Legacy/V1 had a single source of configuration: the global `Blueprinter.configure` block. V2 takes a very different approach with _zero
global configuration_.

In V2, all configuration is handled by the Blueprinter classes themselves, or by their views. Global configuration can be replicated by defining
a base Blueprint for your application and putting anything "global" into it:

```ruby
class ApplicationBlueprint < Blueprinter::V2::Base
  options[:exclude_if_nil] = true
  extensions << MyExtension.new
  format Date, :iso8601
  format Time, :iso8601

  def iso8601(t) = t.iso8601
end
```

This has the advantage of allowing overrides in child Blueprints, views, or even partials.

```ruby
class MyBlueprint < ApplicationBlueprint
  options[:exclude_if_nil] = false

  view :foo do
    options.clear
    
    # Ensure this view always represents time in UTC
    format(Time) { |t| iso8601 t.utc }
  end
end
```
