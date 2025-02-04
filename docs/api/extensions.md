# Extensions

Blueprinter has a powerful extension system with hooks for every step of the serialization lifecycle. In fact, many of Blueprinter's features are implemented as built-in extensions!

Simply extend the `Blueprinter::Extension` class, define the hooks you need, and [add it to your configuration](../dsl/extensions.md#using-extensions).

```ruby
class MyExtension < Blueprinter::Extension
  # Use the exclude_field? hook to exclude certain fields on Tuesdays
  def exclude_field?(ctx) = ctx.field.options[:tues] == false && Date.today.tuesday?
end

class MyBlueprint < ApplicationBlueprint
  extensions << MyExtension.new
end
```

Alternatively, you can define an extension direclty in your blueprint:

```ruby
class MyBlueprint < ApplicationBlueprint
  extension do
    def exclude_field?(ctx) = ctx.field.options[:tues] == false && Date.today.tuesday?
  end
end
```

## Hooks

Hooks are called in the following order. Most are passed a [context object](./context-objects.md) as an argument.

- [around_object_render](#around_object_render) | [around_collection_render](#around_collection_render)
  - [input_object](#input_object) | [input_collection](#input_collection)
  - [around_object_serialization](#around_object_serialization) | [around_collection_serialization](#around_collection_serialization)
    - [blueprint_fields](#blueprint_fields)
    - [prepare](#prepare)
    - [blueprint_input](#blueprint_input)
    - [extract_value](#extract_value)
    - [field_value](#field_value) | [object_value](#object_value) | [collection_value](#collection_value)
    - [exclude_field?](#exclude_field) | [exclude_object?](#exclude_object) | [exclude_collection?](#exclude_collection)
    - [blueprint_output](#blueprint_output)
  - [output_object](#output_object) | [output_collection](#output_collection)
  - [json](#json)

Additionally, the [around_hook](#around_hook) hook runs around all other hooks.

## around_object_render

> **@param [Object Context](./context-objects.md#object-context)** `context.object` will contain the top-level object being rendered\
> **@cost** Low - run exactly once per render

Wraps the entire rendering process of objects. Rendering happens during `yield`, allowing the hook to run code before and after the render. If `yield` is not called exactly one time, a `BlueprinterError` is thrown.

```ruby
def around_object_render(ctx)
  # do something before render
  yield # render
  # do something after render
end
```

## around_collection_render

> **@param [Object Context](./context-objects.md#object-context)** `context.object` will contain the top-level collection being rendered\
> **@cost** Low - run exactly once per render

Wraps the entire rendering process of collections. Rendering happens during `yield`, allowing the hook to run code before and after the render. If `yield` is not called exactly one time, a `BlueprinterError` is thrown.

```ruby
def around_collection_render(ctx)
  # do something before render
  yield # render
  # do something after render
end
```

## input_object

> **@param [Object Context](./context-objects.md#object-context)** `context.object` will contain the top-level object being rendered\
> **@return Object** A new or modified version of `context.object`\
> **@cost** Low - run exactly once per render

Run when `render` is called with a non-collection object, or when `render_object` is called. This hook allows you to modify or replace the object (`context.object`) before rendering. **Whatever object is returned will be used as context.object in subsequent hooks, then rendered.**

```ruby
def input_object(ctx)
  ctx.object
end
```

## input_collection

> **@param [Object Context](./context-objects.md#object-context)** `context.object` will contain the top-level collection being rendered\
> **@return Object** A new or modified version of `context.object`, which will be array-like\
> **@cost** Low - run exactly once per render

Run when `render` is called with a collection object, or when `render_collection` is called. This hook allows you to modify the array-like object (`context.object`) before rendering, or even return a new one. **Whatever collection is returned will be used as context.object in subsequent hooks, then rendered.**

```ruby
def input_collection(ctx)
  ctx.object
end
```

## around_object_serialization

> **@param [Object Context](./context-objects.md#object-context)** `context.object` will contain the current object being rendered\
> **@cost** Medium - run every time any blueprint is rendered

Wraps the rendering of every object (`context.object`). This could be the top-level object or one from an association N levels deep.

Rendering happens during `yield`, allowing the hook to run code before and after the render. If `yield` is not called exactly one time, a `BlueprinterError` is thrown.

```ruby
def around_object_serialization(ctx)
  # do something before render
  yield # render
  # do something after render
end
```

## around_collection_serialization

> **@param [Object Context](./context-objects.md#object-context)** `context.object` will contain the current collection being rendered\
> **@cost** Medium - run every time any blueprint is rendered

Wraps the rendering of every collection (`context.object`). This could be the top-level collection or one from an association N levels deep.

Rendering happens during `yield`, allowing the hook to run code before and after the render. If `yield` is not called exactly one time, a `BlueprinterError` is thrown.

```ruby
def around_collection_serialization(ctx)
  # do something before render
  yield # render
  # do something after render
end
```

## blueprint_fields

> **@param [Render Context](./context-objects.md#render-context)**\
> **@cost** Low - run once for _every blueprint class_ during render

Customize the order fields are rendered in - or strip out certain fields entirely. If multiple extensions define this hook, _only the last one_ will be used. The included, optional [Field Order extension](../dsl/extensions.md#field-order) uses this hook.

The default behavior is to render all fields in the order they were defined. The following example uses the [Reflection API](./reflection.md) to get the fields from the current view, then sort them by name:

```ruby
def blueprint_fields(ctx)
  ref = ctx.blueprint.class.reflections[:default]
  ref.ordered.sort_by(&:name)
end
```

It's run once _per blueprint class_ during a render. So if you're rendering an array of widgets with `WidgetBlueprint`, which contains `PartBlueprint`s and `CategoryBlueprint`s, this hook will be called **three** times: one for each of those blueprints.

## prepare

> **@param [Render Context](./context-objects.md#render-context)**\
> **@cost** Low - run once for _every blueprint class_ during render

Allows an extension to perform setup operations for the render of the current blueprint. `context.store` is a good place to cache data since it is shared across all hooks and extensions during a given render.

```ruby
def prepare(ctx)
  ctx.store[:my_ext] ||= {}
  ctx.store[:my_ext][ctx.blueprint.object_id] = setup ctx
end
```

It's run once _per blueprint class_ during a render. So if you're rendering an array of widgets with `WidgetBlueprint`, which contains `PartBlueprint`s and `CategoryBlueprint`s, this hook will be called **three** times: one for each of those blueprints.

## blueprint_input

> **@param [Object Context](./context-objects.md#object-context)** `context.object` will contain the current object being rendered\
> **@return Object** A new or modified version of `context.object`\
> **@cost** Medium - run every time any blueprint is rendered

Run each time a blueprint renders, allowing you to modify or return a new object (`context.object`) used for the render. For collections of size N, it will be called N times. **Whatever object is returned will be used as context.object in subsequent hooks, then rendered.**

```ruby
def blueprint_input(ctx)
  ctx.object
end
```

## extract_value

> **@param [Field Context](./context-objects.md#field-context)** `context.field` will contain the current field being serialized, and `context.object` the current object\
> **@return Object** The value for the field\
> **@cost** High - run for every field, object, and collection

Called on each field, object, and collection. The return value is used as `context.value` in subsequent hooks. If multiple extensions define this hook, _only the last one_ will be used.

```ruby
def extract_value(ctx)
  ctx.object.public_send(ctx.field.from)
end
```

## field_value

> **@param [Field Context](./context-objects.md#field-context)** `context.field` will contain the current field being serialized, and `context.object` the current object\
> **@return Object** The value to be rendered\
> **@cost** High - run for every field (not object or collection fields)

Run after a field value is extracted from `context.object`. The extracted value is available in `context.value`. **Whatever value you return is used as context.value in subsequent field_value hooks, then run through any formatters and rendered.**

```ruby
def field_value(ctx)
  case ctx.value
  when String then ctx.value.strip
  else ctx.value
  end
end
```

## object_value

> **@param [Field Context](./context-objects.md#field-context)** `context.field` will contain the current field being serialized, and `context.object` the current object\
> **@return Object** The object to be rendered for this field\
> **@cost** High - run for every object field

Run after an object field value is extracted from `context.object`. The extracted value is available in `context.value`. **Whatever value you return is used as context.value in subsequent object_value hooks, then rendered.**

```ruby
def object_value(ctx)
  ctx.value
end
```

## collection_value

> **@param [Field Context](./context-objects.md#field-context)** `context.field` will contain the current field being serialized, and `context.object` the current object\
> **@return Object** The array-like collection to be rendered for this field\
> **@cost** High - run for every collection field

Run after a collection field value is extracted from `context.object`. The extracted value is available in `context.value`. **Whatever value you return is used as context.value in subsequent collection_value hooks, then rendered.**

```ruby
def collection_value(ctx)
  ctx.value.compact
end
```

## exclude_field?

> **@param [Field Context](./context-objects.md#field-context)** `context.field` will contain the current field being serialized, and `context.object` the current object\
> **@return Boolean** Truthy to exclude the field from the output\
> **@cost** High - run for every field (not object or collection fields)

If any extension with this hook returns truthy, the field will be excluded from the output. The formatted field value is available in `context.value`.

```ruby
def exclude_field?(ctx)
  ctx.field.options[:tuesday] == false && Date.today.tuesday?
end
```

## exclude_object?

> **@param [Field Context](./context-objects.md#field-context)** `context.field` will contain the current field being serialized, and `context.object` the current object\
> **@return Boolean** Truthy to exclude the field from the output\
> **@cost** High - run for every object field

If any extension with this hook returns truthy, the object field will be excluded from the output. The field object value is available in `context.value`.

```ruby
def exclude_object?(ctx)
  ctx.field.options[:tuesday] == false && Date.today.tuesday?
end
```

## exclude_collection?

> **@param [Field Context](./context-objects.md#field-context)** `context.field` will contain the current field being serialized, and `context.object` the current object\
> **@return Boolean** Truthy to exclude the field from the output\
> **@cost** High - run for every collection field

If any extension with this hook returns truthy, the collection field will be excluded from the output. The field collection value is available in `context.value`.

```ruby
def exclude_collection?(ctx)
  ctx.field.options[:tuesday] == false && Date.today.tuesday?
end
```

## blueprint_output

> **@param [Result Context](./context-objects.md#result-context)** `context.result` will contain the serialized Hash from the current blueprint, and `context.object` the current object\
> **@return Hash** The Hash to use as this blueprint's serialized output\
> **@cost** Medium - run every time any blueprint is rendered

Run after a blueprint serializes an object to a Hash, allowing you to modify the output. The Hash is available in `context.result`. For collections of size N, it will be called N times. **Whatever Hash is returned will be used as context.result in subsequent hooks and used as the serialized output for this blueprint.**

```ruby
def blueprint_output(ctx)
  ctx.result.merge(ctx.object.extra_fields)
end
```

## output_object

> **@param [Result Context](./context-objects.md#result-context)** `context.result` will contain the serialized Hash from the top-level blueprint, and `context.object` the top-level object\
> **@return Hash** The Hash to use as the final serialized output\
> **@cost** Low - run once per `render` (for objects) or `render_object`

Run after the top-level object is fully serialized to a Hash, allowing you to modify the output. The Hash is available in `context.result`. **Whatever is returned will be the final serialized output.**

```ruby
def output_object(ctx)
  ctx.result.merge({ extra: "data" })
end
```

## output_collection

> **@param [Result Context](./context-objects.md#result-context)** `context.result` will contain the serialized array of Hashes from the top-level blueprint, and `context.object` the top-level collection\
> **@return Hash | Array<Hash>** The Hash, or array of Hashes, to use as tthe final serialized output\
> **@cost** Low - run once per `render` (for collections) or `render_collection`

Run after the top-level collection is fully serialized to an array of Hashes, allowing you to modify the output. The array of Hashes is available in `context.result`. **Whatever is returned will be the final serialized output.**

```ruby
# Wrap the output array in a Hash
def output_collection(ctx)
  {
    data: ctx.result,
    extra: "metadata"
  }
end

# Or modify each element
def output_collection(ctx)
  ctx.result.map { |item| item.merge({ extra: "data" }) }
end
```

## json

> **@param [Result Context](./context-objects.md#result-context)** `context.result` will contain the serialized Hash or array from the top-level blueprint, and `context.object` the top-level object or collection\
> **@return String** The JSON output\
> **@cost** Low - run once per JSON render

Serializes the final output to JSON. If multiple extensions define this hook, _only the last one_ will be used.

The default behavior looks like:

```ruby
def json(ctx)
  JSON.dump ctx.result
end
```

## around_hook

> **@param Extension** Instance of the extension\
> **@param Symbol** Name of the hook\
> **@cost** Variable - Depends on what hooks your extensions implement

A special hook that runs around all other extension hooks. Useful for instrumenting. You can exclude an extension's hooks from this hook by putting `def hidden? = true` in the extension.

```ruby
def around_hook(ext, hook)
  # Do something before extension hook runs
  yield # hook runs here
  # Do something after extension hook runs
end
```
