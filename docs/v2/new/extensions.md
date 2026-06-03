# Extensions

Extensions exist in legacy/V1, but they were added late and have limited functionality. Blueprinter V2 has been designed from the
ground up with extensions in mind.

## Extension API

See the `Blueprinter::Extension` docs for the full API, or read through the [Extension Guide](../../extensions/index.md).

## Using extensions

Extensions can be added to Blueprints, views, and partials. They'll be inherited by child Blueprints or views.

```ruby
# Add some extensions (append)
add MyExtension.new, MyOtherExtension.new

# Prepend an extension
add MyExtension.new, prepend: true

# Remove an extension by class or block
remove MyExtension
remove { |ext| ext.is_a? MyExtension }

# Prevent inheritance of extensions
exclude extensions: true
```

## Bundled extensions

Blueprinter V2 comes bundled with the following extensions. See the `Blueprinter::Extensions` module for full documentation about each one.

### MultiJson

Uses the `multi_json` gem to serialize JSON. See `Blueprinter::Extensions::MultiJson`.

### OpenTelemetry

Instruments the serialization process so you can see which Blueprints or extensions are slowing things down. See `Blueprinter::Extensions::OpenTelemetry`.

### FieldOrder

Customizes the field order in the serialized output. See `Blueprinter::Extensions::FieldOrder`.

### V1 Compatibility Extensions

These extensions offer V1-compatibility for some options. They're covered under the [Compatible Changes](../compatible/index.md) section.

* `Blueprinter::Extensions::LegacyConditionals`
* `Blueprinter::Extensions::LegacyDefaultIf`
* `Blueprinter::Extensions::LegacyDynamicOptions`
* `Blueprinter::Extensions::LegacyExtractorOption`
* `Blueprinter::Extensions::LegacyRenameField`
* `Blueprinter::Extensions::ViewOption`
