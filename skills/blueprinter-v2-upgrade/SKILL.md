---
name: blueprinter-v2-upgrade
description: Upgrade Blueprinter Legacy/V1 Blueprints (Blueprinter::Base) to the V2 DSL (Blueprinter::V2::Base), across a whole codebase or a selected subset, with V1 and V2 running side by side. Use this skill whenever someone mentions migrating, upgrading, porting, or converting Blueprints or Blueprinter serializers to V2; asks what a V1 Blueprint would look like in V2; is moving a `Blueprinter.configure` block onto a base Blueprint; hits a V2 breaking change (include_view, identifier, transform, the `name:` option, V1-style if/unless Procs, extractors, `render` returning something that isn't a String); or asks how to adopt Blueprinter V2 gradually. Use it even when they don't say "V2" or "migration" explicitly — "modernize our serializers" and "get us off the old Blueprinter DSL" are both this skill. Do not use it for Blueprinter work unrelated to V2 — writing new V2 Blueprints, adding views or fields to existing V1 Blueprints, performance tuning, or debugging V1 behavior where nothing has moved to V2 yet.
---

# Upgrading Blueprinter V1 Blueprints to V2

Blueprints serialize API responses. A conversion that *looks* right but reorders keys, drops a
field, or turns a `nil` into `{}` ships a silent API break that no one notices until a client
does. So this workflow is anchored on a **golden-output diff**: capture what the Blueprints
render before you touch anything, then prove the V2 versions render the same thing. Everything
else here exists to make that diff come back clean, or to make the differences deliberate.

Two facts make the migration far less scary than it sounds, and you should rely on both:

- **V1 and V2 interoperate in both directions.** A V2 Blueprint can do
  `association :category, V1CategoryBlueprint` (and `V1CategoryBlueprint[:extended]`), and a V1
  Blueprint can do `association :category, blueprint: V2CategoryBlueprint, view: :extended`. You
  never have to convert a Blueprint just because something points at it.
- **The two base classes coexist indefinitely.** Partial migration is a supported end state, not
  a temporary hack.

Before anything else, confirm V2 is actually available in the project — `Blueprinter::V2::Base`
must be defined. If it isn't, the installed Blueprinter is too old; the migration starts with a
gem upgrade.

> Commands below write bundled scripts as `$SKILL/scripts/…`. `$SKILL` is wherever this skill
> directory actually lives — it may be a symlink in `.claude/skills/`, a plugin cache, or inside
> the installed gem (`$(bundle show blueprinter)/skills/blueprinter-v2-upgrade`). Resolve it once
> and use the real path.

## Pick a mode

**Complete** — convert every V1 Blueprint. The base Blueprint is converted *in place*, global
`Blueprinter.configure` settings move onto it, and the configure block is deleted at the end.

**Partial** — convert a named subset. The V1 base Blueprint stays exactly as it is, and you add a
*parallel* V2 base alongside it (see step 5). `Blueprinter.configure` must stay, because the
remaining V1 Blueprints still read it.

If the user hasn't said which, infer it: a directory or a handful of class names means partial;
"migrate our Blueprints to V2" with no qualifier means complete. Confirm your reading in one line
rather than stopping to ask.

## Workflow

### 1. Take an inventory

Run the bundled inventory script. It boots the app, finds every Blueprint by walking
`ObjectSpace`, and reports each one's file, ancestry, views, and — most usefully — which V1-only
features it actually uses. That last part is what tells you whether a Blueprint is a two-minute
mechanical conversion or needs real thought.

```bash
bin/rails runner $SKILL/scripts/inventory.rb > /tmp/bp-inventory.json
```

For non-Rails projects, see the usage header in the script. If the app can't boot at all, fall
back to grepping for `Blueprinter::Base` and `< ApplicationBlueprint`-style subclasses, but say
so in your report — grep misses Blueprints built with `Class.new(Blueprinter::Base)` and can't
resolve inheritance chains.

Read the inventory before planning. The `v1_features` list per Blueprint drives everything after
this point.

### 2. Settle the scope

Start from what the user named, then close the set:

- **Ancestors.** A V2 Blueprint cannot inherit from a V1 Blueprint. Every ancestor up to
  `Blueprinter::Base` needs a V2 counterpart (step 5).
- **Descendants.** If `SpecialWidgetBlueprint < WidgetBlueprint` and you convert
  `WidgetBlueprint`, the subclass breaks. Descendants must be converted too — or, if the user
  wants them left alone, `WidgetBlueprint` has to stay V1 and you convert a copy instead. Flag
  this trade-off rather than silently expanding scope.
- **Associations are *not* in scope.** This is the main thing that keeps partial migrations
  small. Leave them.
- **Call sites are in scope.** `render` changed shape (step 7).

Write the resulting list down and show it to the user before converting, especially when
ancestors or descendants pulled extra Blueprints in.

### 3. Decide what happens to field order — ask the user

This is the one difference that affects *every* app and that nobody expects, so raise it
explicitly instead of picking for them.

V1 sorts a view's fields **alphabetically by their serialized name**, with `identifier` fields
pinned first, unless the app set `sort_fields_by = :definition`. V2 always serializes in
**definition order**. So unless the app opted into `:definition`, the JSON key order will change
for nearly every Blueprint. Values stay correct; key order does not.

Ask which they want:

- **Preserve V1 order exactly** — add the `FieldOrder` extension to the V2 base Blueprint. Zero
  diff in output, one extension to carry. The replication of V1's default is in
  `references/configuration.md`.
- **Adopt definition order** — accept the reordering. Fine when clients parse JSON properly (they
  should) and nothing snapshot-tests raw response bodies. Check for response-body snapshot tests
  before recommending this.
- **Adopt definition order, but declare fields alphabetically** — same output as V1 with no
  extension, at the cost of a once-and-done reshuffle of each Blueprint's field declarations.
  Only practical for small scopes.

If the app already set `sort_fields_by = :definition`, say so and skip the question — order
already matches.

This is the only question worth stopping for; decide everything else yourself and report it. And
if you can't ask — the run is unattended, or the user has said to just get on with it — **preserve
V1's order**. It's the choice that can't break a client, and it's trivially reversible later by
deleting one extension.

### 4. Capture the baseline

Do this **before** editing any Blueprint. Read `references/verifying.md` and follow it: you write
a small fixtures file naming the Blueprints, views, and sample objects to exercise, then run
`scripts/snapshot.rb` to dump rendered output to a baseline directory.

The script deliberately renders through whichever API the Blueprint currently has (V1
`render_as_hash(obj, view:)` or V2 `Blueprint[view].render(obj).to_hash`), so the *same fixtures
file* works unchanged before and after conversion. That's what makes the diff meaningful.

Fixtures must be deterministic — hand-built Hashes or Structs, or `Model.find(fixed_id)`. Random
factory data produces a diff full of noise and hides the real changes. Cover, for each Blueprint:
a fully-populated object, one with `nil` associations and `nil`/empty fields, and an empty
collection. Those are where V1 and V2 diverge.

### 5. Set up the V2 base Blueprint

Almost every app has an `ApplicationBlueprint`. Its V2 counterpart is where global configuration
lands, because **V2 never reads `Blueprinter.configuration`** — this is the single most common
source of behavior changes in a migration.

- **Complete mode:** convert `ApplicationBlueprint` in place to inherit from
  `Blueprinter::V2::Base`.
- **Partial mode:** leave the V1 base untouched and add a sibling, `ApplicationBlueprintV2`
  (match the codebase's conventions if it has one). Converted Blueprints keep their own names, so
  nothing downstream changes. When the last V1 Blueprint is eventually converted, the two bases
  merge back into one.

Work through every setting in the app's `Blueprinter.configure` block and port it — the full
mapping is in `references/configuration.md`. Pay particular attention to `sort_fields_by` (step
3), `field_default`/`association_default`, and global `if`/`unless`, since those silently apply to
every Blueprint and are easy to forget.

Also replicate V1's `identifier` behavior here if the app uses it:

```ruby
class ApplicationBlueprintV2 < Blueprinter::V2::Base
  field :id

  view :identifier do
    exclude fields: true
    field :id
  end
end
```

### 6. Convert each Blueprint

Prefer **native V2** wherever the translation is mechanical and local — `name:` → `source:`,
if/unless, `default`/`default_if`, association syntax, `include_view` → `use`. The result reads
like V2 and carries no extra machinery.

Reach for a **compatibility extension** where a faithful native rewrite would mean restructuring
real logic: extractors, transformers, and dynamic association options. Those stay as they are,
with the extension doing the adapting. They're supported, not deprecated, so leaving them is a
legitimate end state rather than debt — don't litter the code with TODOs telling the next person
to rewrite working code.

Quick reference (details and edge cases in `references/dsl.md` and `references/options.md`):

| V1 | V2 | Notes |
|---|---|---|
| `< Blueprinter::Base` | `< Blueprinter::V2::Base` | or your V2 base |
| `association :c, blueprint: B` | `association :c, B` | |
| `association :c, blueprint: B, view: :v` | `association :c, B[:v]` | |
| a collection association | `association :cs, [B]` | V2 encodes cardinality in the DSL |
| `field :description, name: :desc` | `field :desc, source: :description` | the arg is the *output* name now |
| `include_view :other` | `use :other` | |
| `identifier :id` | `field :id` on the base + `:identifier` view | step 5 |
| `if: ->(name, obj, opts) { }` | `if: ->(ctx) { }` | `ctx.field.name`, `ctx.object`, `ctx.options` |
| `if: :a_class_method` | `if: :an_instance_method` taking `ctx` | V1's were class methods |
| `default_if: Blueprinter::EMPTY_STRING` | `default_if: ->(ctx, val) { val.to_s == '' }` | exact equivalents in `references/options.md` |
| `datetime_format: '%Y'` | `format Date, ...` or a field block | no field-level option in V2 |
| `transform MyTransformer` | `add Blueprinter::Extensions::LegacyTransformer.new(MyTransformer)` | |
| `extractor: MyExtractor` | unchanged, + `add Blueprinter::Extensions::LegacyOptions.new` | |
| `association ..., options: ->(o) { }` | unchanged, + `add Blueprinter::Extensions::LegacyDynamicOptions.new` | add per-Blueprint, not to the base |
| `exclude` / `excludes` | unchanged | |

Two structural changes that aren't a line-for-line swap:

- **An explicit `view :default do ... end`** — move its contents to the class body. In V2 the
  class body *is* the default view.
- **A `field` block that renders another Blueprint** — make it an `association`. V1 had no better
  option; V2 does, and you get correct nil/collection handling for free.

Add `Blueprinter::Extensions::LegacyOptions` to the V2 base only if something in scope needs it —
after native conversion that's usually just extractors, plus V1-style `render(obj, view:)` if you
chose to leave call sites alone.

Convert ancestors before descendants, and the base before everything.

### 7. Update call sites

In V2, `render` returns a `Blueprinter::V2::Render`, not a String.

```ruby
MyBlueprint.render(widget)                 # V1: a JSON String
MyBlueprint.render(widget).to_json         # V2: a JSON String
MyBlueprint.render(widget).to_hash         # V2: a Hash (or Array)
MyBlueprint.render(widget, view: :x)       # V1
MyBlueprint[:x].render(widget).to_json     # V2
```

`render json: MyBlueprint.render(widget)` in a Rails controller needs **no change** — Rails calls
`to_json` for you. Leave those alone; changing them adds diff noise for nothing.

`render_as_hash` and `render_as_json` still exist and still work. They're soft-deprecated, so
prefer `.to_hash` / `.to_json` in code you're already touching, but don't go hunting for them.

Search beyond controllers: serializer specs, jobs, presenters, GraphQL resolvers, and anywhere a
Blueprint's output is string-interpolated or compared are the places that break.

### 8. Verify

Re-run the *same* snapshot script against the converted code into a second directory, then diff:

```bash
bin/rails runner $SKILL/scripts/snapshot.rb fixtures.rb /tmp/bp-after
python3 $SKILL/scripts/compare_snapshots.py /tmp/bp-before /tmp/bp-after
```

The comparator separates **value differences** (added keys, removed keys, changed values — always
bugs unless you can explain them) from **key-order-only differences** (expected and harmless if
the user chose definition order in step 3; a bug if they chose to preserve order).

Then run the project's test suite. The snapshot diff and the suite catch different things: the
diff catches silent output changes in untested Blueprints, the suite catches call sites and
integration breakage.

Do not report the migration as done while the diff has unexplained entries.

### 9. Report

Say plainly:

- which Blueprints were converted, and which were deliberately left on V1
- what the snapshot diff showed, and for every remaining difference, why it's intentional
- which compatibility extensions you added and what each one is covering
- what the user still needs to decide or check — in partial mode, that `Blueprinter.configure`
  must stay until the last V1 Blueprint is gone

## References

Read these as you need them; don't front-load them.

- `references/dsl.md` — the DSL surface: fields, associations, views, partials, `identifier`,
  `transform`, field blocks, and the `ctx` object that replaced the old block arguments.
- `references/options.md` — field and association options: `name`, `if`/`unless`, `default` and
  `default_if`, `extractor`, `datetime_format`, `exclude_if_nil`, dynamic association options.
- `references/configuration.md` — every `Blueprinter.configure` setting and where it goes in V2,
  including the exact `FieldOrder` replication of V1's field sorting.
- `references/extensions.md` — porting custom V1 `pre_render` extensions to V2's hook system, and
  what each bundled extension does.
- `references/verifying.md` — how to write the fixtures file and run the golden-output diff.
