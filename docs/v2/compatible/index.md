# Compatible Changes

When you migrate a Blueprint to V2 you can enable the `LegacyOptions` extension to maintain backwards-compatibility with many V1 options.

```ruby
class ApplicationBlueprint < Blueprinter::V2::Base
  add Blueprinter::Extensions::LegacyOptions.new
end
```

> [!NOTE]
These extensions don't _replace_ V2's native behavior. Instead, they detect and convert V1-style options. This allows your application
to migrate to V2 at a gradual pace.
