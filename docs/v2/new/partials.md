# Partials

Blueprinter V2's partials allow you to define collections of fields, etc. to be used across multiple views.

```ruby
class MyBlueprint < ApplicationBlueprint
  view :view_1 do
    use :common_associations
    # ...
  end

  view :view_2 do
    use :common_associations
    # ...
  end
  
  partial :common_associations do
    association :foo, FooBlueprint
    association :bar, [BarBlueprint]
  end
end
```

See the `Blueprinter::V2::DSL` docs for more info on `partial`, `use`, and `use!`.

### More than just fields

Partials have access to the full DSL, so they can define options, extensions, formatters, views, and even other partials.

```ruby
class ApplicationBlueprint < Blueprinter::V2::Base
  # This partial will exclude any nil or blank values
  partial :exclude_nil_or_blank do
    options[:exclude_if_nil] = true

    # An inline extension that skips blank fields
    extension do
      def around_field_value(ctx)
        val = yield ctx
        skip! if val.blank?
        val
      end
      alias_method :around_object_value, :around_field_value
      alias_method :around_collection_value, :around_field_value
    end
  end
end

class MyBlueprint < ApplicationBlueprint
  # Child blueprints can opt into this behavior with a single line
  use :exclude_nil_or_blank
end
```
