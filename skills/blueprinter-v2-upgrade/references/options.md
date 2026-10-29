# Field and association option conversion

Most V2 breakage hides in options rather than in the shape of the DSL, because an option that
silently stops applying produces valid-looking JSON. Work through this list for every Blueprint,
using the `v1_features` output from the inventory script to know which ones are actually in play.

The guiding rule: **convert natively when the translation is mechanical and local; keep the
compatibility extension when a faithful rewrite would mean restructuring real logic.** By that
rule `name`, `if`/`unless`, `default`, and `default_if` get converted; `extractor`, `transform`,
and dynamic association options keep their extension.

## Contents

- [`name:` → `source:`](#name--source)
- [`if` / `unless`](#if--unless)
- [`default` and `default_if`](#default-and-default_if)
- [`extractor:`](#extractor)
- [`datetime_format:`](#datetime_format)
- [`exclude_if_nil:`](#exclude_if_nil)
- [Dynamic association options (`options:`)](#dynamic-association-options)
- [The `view:` option on `render`](#the-view-option-on-render)
- [Where options can be set](#where-options-can-be-set)

## `name:` → `source:`

The argument order flips. V1 named the *source* and renamed the output; V2 names the *output*
and points at the source. Reading the V1 line backwards is the whole conversion:

```ruby
# V1: a field called "desc" that reads #description
field :description, name: :desc

# V2
field :desc, source: :description
```

Same for associations:

```ruby
# V1
association :cat, blueprint: CategoryBlueprint, name: :category

# V2
association :category, CategoryBlueprint, source: :cat
```

Two things to get right when converting:

- **Everything that referenced the field by name has to follow it.** `exclude :desc` in V1
  referred to the output name (`exclude` matches on `Field#name`), so it stays `exclude :desc`.
  But a field block's `ctx.field.source` is now `:description` where V1's `field_name` argument
  was `:desc`.
- **If you leave `name:` in place** (because `LegacyOptions` is already loaded for other
  reasons), it keeps working — but reflection reports it the V1 way, and the mixed style gets
  confusing fast. Prefer converting.

Note that reflection output changes with the conversion:
`MyBlueprint.reflections[:default].fields[:desc]` gives `name == :desc` and
`source == :description` in V2, where V1 gave `display_name == :desc` and `name == :description`.
If the app reflects over Blueprints (docs generation, schema export), that code needs updating
too.

## `if` / `unless`

V1 Procs took three arguments; V2 Procs take one context object.

```ruby
# V1
field :ssn, if: ->(field_name, object, options) { options[:current_user]&.admin? }

# V2
field :ssn, if: ->(ctx) { ctx.options[:current_user]&.admin? }
```

The three V1 arguments map to:

| V1 argument | V2 |
|---|---|
| `field_name` | `ctx.field.name` — the field's name *in the result* |
| `object` | `ctx.object` |
| `options` | `ctx.options` |

Use `ctx.field.name`, not `ctx.field.source`, when the old Proc actually used `field_name` — V1
passed the output name, which differs from the source wherever `name:` was set.

Symbols are the trap. **V1 `if:`/`unless:` symbols resolve to class methods; V2's resolve to
public instance methods.** A V2 Blueprint is instantiated once per render, so the method moves
off the singleton:

```ruby
# V1
field :ssn, if: :admin?

def self.admin?(_field_name, _object, options) = options[:current_user]&.admin?

# V2
field :ssn, if: :admin?

def admin?(ctx) = ctx.options[:current_user]&.admin?
```

If you convert the option but leave the method on the singleton, the render raises
`NoMethodError` — loud, at least.

Other V1 behavior worth preserving deliberately:

- A **field-level** `if`/`unless` overrode the global one entirely in V1. V2 is the same: a
  field-level option wins over the Blueprint-level option; they are not ANDed.
- `if: nil` explicitly set on a field was V1's way to opt out of a global `if`. In V2 the
  equivalent is `unset :if` on that Blueprint or view, or just not inheriting it.

`LegacyOptions` will keep V1-style Procs and class methods working if you'd rather defer (it
detects three-argument callables), but this conversion is mechanical — do it.

## `default` and `default_if`

Semantics are identical between versions: with no `default_if`, the default applies when the
value is `nil`; with one, it applies when the condition is true. Only the `default_if` *value*
changes.

```ruby
# V1
field :name,  default: 'N/A', default_if: Blueprinter::EMPTY_STRING
field :tags,  default: [],    default_if: Blueprinter::EMPTY_COLLECTION
field :meta,  default: {},    default_if: Blueprinter::EMPTY_HASH

# V2 — exact equivalents
field :name,  default: 'N/A', default_if: ->(_ctx, val) { val.to_s == '' }
field :tags,  default: [],    default_if: ->(_ctx, val) { val.is_a?(Enumerable) && val.empty? }
field :meta,  default: {},    default_if: ->(_ctx, val) { val.is_a?(Hash) && val.empty? }
```

Match the V1 predicate rather than writing something tidier. `EMPTY_STRING` is `value.to_s == ''`
— it catches `nil` and `0`-length strings but also any object whose `to_s` is empty.
`EMPTY_COLLECTION` only matches array-like values, which in V1 means `Array`,
`ActiveRecord::Relation`, and anything in `custom_array_like_classes`; `val.is_a?(Enumerable)` is
the closest V2 equivalent and is slightly broader. If a Blueprint relies on the narrow behavior,
spell out the classes.

When the same `default_if` appears many times, hoist it to a method on the base Blueprint and
pass the symbol — V2 resolves it as a public instance method taking `(ctx, value)`:

```ruby
class ApplicationBlueprintV2 < Blueprinter::V2::Base
  def empty_string?(_ctx, val) = val.to_s == ''
end

# then
field :name, default: 'N/A', default_if: :empty_string?
```

Two V1 behaviors that don't carry over on their own:

- **`default_if` with no `default`.** V1 fell back to `Blueprinter.configuration.field_default`
  (itself `nil` by default). V2 ignores `default_if` unless a `default` exists. If the app set a
  global `field_default`, port it with `set :default` on the base Blueprint
  (see `configuration.md`); otherwise add an explicit `default: nil`.
- **Defaults are not formatted or serialized.** In V2 a default value for a regular field skips
  formatters, and a default for an association is *not* run through the Blueprint. Usually what
  you want, but check any default that was a model object.

`default` also accepts a Proc taking `ctx`, or a symbol naming a public instance method taking
`ctx` — useful for the branch-on-type pattern described in `configuration.md`.

## `extractor:`

Keep these as-is and enable the extension on the V2 base:

```ruby
class ApplicationBlueprintV2 < Blueprinter::V2::Base
  add Blueprinter::Extensions::LegacyOptions.new
end

# unchanged in the Blueprint
field :weird, extractor: MyWeirdExtractor
field :other, extractor: MyWeirdExtractor.new
```

The extension preserves V1's semantics: the extractor is instantiated at most once per render,
and the field's block (if it has one) is handed to it in the `block` option. A Blueprint-level
`set :extractor, MyExtractor` covers every field in that Blueprint and its children, which is
how you port a global `extractor_default`.

Rewriting an extractor as a V2 extension (`around_field_value`, `around_object_value`,
`around_collection_value`) is a real refactor of working code with its own test surface. It is
not part of a migration — propose it separately if the user wants it.

Blueprinter's own built-in extractors (`AutoExtractor`, `PublicSendExtractor`, `HashExtractor`,
`BlockExtractor`, `AssociationExtractor`) are V1 internals. If a Blueprint passes one explicitly,
it is almost always re-stating the default; drop the option instead of carrying it forward. V2's
extraction already handles Hashes, `public_send`, and blocks.

## `datetime_format:`

V2 has **no field-level `datetime_format`**, and `LegacyOptions` does not cover it. This one
always needs a real change, and it's easy to miss because the field still renders — just
unformatted.

When a whole class of values formats the same way, use a formatter. Put it on the base Blueprint
if it was a global config, or on the individual Blueprint if it was per-field:

```ruby
format(Date)     { |d| d.strftime('%m/%d/%Y') }
format(DateTime) { |d| d.strftime('%m/%d/%Y') }
format(Time)     { |t| t.strftime('%m/%d/%Y') }
```

Declare each class you actually render. `format` matches by class and subclass, and `Date`,
`Time`, `DateTime`, and `ActiveSupport::TimeWithZone` are not in one hierarchy.

When one field formats differently from the rest, use a block — and keep the nil guard, because
V1's formatter passed `nil` straight through:

```ruby
# V1
field :shipped_on, datetime_format: '%Y-%m'

# V2
field(:shipped_on) { |widget| widget.shipped_on&.strftime('%Y-%m') }
```

A Proc-valued `datetime_format` converts the same way: `format(Date, &the_proc)` or inline it in
the block.

One difference not worth reproducing unless something depends on it: V1 raised
`InvalidDateTimeFormatterError` when a field with `datetime_format` returned a value that didn't
respond to `strftime`. V2's formatters simply don't match a non-Date value, and the block form
above returns `nil`. If a spec asserts on that error, it needs updating.

## `exclude_if_nil:`

Same name, same meaning, in both versions — leave it alone. V2 additionally lets you set it
Blueprint-wide with `set :exclude_if_nil, true`, which is the natural home for it when V1 repeated
the option on every field.

## Dynamic association options

V1's `options:` on an association merged a Hash or Proc result into the render options for that
association's subtree. Keep it, and add the extension **to the Blueprints that use it**, not to
the base — it does per-object work on every association it sees:

```ruby
class WidgetBlueprint < ApplicationBlueprintV2
  add Blueprinter::Extensions::LegacyDynamicOptions.new

  association :category, CategoryBlueprint, options: ->(widget) { { owner: widget.owner } }
end
```

Behavior matches V1: the Proc is called once per parent object and receives the *parent*, and the
merged options are visible only to that association and anything nested beneath it.

A static Hash (`options: { show_owner: true }`) works the same way and also needs the extension.

The native alternative is `ctx.store`, which is a different mechanism with different scoping
(render-wide, not subtree-scoped), so it is not a drop-in. Don't swap it in during a migration.

## The `view:` option on `render`

Covered in SKILL.md step 7 — `MyBlueprint.render(obj, view: :x)` becomes
`MyBlueprint[:x].render(obj)`. `LegacyOptions` keeps the V1 form working if the view name is
computed somewhere awkward, and when it does, the `:view` key stays in `ctx.options` exactly as
V1 left it — so conditionals and blocks that read `options[:view]` keep working. If you convert
the call sites instead, check for anything reading `options[:view]`, because it will now be
absent. `ctx.blueprint.class.view_name` is the replacement.

## Where options can be set

In V1, options were per-field plus a small set of globals. In V2, every option can be set at the
Blueprint, view, or partial level with `set`, and is inherited by children:

```ruby
set :exclude_if_nil, true
set :default, 'N/A'
set :if, ->(ctx) { ctx.object.visible? }
unset :default                 # in a child, to stop inheriting
```

Field-level options override Blueprint-level ones. This is what replaces global configuration —
see `configuration.md`.
