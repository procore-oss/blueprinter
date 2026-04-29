# Rendering

### Rendering to JSON

If you're using Rails's `render json:`, V2 is backwards-compatible:

```ruby
render json: WidgetBlueprint.render(widget)
```

Otherwise, it now looks like this:

```ruby
WidgetBlueprint.render(widget).to_json
```

### Rendering to Hash

```ruby
WidgetBlueprint.render(widget).to_hash
```

### Views

V2's preferred method of rendering views is:

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
