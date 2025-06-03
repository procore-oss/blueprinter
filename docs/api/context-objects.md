# Context Objects

Context objects are the arguments passed to APIs like [field blocks](../dsl/fields.md#field-blocks), [option procs](../dsl/options.md) and [extension hooks](./extensions.md). There are several kinds of context objects, each with its own set of fields.

## Render Context

> **blueprint**\
> The current Blueprint instance. You can use this to access the Blueprint's name, options, reflections, and instance methods.

> **options**\
> The frozen options Hash passed to `render`. An empty Hash if none was passed.

## Object Context

> **blueprint**\
> The current Blueprint instance. You can use this to access the Blueprint's name, options, reflections, and instance methods.

> **options**\
> The frozen options Hash passed to `render`. An empty Hash if none was passed.

> **object**\
> The object or collection currently being serialized.

## Field Context

> **blueprint**\
> The current Blueprint instance. You can use this to access the Blueprint's name, options, reflections, and instance methods.

> **options**\
> The frozen options Hash passed to `render`. An empty Hash if none was passed.

> **object**\
> The object currently being serialized.

> **field**\
> A struct of the field, object, or collection currently being rendered. You can use this to access the field's name and options. See [rubydoc.info/gems/blueprinter](https://www.rubydoc.info/gems/blueprinter) for more information about the `Field`, `ObjectField`, and `Collection` structs.

> **value**\
> The extracted field value. (In certain situations, like the extractor API and field blocks, it will always be `nil` since nothing has been extracted yet.)

## Result Context

> **blueprint**\
> The current Blueprint instance. You can use this to access the Blueprint's name, options, reflections, and instance methods.

> **options**\
> The frozen options Hash passed to `render`. An empty Hash if none was passed.

> **object**\
> The object or collection that was just serialized.

> **result**\
> A serialized result. Depending on the situation this will be a Hash or an array of Hashes.

## Hook Context

> **blueprint**\
> The current Blueprint instance. You can use this to access the Blueprint's name, options, reflections, and instance methods.

> **options**\
> The frozen options Hash passed to `render`. An empty Hash if none was passed.

> **extension**\
> Instance of the current extension

> **hook**\
> Name of the current hook
