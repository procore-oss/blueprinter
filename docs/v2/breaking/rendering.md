# Breaking Rendering Changes

If you're using Rails' `render json:` you **don't** have to change anything:

```ruby
render json: WidgetBlueprint.render(widget)
```

Otherwise, it now looks like this:

```ruby
# JSON string
WidgetBlueprint.render(widget).to_json

# Hash (or array of Hashes if you passed an Enumerable)
WidgetBlueprint.render(widget).to_hash
```
