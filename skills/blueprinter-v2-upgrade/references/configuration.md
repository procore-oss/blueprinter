# Global configuration → V2 base Blueprint

**V2 never reads `Blueprinter.configuration`.** Nothing warns you about this. Every setting in
the app's `Blueprinter.configure` block silently stops applying the moment a Blueprint moves to
V2, and most of those settings change output rather than raising.

This is the highest-risk part of the migration. Open the configure block — usually
`config/initializers/blueprinter.rb` — and port every key, including the ones that look
harmless.

Two settings apply even when the app never configured them, because their V1 defaults aren't
V2's: `sort_fields_by` (`:name_asc`) and `extractor_default` (`AutoExtractor`). The first changes
key order in every response.

In **partial** mode the configure block must stay — the remaining V1 Blueprints still read it —
so each setting ends up expressed twice until the migration finishes. Say this in the report so
nobody "cleans up" the duplicate.

## Mapping

| V1 config | V2 equivalent, on the base Blueprint |
|---|---|
| `sort_fields_by` | `FieldOrder` extension (below) |
| `field_default` | `set :default, …` |
| `association_default` | `set :default, …` (same option — see below) |
| `if` / `unless` | `set :if, ->(ctx) { … }` |
| `datetime_format` | `format Date, …` / `format Time, …` / `format DateTime, …` |
| `default_transformers` | `add Blueprinter::Extensions::LegacyTransformer.new(…)` |
| `extractor_default` | `add Blueprinter::Extensions::LegacyOptions.new` + `set :extractor, …` |
| `generator` / `method` | `MultiJson` extension, or a custom `around_result` extension |
| `custom_array_like_classes` | `render_collection` at the call site |
| `extensions` | `add MyExtension.new` (hooks must be ported — see `extensions.md`) |
| `deprecations` | no equivalent; V2 has no deprecation machinery |

## `sort_fields_by`

V1's default is `:name_asc`: fields sorted alphabetically **by serialized name**, with
`identifier` fields pinned first in declaration order. V2 always uses definition order.

If the app set `sort_fields_by = :definition`, orders already match and there is nothing to do.
Otherwise this is the field-order decision in SKILL.md step 3. To preserve V1's output exactly:

```ruby
class ApplicationBlueprintV2 < Blueprinter::V2::Base
  add Blueprinter::Extensions::FieldOrder.new { |a, b|
    if a.name == :id
      -1
    elsif b.name == :id
      1
    else
      a.name <=> b.name
    end
  }
end
```

That block replicates "alphabetical, `id` first". Adjust the pinned name if the app's
`identifier` is something else (`:uuid`), and extend the comparator if a Blueprint declares
several identifiers — those came out in declaration order, not alphabetically.

## `field_default` and `association_default`

V1 had two settings; V2 has one `:default` option that covers fields, objects, and collections.
When the app set both to the same value, one `set :default` is the whole translation. When they
differ, branch on the field type:

```ruby
set :default, ->(ctx) {
  case ctx.field.type
  when :field               then 'N/A'   # field_default
  when :object, :collection then {}      # association_default
  end
}
```

V1 used the single `association_default` for both objects *and* collections, so the branch above
is the faithful translation even though an empty collection rendering as `{}` looks wrong. If the
user would rather have `[]` for collections, that's a deliberate output change — call it out and
let them decide, don't fix it quietly.

Remember that `field_default` also backstopped `default_if` on fields that declared no `default`
of their own (see `options.md`). Porting the global covers those cases too.

One V1 behavior you should *not* reproduce: a global `field_default` leaked into associations.
V1 resolved an association's value through the field extractor first, so a `nil` association
became the `field_default` value and was then handed to the associated Blueprint — which usually
raised `NoMethodError` on the default. Apps with `field_default` set therefore couldn't have
`nil` associations at all. In V2 a default is never run through the Blueprint, so the same
config just works. If the baseline snapshot shows a V1 render raising here and the V2 one
succeeding, that's the fix, not a regression — note it in the report.

