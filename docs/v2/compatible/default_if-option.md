# default_if option

V2 has a much more flexible `default_if` option, but you can maintain backwards compatibility with V1 using the `LegacyOptions` extension.

The old `default_if` values will continue to work (until a future Blueprinter removes the constants).

```ruby
field :name, default: "N/A", default_if: Blueprinter::EMPTY_STRING
```

Also like V1, a `default_if` with no `default` option defaults to `nil`:

```ruby
field :name, default_if: Blueprinter::EMPTY_STRING
```

V2 never reads V1's global configuration, so `Blueprinter.configuration.field_default` is ignored. Declare the default on a Blueprint instead — on an `ApplicationBlueprint` that the rest of your Blueprints inherit from, if you want it applied everywhere:

```ruby
class ApplicationBlueprint < Blueprinter::V2::Base
  set :default, "N/A"
end
```

## V2 style

The native V2 option allows for Procs or symbols (method names). The logic is up to you.

They're passed a `Blueprinter::V2::Context::Field` object and the extracted value.

```ruby
field :name, default: "N/A", default_if: ->(ctx, val) { val.empty? }
field :name, default: "N/A", default_if: :empty_string?

def empty_string?(ctx, val) = val.empty?
```
