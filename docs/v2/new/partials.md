# Partials

Partials allow you to compose your Blueprints and views from reusable pieces.

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

You may only use partials defined in the current Blueprint/view (or a parent). To share code across completely separate Blueprints, use [modules](./modules.md).

See the `Blueprinter::V2::DSL` docs for more info on `partial` and `use`.

### More than just fields

Partials have access to the full DSL, so they can set options, add extensions, formatters, views, and even other partials.

```ruby
class ApplicationBlueprint < Blueprinter::V2::Base
  partial :exclude_nil_or_blank do
    # Enable the built-in "skip if nil" option
    set :exclude_if_nil, true

    # Add an inline extension to skip blank fields
    extension do
      def around_field_value(ctx)
        val = yield ctx
        skip! if val.blank?
        val
      end
    end
  end
end
```

Blueprints or views that use the above partial will skip any nil or blank fields:

```ruby
class MyBlueprint < ApplicationBlueprint
  use :exclude_nil_or_blank
end
```
