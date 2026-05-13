---
description: How to upgrade a Blueprint to V2
user-invocable: false
skills:
  - blueprinter-v2-basics
---

## Breaking DSL Changes in V2

* V1's base class was `Blueprinter::Base`. V2's is `Blueprinter::V2::Base`.
* `include_view` changed to `use`.
* `current_view.name` changed to `view_name`.
* `identifier` no longer exists.
* Procs passed to `if` and `unless` options take a single `ctx` argument. Legacy args can be extracted from `ctx.field.source`, `ctx.object`, and `ctx.options`.
* The `default_if` arg should be the symbol `:empty_field?`.
* The 2nd arg to field or association blocks is now `ctx`. The legacy arg can be extracted from `ctx.options`.
* `ctx.options` is immutable. If a block tries to modify it, add a TODO to use `ctx.store` instead.
* The `name` option is gone. `field :x, name: :y` should be changed to `field :y, source: :x`. Same for `association`.
* Update associations to use the V2 syntax.
* If an explicit `:default` view is defined, move everything in it to the class level.
* `transform` no longer exists. Replace it with the `Blueprinter::Extensions::LegacyTransformer` extension, passing the transformer class to the initializer.
* If a `field` block is rendering a Blueprint, convert it to an `association`.
* Change `MyBlueprint.render(x)` to `MyBlueprint.render(x).to_json`.

## Best Practices in V2

* When extracting options, etc from `ctx`, prefer to change as few lines as possible.
* Including the `:default` view is redundant.
* Remove the 2nd arg from field/association blocks if it's unused.
* Add the `Blueprinter::Extensions::ViewOption` extension to V2's base class.
* Add the `Blueprinter::Extensions::LegacyExtractorOption` extension to V2's base class.
* `MyBlueprint.render(x).to_hash` is preferred over `MyBlueprint.render_as_hash(x)`.
* `MyBlueprint.render(x).to_json` is preferred over `MyBlueprint.render_as_json(x)`.
