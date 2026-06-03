# Modules

Any Ruby module can be extended with the Blueprinter DSL:

```ruby
module MySharedBlueprintCode
  extend Blueprinter::V2::DSL

  set :exclude_if_nil, true
  add MyExtension.new
  
  format Time, :iso8601
  format Date, :iso8601

  field :foo

  view :full do
    association :bar, BarBlueprint
  end

  def iso8601(val) = val.iso8601
end
```

Then included into Blueprints:

```ruby
class MyBlueprint < ApplicationBlueprint
  include MySharedBlueprintCode

  # ...
end
```

Or views:

```ruby
class MyBlueprint < ApplicationBlueprint
  # ...

  view :my_view do
    include MySharedBlueprintCode
    
    # ...
  end
end
```
