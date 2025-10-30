# Extensions

Blueprinter has a powerful middleware-based extension system with hooks for every step of the serialization lifecycle. In fact, many of Blueprinter's features are implemented using the extension API!

Simply extend the `Blueprinter::Extension` class, define the hooks you need, and [add it to your configuration](../dsl/extensions.md#using-extensions).

## Hooks

Hooks are called in the following order. They are passed a [context object](./context-objects.md) as an argument.

<div class="hooks"><a href="#around_result">around_result</a>
  <a href="#around_blueprint_init">around_blueprint_init</a>
    <a href="#around_serialize_object">around_serialize_object</a> | <a href="#around_serialize_collection">around_serialize_collection</a>
      <a href="#around_blueprint">around_blueprint</a>
        <a href="#around_field_value">around_field_value</a> | <a href="#around_object_value">around_object_value</a> | <a href="#around_collection_value">around_collection_value</a>
          <a href="#around_blueprint_init">around_blueprint_init...</a>
</div>

Additionally, the [around_hook](#around_hook) hook runs around all other hooks.

### around_result

> **param** [Result Context](./context-objects.md#result-context) \
> **return** result \
> **cost** Low - run once during render

The `around_result` hook runs around the entire serialization process, allowing you to modify the initial input and final output.

The following example hook caches an entire result for five minutes.

```ruby
def around_result(ctx)
  cache(ctx.blueprint.class, ctx.object, ctx.format, ttl: 300) do
    yield ctx
  end
end
```

#### Finalizing

The `final` and `final?` helpers allow middleware to declare, and check if, a result is "finalized" and should no longer be altered. These helpers should **only** be used in `around_result`.

```ruby
def around_result(ctx)
  result = yield ctx
  return result if final? result

  result = somehow_modify result
  final result
end
```

### around_blueprint_init

> **param** [Render Context](./context-objects.md#render-context) \
> **cost** Low - run once per used blueprint during render

The `around_blueprint_init` hook runs the first time a new Blueprint is used during a render cycle. It can be used by extensions to perform time-saving setup before a render.

```ruby
def around_blueprint_init(ctx)
  perform_setup ctx.blueprint, ctx.options
  yield ctx
end
```

`around_blueprint_init` MUST yield, otherwise a `Blueprinter::Errors::ExtensionHook` will be raised.

### around_serialize_object

> **param** [Object Context](./context-objects.md#object-context) \
> **return** result \
> **cost** Medium - run every time any blueprint is rendered

The `around_serialize_object` hook runs around every object (as opposed to collection) that's serialized. The following example would see it called **four** times: once for the category itself and once for each item.

```ruby
CategoryBlueprint.render({
  name: "Foo",
  items: [item1, item2, item3],
}).to_json
```

The following example hook modifies both the input object and the output result.

```ruby
def around_serialize_object(ctx)
  # modify the object before it's serialized
  ctx.object = modify ctx.object

  result = yield ctx

  # modify the result
  result.merge({ foo: "Bar" })
end
```

### around_serialize_collection

> **param** [Object Context](./context-objects.md#object-context) \
> **return** result \
> **cost** Medium - run every time any blueprint is rendered

The `around_serialize_collection` hook runs around every collection that's serialized. The following example would see it called three times: once for the array of categories and once for each set of items.

```ruby
CategoryBlueprint.render([
  { name: "Foo", items: [item1] },
  { name: "Bar", items: [item2, item3] },
]).to_json
```

The following example hook modifies both the input collection and the output results.

```ruby
def around_serialize_collection(ctx)
  # modify the collection before it's serialized
  ctx.object = modify ctx.object

  result = yield ctx

  # modify the result
  result.reject { |obj| some_logic obj }
end
```

### around_blueprint

> **param** [Object Context](./context-objects.md#object-context) \
> **return** result \
> **cost** Medium - run every time any blueprint is rendered

The `around_blueprint` hook runs every time an object, including members of collections, are serialized. The following example would see it called three times: once for the category and once for each item.

```ruby
CategoryBlueprint.render({ name: "Foo", items: [item1, item] }).to_json
```

The following example hook modifies both the input object and the output result.

```ruby
def around_blueprint(ctx)
  # modify the object before it's serialized
  ctx.object = modify ctx.object

  result = yield ctx

  # modify the result
  result.merge({ foo: "Bar" })
end
```

### around_field_value

> **param** [Field Context](./context-objects.md#field-context) \
> **return** result \
> **cost** High - run for every (non-object, non-collection) field

The `around_field_value` hook runs around every non-object, non-collection field that's extracted. The following example trims leading and trailing whitespace from string values.

```ruby
def around_field_value(ctx)
  val = yield ctx
  case val
  when String then val.strip
  else val
  end
end
```

#### Skipping fields

You can tell blueprinter to completely skip a field using `skip`. It will bail out of the hook and any previous hooks that yielded.

```ruby
def around_field_value(ctx)
  val = yield ctx
  skip if ctx.field.options[:skip_on] == val
  val
end
```

### around_object_value

> **param** [Field Context](./context-objects.md#field-context) \
> **return** result \
> **cost** High - run for every object field

The `around_object_value` hook runs around every object field that's extracted (before it's serialized with a Blueprint). The following example adds a `foo` attribute to each object Hash.

```ruby
def around_object_value(ctx)
  val = yield ctx
  case val
  when Hash then val.merge({ foo: "bar" })
  else val
  end
end
```

#### Skipping fields

You can tell blueprinter to completely skip a field using `skip`. It will bail out of the hook and any previous hooks that yielded.

```ruby
def around_object_value(ctx)
  val = yield ctx
  skip if ctx.field.options[:skip_on] == val
  val
end
```

### around_collection_value

> **param** [Field Context](./context-objects.md#field-context) \
> **return** result \
> **cost** High - run for every collection field

The `around_collection_value` hook runs around every collection field that's extracted (before it's serialized with a Blueprint). The following example removes deleted widgets from a collection.

```ruby
def around_collection_value(ctx)
  val = yield ctx
  case ctx.field.blueprint
  when WidgetBlueprint
    val.reject { |widget| widget.deleted? }
  else
    val
  end
end
```

#### Skipping fields

You can tell blueprinter to completely skip a field using `skip`. It will bail out of the hook and any previous hooks that yielded.

```ruby
def around_collection_value(ctx)
  val = yield ctx
  skip if ctx.field.options[:skip_on] == val
  val
end
```

### around_hook

> **param** [Hook Context](./context-objects.md#hook-context) \
> **cost** Variable - runs around all your extensions

The `around_hook` hook runs around all other extension hooks. It **must** yield, otherwise a `Blueprinter::Errors::ExtensionHook` will be raised. The return value from `yield` is **not** used, nor is the return value of `around_hook`.

```ruby
def around_hook(ctx)
  # do something
  yield
  # do something else
end
```
