# Rendering views

V2's method of rendering a view is:

```ruby
WidgetBlueprint[:my_view].render(widget).to_json
```

However, the included `ViewOption` extension can be enabled to allow V1-style view rendering:

```ruby
class ApplicationBlueprint < Blueprinter::V2::Base
  extensions << Blueprinter::Extensions::ViewOption.new
end

WidgetBlueprint.render(widget, view: :my_view).to_json
```