## `if` / `unless`

```ruby
# V1
Blueprinter.configure do |config|
  config.if = ->(field_name, object, options) { options[:current_user].present? }
end

# V2
class ApplicationBlueprintV2 < Blueprinter::V2::Base
  set :if, ->(ctx) { ctx.options[:current_user].present? }
end
```

The argument mapping is the same as for field-level conditionals (`options.md`): `field_name` →
`ctx.field.name`, `object` → `ctx.object`, `options` → `ctx.options`.

As in V1, a field that declares its own `if` ignores the inherited one rather than ANDing with
it.

## `datetime_format`

```ruby
# V1
config.datetime_format = '%Y-%m-%d'

# V2
class ApplicationBlueprintV2 < Blueprinter::V2::Base
  format(Date)     { |d| d.strftime('%Y-%m-%d') }
  format(DateTime) { |d| d.strftime('%Y-%m-%d') }
  format(Time)     { |t| t.strftime('%Y-%m-%d') }
end
```

Declare every class the app actually renders — `Date`, `Time`, `DateTime`, and
`ActiveSupport::TimeWithZone` do not share one hierarchy, so a single `format Date` silently
misses the others. Check what the models return before trimming the list.

A `Proc`-valued `datetime_format` becomes the formatter block directly.

## `default_transformers`

```ruby
# V1
config.default_transformers = [MyTransformer, OtherTransformer]

# V2
add Blueprinter::Extensions::LegacyTransformer.new(MyTransformer, OtherTransformer)
```

V1 applied these only to views that declared no transformers of their own. On the V2 base the
extension is inherited by everything, so a Blueprint that had its own `transform` would now run
both. Where that happens, `remove Blueprinter::Extensions::LegacyTransformer` in that Blueprint
before adding its own — and verify it against the snapshot, because double-transforming is
exactly the kind of bug that produces plausible output.

## `extractor_default`

```ruby
# V1
config.extractor_default = MyExtractor

# V2
class ApplicationBlueprintV2 < Blueprinter::V2::Base
  add Blueprinter::Extensions::LegacyOptions.new
  set :extractor, MyExtractor
end
```

If the app never set this, the default was `Blueprinter::AutoExtractor`, whose behavior (Hash
keys, `public_send`, blocks) V2 already does natively. Don't port it.

## `generator` / `method`

```ruby
# V1
config.generator = Oj
config.method = :dump

# V2 — if the serializer is multi_json-compatible
class ApplicationBlueprintV2 < Blueprinter::V2::Base
  add Blueprinter::Extensions::MultiJson.new   # must be the FIRST extension added
end
```

Order matters: `MultiJson` has to be added before any other extension. If the serializer isn't
multi_json-compatible, write an `around_result` extension — there's a worked example in
`extensions.md`.

If the app left these at the defaults (`JSON` / `:generate`), there's nothing to port.

## `custom_array_like_classes`

No configuration equivalent. V2 treats any `Enumerable` except `Hash` as a collection, which
covers most of what this setting existed for. For anything that isn't `Enumerable`, force it at
the call site:

```ruby
WidgetBlueprint.render_collection(weird_thing).to_json
WidgetBlueprint.render_object(weird_thing).to_json
```

This also affects `EMPTY_COLLECTION` conversions — see `options.md`.

## `extensions`

```ruby
# V1
config.extensions = [MyExtension.new]

# V2
class ApplicationBlueprintV2 < Blueprinter::V2::Base
  add MyExtension.new
end
```

A V1 extension only implements `pre_render`, which V2 never calls — it will be added
successfully and then do nothing at all. Port the hooks; see `extensions.md`.

In partial mode the extension has to work under both APIs simultaneously. `extensions.md` shows
the dual-API shape.

## Removing the configure block

Only in **complete** mode, and only after the snapshot diff is clean. Then delete the
initializer, or trim it to the keys V1 still needs if any `Blueprinter::Base` usage remains
anywhere (including in gems and in specs).
