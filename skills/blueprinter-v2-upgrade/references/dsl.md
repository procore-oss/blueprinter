# DSL conversion reference

The V2 DSL looks close enough to V1 that it's easy to skim past a difference. This file covers
the structural pieces; field and association *options* are in `options.md`.

## Contents

- [The class body is the default view](#the-class-body-is-the-default-view)
- [Associations](#associations)
- [Field and association blocks](#field-and-association-blocks)
- [Views](#views)
- [`include_view` → `use`](#include_view--use)
- [`identifier`](#identifier)
- [`transform`](#transform)
- [`exclude` / `excludes`](#exclude--excludes)
- [`current_view`](#current_view)
- [Partials](#partials-new-in-v2)
- [Formatters](#formatters-new-in-v2)
- [Anonymous Blueprints](#anonymous-blueprints)

## The class body is the default view

In V1 both of these were legal and meant the same thing:

```ruby
class WidgetBlueprint < Blueprinter::Base
  field :name                      # goes into the default view

  view :default do
    field :description             # also the default view
  end
end
```

In V2 the class body *is* the default view (`MyBlueprint == MyBlueprint[:default]`), and
`view :default` raises `Blueprinter::Errors::InvalidBlueprint`. Hoist the contents of an explicit
`:default` view into the class body, keeping the relative order of declarations.

## Associations

V1 took the Blueprint and cardinality as options and inferred collection-ness at render time. V2
puts both in the DSL.

```ruby
# V1
association :category,    blueprint: CategoryBlueprint
association :subcategory, blueprint: CategoryBlueprint, view: :simple
association :parts,       blueprint: PartBlueprint
association :subparts,    blueprint: PartBlueprint, view: :simple

# V2
association :category,    CategoryBlueprint
association :subcategory, CategoryBlueprint[:simple]
association :parts,       [PartBlueprint]
association :subparts,    [PartBlueprint[:simple]]
```

Getting the brackets wrong is the easiest way to break a migration, and the symptom is ugly —
V2 trusts the declaration, so a collection declared as an object serializes the Enumerable
itself. The source of truth is the underlying data, not the V1 code (V1 gave you no way to say).
Check the model association or the object the method returns.

**Interop**: the Blueprint may be a V1 class. `association :category, V1CategoryBlueprint` and
`association :category, V1CategoryBlueprint[:extended]` both work, and so does the reverse
(`association :c, blueprint: V2Blueprint, view: :extended` inside a V1 Blueprint). Use this to
keep a partial migration's scope small.

A `Proc` returning a Blueprint class is also allowed, for polymorphism:

```ruby
association :item,  ->(item) { item.blueprint }
association :items, [->(item) { item.blueprint }]
```

To reference a view of the *current* Blueprint without naming it, use `view_name` (just this
view's name) or `view_path` (the dotted path including parents):

```ruby
view :extended do
  association :category, CategoryBlueprint[view_name]   # CategoryBlueprint[:extended]
end
```

## Field and association blocks

The first block argument is unchanged. The **second argument is no longer the options Hash** —
it's a `Blueprinter::V2::Context::Field`. The mechanical fix is one line at the top:

```ruby
# V1
field :address do |widget, options|
  options[:full] ? widget.full_address : widget.city
end

# V2
field :address do |widget, ctx|
  options = ctx.options
  options[:full] ? widget.full_address : widget.city
end
```

Better, when the block is short, is to use `ctx.options` directly and drop the local. If the
second argument was unused, delete it.

`ctx` also carries `ctx.object`, `ctx.field` (with `.name`, `.source`, `.type`), `ctx.blueprint`,
`ctx.store`, `ctx.parent`, and `ctx.depth`. See `Blueprinter::V2::Context`.

**`ctx.options` is frozen.** V1 froze the render options too, but code that mutated a Hash it had
smuggled in will now raise. The V2 answer is `ctx.store`, a mutable Hash shared across the whole
render:

```ruby
field :foo do |widget, ctx|
  ctx.store[:seen] ||= []
  ctx.store[:seen] << widget.id
  widget.foo
end
```

**A field block that renders a Blueprint should become an association.** V1 forced this pattern
for anything with a dynamic Blueprint or odd shape:

```ruby
# V1
field :category do |widget, _opts|
  CategoryBlueprint.render_as_hash(widget.category)
end

# V2
association :category, CategoryBlueprint
```

Converting it gets you correct `nil` handling, correct collection handling, and association
hooks. If the Blueprint genuinely varies per object, use the `Proc` form shown above.

## Views

`view :name do ... end` is unchanged, and as in V1 a view inherits the default view's fields.
Two differences:

- **Views are real subclasses.** A V2 view can do anything a Blueprint can: set options, add
  extensions, define formatters, `include` a module, define methods, and declare *nested* views.
- **Nested views inherit from the enclosing view**, which inherits from the class. V1 had no
  nesting, so there's nothing to convert — but it's often the right target shape for a V1
  Blueprint that used `include_view` to build up layers.

```ruby
view :extended do
  field :description

  view :plus do            # rendered as MyBlueprint["extended.plus"]
    association :parts, [PartBlueprint]
  end
end
```

Redefining a view **appends** to it rather than replacing it. To replace, start the view with
`exclude fields: true`.

## `include_view` → `use`

```ruby
# V1
view :mobile do
  include_view :summary
  field :thumbnail
end

# V2
view :mobile do
  use :summary
  field :thumbnail
end
```

`include_views :a, :b` becomes `use :a, :b`.

A real behavioral difference: V1 merged included views as a set, so order mostly didn't matter.
V2's `use` **expands the partial in place**, so whatever comes after it wins. This usually
matches intent, but if a V1 view both `include_view`s something and overrides one of its fields,
make sure the override now comes *after* the `use`.

## `identifier`

V1's `identifier` created a field that was prepended to *every* view, plus a special
`:identifier` view containing only identifier fields. V2 has no such concept — but inheritance
reproduces it exactly, which is why it belongs on the base Blueprint:

```ruby
class ApplicationBlueprintV2 < Blueprinter::V2::Base
  field :id

  view :identifier do
    exclude fields: true
    field :id
  end
end
```

Per-Blueprint identifiers (`identifier :uuid` on one Blueprint) become `field :uuid` declared
first in that Blueprint, plus a local `:identifier` view if anything renders one.

`identifier` accepted `name:`, `extractor:`, and a block; those translate exactly as they do for
`field` (see `options.md`).

Two edge cases worth checking rather than assuming:

- V1 pinned identifier fields **first** in the output regardless of sort order. As a plain
  `field :id` on the base it's first by inheritance, so this holds — but only if the Blueprint
  doesn't `exclude fields: true`. If one does, re-declare `field :id` there.
- V1's `exclude :id` in a view removed the identifier. V2's `exclude :id` does the same.

## `transform`

V1 transformer classes keep working through an extension. Add it at the same level the
`transform` call was at — Blueprint-level transforms go on the class, view-level on the view:

```ruby
# V1
class WidgetBlueprint < Blueprinter::Base
  transform MyTransformer
end

# V2
class WidgetBlueprint < ApplicationBlueprintV2
  add Blueprinter::Extensions::LegacyTransformer.new(MyTransformer)
end
```

Multiple transformers go in one call: `LegacyTransformer.new(First, Second)`. The transformer's
`transform(hash, object, options)` signature is unchanged, and it mutates the hash in place as
before.

Leaving transformers on the legacy extension is a fine end state. The native alternative is an
`around_blueprint` hook, which is worth it only if the transformer is doing something the V1 API
made awkward.

One V1 quirk not reproduced: V1 fell back to `Blueprinter.configuration.default_transformers`
when a view declared none of its own. Port that global to the base Blueprint
(see `configuration.md`) rather than relying on a fallback.

## `exclude` / `excludes`

Unchanged — `exclude :field_name`, `excludes :a, :b`. V2 additionally supports categorical
exclusion of inherited things, which has no V1 equivalent but is often what a V1 "start from
scratch" view was faking:

```ruby
exclude fields: true, options: true, extensions: true, formatters: true
```

## `current_view`

`current_view` is gone. Inside a V2 Blueprint or view, use the class-level readers:

- `view_name` — this view's own name (`:default`, `:extended`)
- `view_path` — the full dotted path (`:default`, `:extended`, `:"extended.plus"`)
- `blueprint_name` — the fully-qualified name (`"WidgetBlueprint.extended"`)

From inside a block or hook, the same values are on `ctx.blueprint.class`.

## Partials (new in V2)

Not a conversion target, but frequently the better shape for a V1 Blueprint that leaned on
`include_view` for reuse, or that repeated the same field group across views:

```ruby
class WidgetBlueprint < ApplicationBlueprintV2
  partial :timestamps do
    fields :created_at, :updated_at
  end

  view :audit do
    use :timestamps
  end
end
```

Partials can be defined in a module (`extend Blueprinter::V2::DSL`) and included, which is the
natural home for field groups that V1 duplicated across Blueprints. Creating a view also creates
a partial of the same name, so views can `use` other views.

Propose this only when it genuinely simplifies; a migration diff is not the place for
speculative restructuring.

## Formatters (new in V2)

`format(Klass) { |val| ... }` or `format Klass, :method_name` applies to any field value of that
class (including subclasses). This is the replacement for `datetime_format` — see `options.md`
and `configuration.md`.

## Anonymous Blueprints

`Class.new(Blueprinter::Base) do ... end` becomes `Class.new(Blueprinter::V2::Base) do ... end`,
or `Class.new(ApplicationBlueprintV2)`. These are common in specs and easy to miss with grep
because they don't have a class name — the inventory script finds them, grep for
`Blueprinter::Base` also catches them.
