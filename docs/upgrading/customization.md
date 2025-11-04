# Customization

## Formatting

Blueprinter V2 has a more generic approach to formatting, allowing any type of value to have formatting applied. [Learn more](../dsl/formatters.md).

```ruby
format(Date) { |date| date.iso8601 }
```

The [around_field_value](../api/extensions.md#around_field_value), [around_object_value](../api/extensions.md#around_object_value), and [around_collection_value](../api/extensions.md#around_collection_value) extension hooks can also be used.

## Custom extractors

Custom extraction in V2 can also be accomplished with the [around_field_value](../api/extensions.md#around_field_value), [around_object_value](../api/extensions.md#around_object_value), and [around_collection_value](../api/extensions.md#around_collection_value) hooks. [Read more](../dsl/fields.md#extracting-with-extensions).

## Transformers

Blueprinter V2's [extension hooks](../api/extensions.md) offer many ways to transform your inputs and outputs. The [around_blueprint](../api/extensions.md#around_blueprint) hook offers equivalent functionality to Legacy/V1 transformers.
