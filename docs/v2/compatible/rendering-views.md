# Rendering views

V2's method of rendering a view is:

```ruby
WidgetBlueprint[:my_view].render(widget).to_json
```

However, with the `LegacyOptions` extension you may continue using V1-style view rendering:

```ruby
WidgetBlueprint.render(widget, view: :my_view).to_json
```

As in V1, the option remains in the options hash that's passed to conditionals, extractors, and field blocks.
