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

Hooks are called in the following order. They are passed a [context object](./context-objects.md) as an argument.

- [blueprint](#blueprint)
- [blueprint_fields](#blueprint_fields)
- [blueprint_setup](#blueprint_setup)
- [around_serialize_object](#around_serialize_object) | [around_serialize_collection](#around_serialize_collection)
  - [object_input](#object_input) | [collection_input](#collection_input)
  - [blueprint_input](#blueprint_input)
    - [extract_value](#extract_value)
    - [field_value](#field_value) | [object_field_value](#object_field_value) | [collection_field_value](#collection_field_value)
    - [exclude_field?](#exclude_field) | [exclude_object_field?](#exclude_object_field) | [exclude_collection_field?](#exclude_collection_field)
      - *blueprint_fields &hellip;*
    - [field_result](#field_result) | [object_field_result](#object_field_result) | [collection_field_result](#collection_field_result)
  - [blueprint_output](#blueprint_output)
  - [object_output](#object_output) | [collection_output](#collection_output)
- [json](#json)

Additionally, the [around_hook](#around_hook) hook runs around all other hooks.

#### Chain vs override hooks

Most hooks are *chained*; if you have N of the same hook, they run one after the other, using the output of one as input for the next. However, a few hooks are *override* hooks: only the last one runs. Override hooks are used to replace built-in functionality, like the JSON serializer.

## blueprint

> *Override hook*\
> **@param [Render Context](./context-objects.md#render-context)** NOTE `fields` will be empty\
> **@return [Class](./fields.md)** The Blueprint class to use\
> **@cost** Low - run once during render

Return a different blueprint class to render with. If multiple extensions define this hook, _only the last one_ will be used. The included, optional [View Option extension](../dsl/extensions.md#viewoption) uses this hook.

The following example looks for a `view` option passed in to `render`. If present, it attempts to return a child view.

```ruby
def blueprint(ctx)
  view = ctx.options[:view]
  view ? ctx.blueprint.class[view] : ctx.blueprint.class
end
```

## blueprint_fields

> *Override hook*\
> **@param [Render Context](./context-objects.md#render-context)**\
> **@return [Array&lt;Field&gt;](./fields.md)** The fields to serialize\
> **@cost** Low - run once for _every blueprint class_ during render

Customize the order fields are rendered in - or strip out certain fields entirely. If multiple extensions define this hook, _only the last one_ will be used. The included, optional [Field Order extension](../dsl/extensions.md#field-order) uses this hook.

In this hook, `context.fields` will contain all of the view's fields in the order in which they were defined. (Fields from `use`d partials are appended.) The fields this hook returns are used as `context.fields` in all subsequent hooks:

The following example removes all collection fields and sorts the rest by name:

```ruby
def blueprint_fields(ctx)
  ctx.fields.
    reject { |f| f.type == :collection }.
    sort_by(&:name)
end
```

It's run once _per blueprint class_ during a render. So if you're rendering an array of widgets with `WidgetBlueprint`, which contains `PartBlueprint`s and `CategoryBlueprint`s, this hook will be called **three** times: one for each of those blueprints.

[&uarr; Back to Hooks](#hooks)

## blueprint_setup

> **@param [Render Context](./context-objects.md#render-context)**\
> **@cost** Low - run once for _every blueprint class_ during render

Allows an extension to perform setup operations for the render of the current blueprint.

```ruby
def blueprint_setup(ctx)
  # do setup for ctx.blueprint
end
```

It's run once _per blueprint class_ during a render. So if you're rendering an array of widgets with `WidgetBlueprint`, which contains `PartBlueprint`s and `CategoryBlueprint`s, this hook will be called **three** times: one for each of those blueprints.

[&uarr; Back to Hooks](#hooks)

## around_serialize_object

> **@param [Object Context](./context-objects.md#object-context)** `context.object` will contain the current object being rendered\
> **@cost** Medium - run every time any blueprint is rendered

Wraps the rendering of every object (`context.object`). This could be the top-level object or one from an association N levels deep (check `context.depth`).

Rendering happens during `yield`, allowing the hook to run code before and after the render. If `yield` is not called exactly one time, a `BlueprinterError` is thrown.

```ruby
def around_serialize_object(ctx)
  # do something before render
  yield # render
  # do something after render
end
```

[&uarr; Back to Hooks](#hooks)

## around_serialize_collection

> **@param [Object Context](./context-objects.md#object-context)** `context.object` will contain the current collection being rendered\
> **@cost** Medium - run every time any blueprint is rendered

Wraps the rendering of every collection (`context.object`). This could be the top-level collection or one from an association N levels deep (check `context.depth`).

Rendering happens during `yield`, allowing the hook to run code before and after the render. If `yield` is not called exactly one time, a `BlueprinterError` is thrown.

```ruby
def around_serialize_collection(ctx)
  # do something before render
  yield # render
  # do something after render
end
```

[&uarr; Back to Hooks](#hooks)

## object_input

> **@param [Object Context](./context-objects.md#object-context)** `context.object` will contain the current object being rendered\
> **@return Object** A new or modified version of `context.object`\
> **@cost** Medium - run every time an object is rendered

Runs before serialization of any object from `render`, `render_object`, or a blueprint's `object` field. You may modify and return `context.object` or return a different object entirely. **Whatever object is returned will be used as context.object in subsequent hooks, then rendered.**

If you want to target only the root object, check `context.depth == 1`.

```ruby
def object_input(ctx)
  ctx.object
end
```

[&uarr; Back to Hooks](#hooks)

## collection_input

> **@param [Object Context](./context-objects.md#object-context)** `context.object` will contain the current collection being rendered\
> **@return Object** A new or modified version of `context.object`, which will be array-like\
> **@cost** Medium - run every time a collection is rendered

Runs before serialization of any collection from `render`, `render_collection`, or a blueprint's `collection` field. You may modify and return `context.object` or return a different collection entirely. **Whatever collection is returned will be used as context.object in subsequent hooks, then rendered.**

If you want to target only the root collection, check `context.depth == 1`.

```ruby
def collection_input(ctx)
  ctx.object
end
```

[&uarr; Back to Hooks](#hooks)

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

[&uarr; Back to Hooks](#hooks)

## extract_value

> *Override hook*\
> **@param [Field Context](./context-objects.md#field-context)** `context.field` will contain the current field being serialized, and `context.object` the current object\
> **@return Object** The value for the field\
> **@cost** High - run for every field, object, and collection

Called on each field, object, and collection to extract a field's value from an object. The return value is used as `context.value` in subsequent hooks. If multiple extensions define this hook, _only the last one_ will be used.

```ruby
def extract_value(ctx)
  ctx.object.public_send(ctx.field.from)
end
```

[&uarr; Back to Hooks](#hooks)

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

[&uarr; Back to Hooks](#hooks)

## object_field_value

> **@param [Field Context](./context-objects.md#field-context)** `context.field` will contain the current field being serialized, and `context.object` the current object\
> **@return Object** The object to be rendered for this field\
> **@cost** High - run for every object field

Run after an object field value is extracted from `context.object`. The extracted value is available in `context.value`. **Whatever value you return is used as context.value in subsequent object_field_value hooks, then rendered.**

```ruby
def object_field_value(ctx)
  ctx.value
end
```

[&uarr; Back to Hooks](#hooks)

## collection_field_value

> **@param [Field Context](./context-objects.md#field-context)** `context.field` will contain the current field being serialized, and `context.object` the current object\
> **@return Object** The array-like collection to be rendered for this field\
> **@cost** High - run for every collection field

Run after a collection field value is extracted from `context.object`. The extracted value is available in `context.value`. **Whatever value you return is used as context.value in subsequent collection_field_value hooks, then rendered.**

```ruby
def collection_field_value(ctx)
  ctx.value.compact
end
```

[&uarr; Back to Hooks](#hooks)

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

[&uarr; Back to Hooks](#hooks)

## exclude_object_field?

> **@param [Field Context](./context-objects.md#field-context)** `context.field` will contain the current field being serialized, and `context.object` the current object\
> **@return Boolean** Truthy to exclude the field from the output\
> **@cost** High - run for every object field

If any extension with this hook returns truthy, the object field will be excluded from the output. The field object value is available in `context.value`.

```ruby
def exclude_object_field?(ctx)
  ctx.field.options[:tuesday] == false && Date.today.tuesday?
end
```

[&uarr; Back to Hooks](#hooks)

## exclude_collection_field?

> **@param [Field Context](./context-objects.md#field-context)** `context.field` will contain the current field being serialized, and `context.object` the current object\
> **@return Boolean** Truthy to exclude the field from the output\
> **@cost** High - run for every collection field

If any extension with this hook returns truthy, the collection field will be excluded from the output. The field collection value is available in `context.value`.

```ruby
def exclude_collection_field?(ctx)
  ctx.field.options[:tuesday] == false && Date.today.tuesday?
end
```

[&uarr; Back to Hooks](#hooks)

## field_result

> **@param [Field Context](./context-objects.md#field-context)** `context.field` will contain the current field being serialized, and `context.object` the current object\
> **@return Object** The value to be rendered for this field\
> **@cost** High - run for every field

The final value to be used for the field, available in `context.value`. You may modify or replace it. **Whatever value you return is used as context.value in subsequent hooks, then rendered.** Not called if [exclude_field?](#exclude_field) returned `true`.

```ruby
def field_result(ctx)
  ctx.value
end
```

[&uarr; Back to Hooks](#hooks)

## object_field_result

> **@param [Field Context](./context-objects.md#field-context)** `context.field` will contain the current field being serialized, and `context.object` the current object\
> **@return Object** The value to be rendered for this field\
> **@cost** High - run for every field

The final value to be used for the field, available in `context.value`. You may modify or replace it. **Whatever value you return is used as context.value in subsequent hooks, then rendered.** Not called if [exclude_object_field?](#exclude_object_field) returned `true`.

```ruby
def object_field_result(ctx)
  ctx.value
end
```

[&uarr; Back to Hooks](#hooks)

## collection_field_result

> **@param [Field Context](./context-objects.md#field-context)** `context.field` will contain the current field being serialized, and `context.object` the current object\
> **@return Object** The value to be rendered for this field\
> **@cost** High - run for every field

The final value to be used for the field, available in `context.value`. You may modify or replace it. **Whatever value you return is used as context.value in subsequent hooks, then rendered.** Not called if [exclude_collection_field?](#exclude_collection_field) returned `true`.

```ruby
def collection_field_result(ctx)
  ctx.value
end
```

[&uarr; Back to Hooks](#hooks)

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

[&uarr; Back to Hooks](#hooks)

## object_output

> **@param [Result Context](./context-objects.md#result-context)** `context.result` will contain the serialized Hash from the current blueprint, and `context.object` the current object\
> **@return [Object]** The value to use for the fully serialized object\
> **@cost** High - run for every object field

Run after an object is fully serialized. This may be the root object from `render` or an `object` field from a blueprint (check `context.depth`). This example wraps the result in a metadata block:

```ruby
def object_output(ctx)
  { data: ctx.value, metadata: {...} }
end
```

[&uarr; Back to Hooks](#hooks)

## collection_output

> **@param [Result Context](./context-objects.md#result-context)** `context.result` will contain the array of serialized Hashes from the current blueprint, and `context.object` the current collection\
> **@return Object** The value to use for the fully serialized collection\
> **@cost** High - run for every collection field

Run after a collection is fully serialized. This may be the root collection from `render` or a `collection` field from a blueprint (check `context.depth`). This example wraps the result in a metadata block:

```ruby
def collection_output(ctx)
  { data: ctx.value, metadata: {...} }
end
```

[&uarr; Back to Hooks](#hooks)

## json

> *Override hook*\
> **@param [Result Context](./context-objects.md#result-context)** `context.result` will contain the serialized Hash or array from the top-level blueprint, and `context.object` the top-level object or collection\
> **@return String** The JSON output\
> **@cost** Low - run once per JSON render

Serializes the final output to JSON. Only called on the top-level blueprint. If multiple extensions define this hook, _only the last one_ will be used.

The default behavior looks like:

```ruby
def json(ctx)
  JSON.dump ctx.result
end
```

[&uarr; Back to Hooks](#hooks)

## around_hook

> **@param [Hook Context](./context-objects.md#hook-context)**\
> **@cost** Variable - Depends on what hooks your extensions implement

A special hook that runs around all other extension hooks. Useful for instrumenting. You can exclude an extension's hooks from this hook by putting `def hidden? = true` in the extension.

```ruby
def around_hook(ext, hook)
  # Do something before extension hook runs
  yield # hook runs here
  # Do something after extension hook runs
end
```
