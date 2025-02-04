# Customization

## Formatting

Blueprinter V2 has a more generic approach to formatting, allowing any type of value to have formatting applied. [Learn more](../dsl/formatters.md).

```ruby
format(Date) { |date| date.iso8601 }
```

The [field_value](../api/extensions.md#field_value), [object_field_value](../api/extensions.md#object_field_value), and [collection_field_value](../api/extensions.md#collection_field_value) extension hooks can also be used.

## Custom extractors

Custom extraction in V2 is accomplished using the [extract_value](../api/extensions.md#extract_value) extension hook.

Fields, objects, and collections continue to have an [extractor](../dsl/options.md#extractor) option. Simply pass your extension class to it. [Learn more](../api/extractors.md).

Unlike Legacy/V1, custom extractors *do not override blocks* passed to fields, objects, and collections. If a field has a block, that's how it's extracted.

## Transformers

Blueprinter V2's [extension hooks](../api/extensions.md) offer many ways to transform your inputs and outputs. The [blueprint_output](../api/extensions.md#blueprint_output) hook offers equivalent functionality to Legacy/V1 transformers.
