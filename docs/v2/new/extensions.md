# Extensions

While extensions were added to legacy/V1 several years ago, they were after afterthought and very limited. Blueprinter V2 has been designed from the
ground up with extensions in mind.

See the `Blueprinter::Extension` docs for the full API, or read through the [Extension Guide](../../extensions/index.md).

## Bundled extensions

Blueprinter V2 comes bundled with the following extensions. See the `Blueprinter::Extensions` module for full documentation about each one.

### MultiJson

Use the `multi_json` gem to serialize JSON. See `Blueprinter::Extensions::MultiJson`.

### OpenTelemetry

Instrument the serialization process so you can see which Blueprints or extensions are slowing things down. See `Blueprinter::Extensions::OpenTelemetry`.

### FieldOrder

Customize the field order in the serialized output. See `Blueprinter::Extensions::FieldOrder`.

### V1 Compatibility Extensions

These extensions offer V1-compatibility for some options. They're covered under the [Compatible Changes](../compatible/index.md) section.

* `Blueprinter::Extensions::LegacyConditionals`
* `Blueprinter::Extensions::LegacyDefaultIf`
* `Blueprinter::Extensions::LegacyDynamicOptions`
* `Blueprinter::Extensions::LegacyExtractorOption`
* `Blueprinter::Extensions::LegacyRenameField`
* `Blueprinter::Extensions::ViewOption`
