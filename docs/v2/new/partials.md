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

Partials are inherited from parent Blueprints and views, but they may also be defined in Ruby modules.
Blueprints, views, or other partials can include the module to get access to its partials.

```ruby
module MySharedPartials
  extend Blueprinter::V2::DSL

  partial :my_partial do
    # ...
  end
end

class MyBlueprint < ApplicationBlueprint
  include MySharedPartials

  use :my_partial
  # ...
end
```

### More than just fields

Partials have access to the full DSL, so they can set options, add extensions, formatters, views, and even other partials.

```ruby
class ApplicationBlueprint < Blueprinter::V2::Base
  partial :exclude_nil_or_blank do
    # Enable the built-in "skip if nil" option
    set :exclude_if_nil, true

    # Enable an extension for skipping blank fields
    add ExcludeIfBlank.new
  end
end
```

Blueprints or views that use the above partial will skip any nil or blank fields:

```ruby
class MyBlueprint < ApplicationBlueprint
  use :exclude_nil_or_blank
end
```

See the `Blueprinter::V2::DSL` docs for more info on `partial` and `use`.
