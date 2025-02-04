# Context Objects

Context objects are the arguments passed to APIs like [field blocks](../dsl/fields.md#field-blocks), [option procs](../dsl/options.md) and [extension hooks](./extensions.md). There are several kinds of context objects, each with its own set of fields.

## Render Context

> **blueprint**\
> The current Blueprint instance. You can use this to access the Blueprint's name, options, reflections, and instance methods.

> **fields**\
> A frozen array of field definitions that will be serialized, in order. See [Fields API](./fields.md) and the [blueprint_fields](./extensions.md#blueprint_fields) hook.

> **options**\
> The frozen options Hash passed to `render`. An empty Hash if none was passed.

> **depth**\
> The current blueprint depth (1-indexed).

## Object Context

> **blueprint**\
> The current Blueprint instance. You can use this to access the Blueprint's name, options, reflections, and instance methods.

> **fields**\
> A frozen array of field definitions that will be serialized, in order. See [Fields API](./fields.md) and the [blueprint_fields](./extensions.md#blueprint_fields) hook.

> **options**\
> The frozen options Hash passed to `render`. An empty Hash if none was passed.

> **object**\
> The object or collection currently being serialized.

> **depth**\
> The current blueprint depth (1-indexed).

## Field Context

> **blueprint**\
> The current Blueprint instance. You can use this to access the Blueprint's name, options, reflections, and instance methods.

> **fields**\
> A frozen array of field definitions that will be serialized, in order. See [Fields API](./fields.md) and the [blueprint_fields](./extensions.md#blueprint_fields) hook.

> **options**\
> The frozen options Hash passed to `render`. An empty Hash if none was passed.

> **object**\
> The object currently being serialized.

> **field**\
> A struct of the field, object, or collection currently being rendered. You can use this to access the field's name and options. See [Fields API](./fields.md).

> **value**\
> The extracted field value. (In certain situations, like the extractor API and field blocks, it will always be `nil` since nothing has been extracted yet.)

> **depth**\
> The current blueprint depth (1-indexed).

## Result Context

> **blueprint**\
> The current Blueprint instance. You can use this to access the Blueprint's name, options, reflections, and instance methods.

> **fields**\
> A frozen array of field definitions that were serialized, in order. See [Fields API](./fields.md) and the [blueprint_fields](./extensions.md#blueprint_fields) hook.

> **options**\
> The frozen options Hash passed to `render`. An empty Hash if none was passed.

> **object**\
> The object or collection that was just serialized.

> **result**\
> A serialized result. Depending on the situation this will be a Hash or an array of Hashes.

> **depth**\
> The current blueprint depth (1-indexed).

## Hook Context

> **blueprint**\
> The current Blueprint instance. You can use this to access the Blueprint's name, options, reflections, and instance methods.

> **fields**\
> A frozen array of field definitions that will be serialized, in order. See [Fields API](./fields.md) and the [blueprint_fields](./extensions.md#blueprint_fields) hook.

> **options**\
> The frozen options Hash passed to `render`. An empty Hash if none was passed.

> **extension**\
> Instance of the current extension

> **hook**\
> Name of the current hook

> **depth**\
> The current blueprint depth (1-indexed).
