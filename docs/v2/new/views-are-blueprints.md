# Views are Blueprints

A view is an anonymous subclass of its Blueprint. There is little practical or technical distinction between "blueprints" and "views".

This has two important consequences:

1. The DSL is *recursive*: views can do anything Blueprints can do.
2. Views are *Ruby classes*: views can do anything Ruby classes can do.

```ruby
class MyBlueprint < ApplicationBlueprint
  set :exclude_if_nil, true
  add MyExtension.new
  format Time, :iso8601
  
  fields :name, :description

  # This view is a subclass of MyBlueprint
  view :my_view do
    # Override inherited options
    set :exclude_if_nil, false

    # Add an extension
    add OtherExtension.new

    # Include a Ruby module. Only this view (and any child views) will have it.
    include MyHelpers

    # Override the formatter's method to ensure UTC time
    def iso8601(t) = t.utc.iso8601
  end

  def iso8601(t) = t.iso8601
end
```

You can even subclass another Blueprint's view!

```ruby
class FooBlueprint < MyBlueprint[:my_view] do
  # ...
end
```

### The default view

The *default* view is simply an alias to the class:

```ruby
MyBlueprint == MyBlueprint[:default]
=> true
```

And since views are their own Blueprints, each view has its own default view:

```ruby
MyBlueprint[:my_view] == MyBlueprint[:my_view][:default]
=> true
```

Which brings us to the next topic: [Nested Views](./nested-views.md).
