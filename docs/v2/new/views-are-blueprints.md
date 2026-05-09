# Views are Blueprints

In V2, a view is an anonymous subclass of the parent. Practially speaking there is no distinction between a "blueprint" and a "view".

This has two important consequences:

1. The DSL in V2 is *recursive*: views can do anything Blueprints can do.
2. Views in V2 are *Ruby subclasses*: views can do anything Ruby classes can do.

```ruby
class MyBlueprint < ApplicationBlueprint
  options[:exclude_if_nil] = true
  extensions << MyExtension.new
  format Time, :iso8601
  
  fields :name, :description

  # This view is a subclass of MyBlueprint
  view :my_view do
    # Like legacy/V1, views inherit fields from the parent. In V2 they also
    # inherit options, extensions, and formatters.

    # Override a parent's option
    options[:exclude_if_nil] = false

    # Because views are real Ruby subclass of MyBlueprint, they can do
    # anything a Ruby class can do.

    # Include a Module. Only this view (and any child views) will have it.
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
