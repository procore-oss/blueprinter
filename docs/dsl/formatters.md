# Formatters

Declaratively format field values by class. You can define formatters anywhere in your blueprints: top level, [views](./views.md), and [partials](./partials.md).

```ruby
class WidgetBlueprint < ApplicationBlueprint
  # Strip whitespace from all strings
  format(String) { |val| val.strip }

  # Format all dates and times using ISO-8601
  format Date, :iso8601
  format Time, :iso8601

  def iso8601(val)
    val.iso8601
  end
end
```
