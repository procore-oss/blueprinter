# Context Objects

Context objects are the arguments passed to APIs like [field blocks](../dsl/fields.md#field-blocks), [option procs](../dsl/options.md) and [extension hooks](./extensions.md). There are several kinds of context objects, each with its own set of fields.

## Render Context

_* Field can be changed._

> **blueprint** \
> The current Blueprint instance. You can use this to access the Blueprint's name, options, reflections, and instance methods.

> **fields** * \
> A frozen array of field definitions that will be serialized, in order. See [Fields API](./fields.md).

> **options** * \
> The frozen options Hash passed to `render`. An empty Hash if none was passed.

> **depth** \
> The current blueprint depth (1-indexed).

## Object Context

_* Field can be changed._

> **blueprint** \
> The current Blueprint instance. You can use this to access the Blueprint's name, options, reflections, and instance methods.

> **fields** \
> A frozen array of field definitions that will be serialized, in order. See [Fields API](./fields.md) and the [blueprint_fields](./extensions.md#blueprint_fields) hook.

> **options** \
> The frozen options Hash passed to `render`. An empty Hash if none was passed.

> **object** * \
> The object or collection currently being serialized.

> **depth** \
> The current blueprint depth (1-indexed).

## Field Context

> **blueprint** \
> The current Blueprint instance. You can use this to access the Blueprint's name, options, reflections, and instance methods.

> **fields** \
> A frozen array of field definitions that will be serialized, in order. See [Fields API](./fields.md) and the [blueprint_fields](./extensions.md#blueprint_fields) hook.

> **options** \
> The frozen options Hash passed to `render`. An empty Hash if none was passed.

> **object** \
> The object currently being serialized.

> **field** \
> A struct of the field, object, or collection currently being rendered. You can use this to access the field's name and options. See [Fields API](./fields.md).

> **depth** \
> The current blueprint depth (1-indexed).

## Result Context

_* Field can be changed._

> **blueprint** * \
> The current Blueprint instance. You can use this to access the Blueprint's name, options, reflections, and instance methods.

> **fields** \
> A frozen array of field definitions that were serialized, in order. See [Fields API](./fields.md) and the [around_blueprint_init](./extensions.md#around_blueprint_init) hook.

> **options** * \
> The frozen options Hash passed to `render`. An empty Hash if none was passed.

> **object** * \
> The object or collection that was just serialized.

> **format** * \
> The requested serialization format (e.g. `:json`, `:hash`).

## Hook Context

> **blueprint** \
> The current Blueprint instance. You can use this to access the Blueprint's name, options, reflections, and instance methods.

> **fields** \
> A frozen array of field definitions that will be serialized, in order. See [Fields API](./fields.md) and the [around_blueprint_init](./extensions.md#around_blueprint_init) hook.

> **options** \
> The frozen options Hash passed to `render`. An empty Hash if none was passed.

> **extension** \
> Instance of the current extension

> **hook** \
> Name of the current hook

> **depth** \
> The current blueprint depth (1-indexed).
