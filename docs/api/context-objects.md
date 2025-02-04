# Context Objects

Context objects are the arguments passed to APIs like [field blocks](../dsl/fields.md#field-blocks), [option procs](../dsl/options.md), [extension hooks](./extensions.md), and [extractors](./extractors.md). They contain the current blueprint, the object being rendered, and more (depending on the specific API).

### blueprint

The current Blueprint instance. You can use this to access the Blueprint's name, options, reflections, and instance methods.

_Present_: Always

### field

A struct of the field, object, or collection being rendered. You can use this to access the field's name and options. See [rubydoc.info/gems/blueprinter](https://www.rubydoc.info/gems/blueprinter) for more information about the `Field`, `ObjectField`, and `Collection` structs.

_Present_: In field blocks, option procs, extractors, and certain extension hooks

### value

Depending on the API, this will be either the extracted value of the current field, or the entire output of the current Blueprint.

_Present_: Certain option procs and extension hooks

### object

The object currently being rendered.

_Present_: Always

### options

The frozen options Hash passed to `render`. An empty Hash if none was passed.

_Present_: Always

### store

A Hash for extensions to cache data in. Note that Blueprinter uses this store internally, so be careful not to overwrite Blueprinter's keys (they're all object ids).

_Present_: Always

### instances

A Hash-like interface for creating/fetching class instances. This allows Blueprinter to reuse the same blueprint and extractor instances during a render. You're free to use it, too. See `InstanceCache` in [rubydoc.info/gems/blueprinter](https://www.rubydoc.info/gems/blueprinter) for more details.

_Present_: Always
