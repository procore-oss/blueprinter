# Verifying a conversion with a golden-output diff

A Blueprint migration either produces byte-identical JSON or it produces a change you chose. The
only way to know which is to render the Blueprints before you touch them and compare.

This matters more than a test suite because most of what breaks in a V1 → V2 migration breaks
*quietly*: a global config setting that no longer applies, an extension that registers but never
runs, an association declared as an object when it's a collection, a `name:` that got converted
backwards. All of those produce well-formed JSON.

## The workflow

```bash
# 1. before touching anything
bin/rails runner $SKILL/scripts/snapshot.rb bp_fixtures.rb tmp/bp-before

# 2. convert

# 3. the same fixtures file, unchanged
bin/rails runner $SKILL/scripts/snapshot.rb bp_fixtures.rb tmp/bp-after

# 4. diff
python3 $SKILL/scripts/compare_snapshots.py tmp/bp-before tmp/bp-after
```

The fixtures file works on both sides because `snapshot.rb` renders through whichever API each
Blueprint currently has — V1's `render_as_hash(obj, view:)` or V2's
`Blueprint[view].render(obj).to_hash`. You don't rewrite it mid-migration, and you shouldn't:
rewriting it is how you accidentally make the diff agree with itself.

Keep the fixtures file and both output directories out of version control (`tmp/` is a good
home in Rails) unless the user wants the snapshots committed as regression fixtures — which is
a reasonable thing to offer at the end.

## Writing the fixtures file

It's a plain Ruby file whose last expression is an Array of Hashes:

```ruby
WIDGET = {
  name: 'Widget',
  description: 'A widget',
  created_at: Time.utc(2024, 1, 15, 12, 0, 0),
  category: { name: 'Tools', description: 'Hand tools' },
  parts: [{ name: 'Bolt' }, { name: 'Nut' }]
}.freeze

[
  {
    blueprint: WidgetBlueprint,
    views: [:default, :extended],          # optional; defaults to every view
    options: { current_user: nil },        # optional; passed to render
    samples: {
      'full'     => -> { WIDGET },
      'nils'     => -> { { name: 'Widget', description: nil, category: nil, parts: nil } },
      'empties'  => -> { { name: '', description: '', category: {}, parts: [] } },
      'list'     => -> { [WIDGET, WIDGET] }
    }
  },
  {
    blueprint: CategoryBlueprint,
    samples: { 'full' => -> { WIDGET[:category] } }
  }
]
```

### Samples must be deterministic

Random factory data produces a diff full of noise that hides the real changes. Use hand-built
Hashes or Structs, or `Model.find(fixed_id)` against a seeded database.

Plain Hashes are usually the best choice: Blueprinter will render anything that responds to the
right methods, so you rarely need real models, and a literal Hash makes the sample's shape
obvious to whoever reads the diff later. Switch to real models only when the Blueprint depends
on model behavior — computed methods, delegated attributes, association loading.

### Cover the cases where V1 and V2 diverge

For each Blueprint, include at minimum:

- **Fully populated** — catches `name:`/`source:` inversions, missing fields, wrong views on
  associations, and formatter changes.
- **`nil` associations and `nil` field values** — catches `default` / `field_default` /
  `association_default` regressions and `exclude_if_nil` changes.
- **Empty string, empty Hash, empty collection** — catches `default_if` conversions, which are
  the easiest thing in this migration to get subtly wrong.
- **A collection at the top level** — catches an association declared as `B` where it should be
  `[B]`.

If the Blueprint has conditionals driven by render options, add one sample per branch by
duplicating the entry with different `options`.

### Use the inventory to decide what to cover

The `v1_features` list from `inventory.rb` tells you which samples each Blueprint actually needs.
A Blueprint with no features beyond plain fields needs one sample; one using `default_if`,
`datetime_format`, and a V1 conditional needs the full set.

## Reading the diff

The comparator splits findings in two:

**VALUE DIFFERENCES** — added keys, removed keys, changed values, length changes, render errors.
Every one is a bug until you can explain it. Common causes, in rough order of frequency:

| Symptom | Likely cause |
|---|---|
| a field's value and the one next to it swapped | `name:` → `source:` converted backwards |
| a formatted date became an ISO string or a raw object | `datetime_format` not ported (`options.md`) |
| `nil` where there used to be `"N/A"` or `{}` | global `field_default` / `association_default` not ported (`configuration.md`) |
| `""` where there used to be a default | `default_if` constant converted wrong, or `default_if` with no `default` |
| a field appeared that used to be filtered out | global `if`/`unless` not ported, or an `if:` symbol still a class method |
| an association serialized as a raw object or a list of nulls | `[B]` vs `B` cardinality |
| a field that used to be absent now renders as `null` | `exclude_if_nil` lost |
| whole object unchanged by a transformer | V1 extension's `pre_render` never runs in V2 (`extensions.md`) |
| `__error__` in a snapshot | the render raised; the message says what |

**KEY ORDER ONLY** — the same keys and values in a different order. This is the expected
consequence of V1's alphabetical sort (identifiers first) versus V2's definition order. Whether
it's acceptable is the decision from SKILL.md step 3:

- Chose definition order → expected, note it in the report and move on.
- Chose to preserve V1 order → a bug. Add or fix the `FieldOrder` extension
  (`configuration.md`), then re-run with `--strict-order` so order differences fail the check.

## Then run the test suite

The snapshot diff and the test suite catch different things. The diff catches silent output
changes in Blueprints nothing tests. The suite catches call sites — `render` now returning a
`Render` object rather than a String is the big one — plus controllers, jobs, and anything that
reflects over Blueprints.

Run both. Don't report the migration as done while either is failing or while the diff has
differences you can't account for.

## When the app can't boot

If `rails runner` isn't available, the same approach still works at a smaller scale: write a
standalone script that requires `blueprinter` and the Blueprint files directly, defines the
sample Hashes inline, and prints `JSON.pretty_generate` of each render. Capture it before and
after and `diff` the two files. You lose the structured comparison but keep the thing that
matters — evidence that the output didn't change.

Say in your report that verification was limited, and which Blueprints went uncovered.
