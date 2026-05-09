# Exclude If Blank

Here's a more fully formed version of the ExcludeIfBlank extension from the previous section.

It works just like the built-in `exclude_if_nil` option, but checks for `blank?` instead. It checks the Blueprint
options first, then allows fields to override it.

```ruby
class ExcludeIfBlankExtension < Blueprinter::Extension
  def around_field_value(ctx)
    val = yield ctx

    exclude = ctx.blueprint_options[:exclude_if_blank]
    exclude = ctx.field.options[:exclude_if_blank] if ctx.field.options.key? :exclude_if_blank
    skip! if exclude && val.blank?

    val
  end
end
```

Add it to your `ApplicationBlueprint` and use it in your blueprints.

```ruby
class WidgetBlueprint < ApplicationBlueprint
  field :name
  field :description, exclude_if_blank: true
end
```

```ruby
class CategoryBlueprint < ApplicationBlueprint
  options[:exclude_if_blank] = true

  field :name, exclude_if_blank: false
  field :description
end
```
