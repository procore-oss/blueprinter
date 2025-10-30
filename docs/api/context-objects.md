# Context Objects

Context objects are the arguments passed to APIs like [field blocks](../dsl/fields.md#field-blocks), [option procs](../dsl/options.md) and [extension hooks](./extensions.md). There are several kinds of context objects, each with its own set of fields. Some fields are read-only (_RO_), others can be changed (_RW_).

## Render Context

> **blueprint** _RO_\
> The current Blueprint instance. You can use this to access the Blueprint's name, options, reflections, and instance methods.

> **fields** _RW_\
> A frozen array of field definitions that will be serialized, in order. See [Fields API](./fields.md).

> **options** _RW_\
> The frozen options Hash passed to `render`. An empty Hash if none was passed.

> **depth** _RO_\
> The current blueprint depth (1-indexed).

## Object Context

> **blueprint** _RO_\
> The current Blueprint instance. You can use this to access the Blueprint's name, options, reflections, and instance methods.

> **fields** _RO_\
> A frozen array of field definitions that will be serialized, in order. See [Fields API](./fields.md) and the [blueprint_fields](./extensions.md#blueprint_fields) hook.

> **options** _RO_\
> The frozen options Hash passed to `render`. An empty Hash if none was passed.

> **object** _RW_\
> The object or collection currently being serialized.

> **depth** _RO_\
> The current blueprint depth (1-indexed).

## Field Context

> **blueprint** _RO_\
> The current Blueprint instance. You can use this to access the Blueprint's name, options, reflections, and instance methods.

> **fields** _RO_\
> A frozen array of field definitions that will be serialized, in order. See [Fields API](./fields.md) and the [blueprint_fields](./extensions.md#blueprint_fields) hook.

> **options** _RO_\
> The frozen options Hash passed to `render`. An empty Hash if none was passed.

> **object** _RO_\
> The object currently being serialized.

> **field** _RO_\
> A struct of the field, object, or collection currently being rendered. You can use this to access the field's name and options. See [Fields API](./fields.md).

> **depth** _RO_\
> The current blueprint depth (1-indexed).

## Result Context

> **blueprint** _RW_\
> The current Blueprint instance. You can use this to access the Blueprint's name, options, reflections, and instance methods.

> **fields** _RO_\
> A frozen array of field definitions that were serialized, in order. See [Fields API](./fields.md) and the [blueprint_fields](./extensions.md#blueprint_fields) hook.

> **options** _RW_\
> The frozen options Hash passed to `render`. An empty Hash if none was passed.

> **object** _RW_\
> The object or collection that was just serialized.

> **format** _RW_\
> The requested serialization format (e.g. `:json`, `:hash`).

## Hook Context

> **blueprint** _RO_\
> The current Blueprint instance. You can use this to access the Blueprint's name, options, reflections, and instance methods.

> **fields** _RO_\
> A frozen array of field definitions that will be serialized, in order. See [Fields API](./fields.md) and the [blueprint_fields](./extensions.md#blueprint_fields) hook.

> **options** _RO_\
> The frozen options Hash passed to `render`. An empty Hash if none was passed.

> **extension** _RO_\
> Instance of the current extension

> **hook** _RO_\
> Name of the current hook

> **depth** _RO_\
> The current blueprint depth (1-indexed).
