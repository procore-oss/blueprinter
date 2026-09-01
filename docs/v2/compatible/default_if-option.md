# default_if option

V2 has a much more flexible `default_if` option. You can maintain backwards compatibility with V1 using the `LegacyDefaultIf` extension.

```ruby
class ApplicationBlueprint < Blueprinter::V2::Base
  add Blueprinter::Extensions::LegacyDefaultIf.new
end
```

The old `default_if` values will continue to work (until a future Blueprinter removes the constants).

```ruby
field :name, default: "N/A", default_if: Blueprinter::EMPTY_STRING
```

## V2 style

The native V2 option allows for Procs or symbols (method names). The logic is up to you.

They're passed a `Blueprinter::V2::Context::Field` object and the extracted value.

```ruby
field :name, default: "N/A", default_if: ->(ctx, val) { val.empty? }
field :name, default: "N/A", default_if: :empty_string?

def empty_string?(ctx, val) = val.empty?
```
