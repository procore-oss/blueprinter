# Context Objects

Context objects are the arguments passed to APIs like [field blocks](../dsl/fields.md#field-blocks), [option procs](../dsl/options.md), [extension hooks](./extensions.md), and [extractors](./extractors.md). There are several kinds of context objects, each with its own set of fields.

## Render Context

Only the [common fields](#common-fields) exist in the render context.

## Hook Context

Only the [common fields](#common-fields) exist in the hook context.

## Object Context

All the [common fields](#common-fields) plus:

> **object**\
> The object or collection currently being serialized.

## Field Context

All the [common fields](#common-fields) plus:

> **object**\
> The object currently being serialized.

> **field**\
> A struct of the field, object, or collection currently being rendered. You can use this to access the field's name and options. See [rubydoc.info/gems/blueprinter](https://www.rubydoc.info/gems/blueprinter) for more information about the `Field`, `ObjectField`, and `Collection` structs.

> **value**\
> The extracted field value. (In certain situations, like the extractor API and field blocks, it will always be `nil` since nothing has been extracted yet.)

## Result Context

All the [common fields](#common-fields) plus:

> **object**\
> The object or collection that was just serialized.

> **result**\
> A serialized result. Depending on the situation this will be a Hash or an array of Hashes.

## Common fields

These fields exist on all context objects:

> **blueprint**\
> The current Blueprint instance. You can use this to access the Blueprint's name, options, reflections, and instance methods.

> **options**\
> The frozen options Hash passed to `render`. An empty Hash if none was passed.

> **store**\
> A Hash for extensions, field blocks, and option blocks to cache data in. All hooks in a given extension use a shared store. Likewise, all field blocks and option procs in a given Blueprint view use a shared store.\
>\
> The store is discarded at the end of every render.

> **instances**\
> A Hash-like interface for creating/fetching class instances. This allows Blueprinter to reuse the same blueprint and extractor instances during a render. You're free to use it, too. See `InstanceCache` in [rubydoc.info/gems/blueprinter](https://www.rubydoc.info/gems/blueprinter) for more details.
