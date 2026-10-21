---
title: "Making Changes"
type: how-to
description: "Take a change from idea to mergeable PR: what every PR needs, and where each kind of change belongs in the code."
generated: { by: claude-code/claude-opus-5-5, at: "2026-10-21T21:35:53Z" }
verified:
  - { by: human:lessthanjacob, at: "2026-10-21T22:30:20Z" }
---

# Making Changes

Terms such as definition, compilation, render, `local_options`, and snapshot are defined in [architecture.md](architecture.md).

## Every Change

Every PR goes through the same gate, so check these before asking for review:

- `bundle exec rake` passes (specs and `RuboCop`; see [testing.md](testing.md#run-the-checks)).
- Every commit carries a DCO `Signed-off-by` trailer whose email matches your primary GitHub email (`git commit -s`; see [CONTRIBUTING.md](../CONTRIBUTING.md)). Every PR runs a DCO check.
- Every user-facing change adds a line under `## Unreleased` in `CHANGELOG.md` ([format](releasing.md#changelog-format)), updates YARD for public methods, and updates the matching README `<details>` section for any DSL or configuration change.
- Text under `docs/` or in `AGENTS.md` that describes the changed behavior is updated in the same PR ([writing-docs.md](writing-docs.md#keeping-docs-current)).
- Feature PRs _never_ bump `lib/blueprinter/version.rb`, since merging a version change to `main` publishes a gem ([releasing.md](releasing.md)).
- `Gemfile.lock` is git-ignored and never committed. Actions in `.github/workflows/` are pinned by SHA and bumped by Dependabot, not by hand.

## Where a Change Belongs

Blueprinter does its work in three **phases** (definition, compilation, and render), and each kind of change lives in one of them. Knowing the phase tells you which file to open:

| Goal | Where | Phase |
|---|---|---|
| Add a per-field or per-association option | Pass it through `field` / `association` in `lib/blueprinter/base.rb`; read it in an extractor or `lib/blueprinter/rendering.rb` | Definition + render |
| Change which fields a view has, or their order | `lib/blueprinter/view_collection.rb`, `view.rb` | Compilation |
| Change how values are read from objects | `AutoExtractor`, or a new extractor in `lib/blueprinter/extractors/` | Render |
| Change how associations render | `lib/blueprinter/extractors/association_extractor.rb` | Render |
| Add a global default | `lib/blueprinter/configuration.rb`, plus wherever it's read ([configuration.md](configuration.md)) | Varies |
| Run code before rendering | `lib/blueprinter/extension.rb`, `extensions.rb`, and the call in `rendering.rb` | Render |
| Add a failure mode | A new error under `lib/blueprinter/errors/` | Render |

## Add a Field or Association Option

A field stores _every_ option it's given and hands the whole hash to its extractor on each render, so adding an option is mostly a question of where to read it. `:exclude_if_nil`, for example, is read in `Rendering#object_to_hash`, right after extraction:

```ruby
value = field.extract(object, local_options)
next if value.nil? && field.options[:exclude_if_nil]
```

1. Pick where to read it using [Where a Change Belongs](#where-a-change-belongs). Other models: `:default_if` is read in the extractors, and `:if` / `:unless` in `Field#skip?`.
2. Read it without allocating per field (this code runs once per field per object). Anything you can work out once per field goes in an `@_`-prefixed memo, as `Field#if_callable` does (`RuboCop` requires the underscore):

   ```ruby
   def if_callable
     @_if_callable ||= callable_from(:if)
   end
   ```

3. If the option changes the `local_options` a nested blueprint receives, do it in `AssociationExtractor#merge_association_options`, the one place association options are merged. A new key in `local_options` is **breaking**, because field blocks receive those keys as keyword arguments ([public API](architecture.md#public-api-and-compatibility)).
4. Pick a name that doesn't collide with the [reserved keys](extension-points.md#reserved-field-option-keys), since user options share the same hash.
5. Add a YARD `@option` entry to the DSL method in `base.rb`.
6. Test it in the **shared examples** when it must hold for every object type, or directly in `base_spec.rb` when it's specific to associations or `ActiveRecord` ([where a test goes](testing.md#add-a-test)).
7. Run `bundle exec rake benchmarks`, since the option is read on the render path.

## Add a DSL Method on Base

DSL methods run while a class body is evaluated, and write to whichever view is current, so they need to respect `view` blocks and the compiled snapshot.

1. Define it under `class << self` in `lib/blueprinter/base.rb`, writing through `current_view` so it honors `view` blocks.
2. Decide whether it must invalidate the snapshot. Changes inside a `view` block are covered (`Base.view` invalidates after its block), but direct changes to `:default` after a render are not. Call `view_collection.invalidate_cache!` if the method can run after rendering has started.
3. If the new state should reach subclasses, extend `View#inherit`.
4. If it affects field order under `sort_fields_by = :definition`, call `track_definition_order`.
5. Unit test it in `spec/units/view_spec.rb` or `view_collection_spec.rb` and add an integration test in `base_spec.rb`.

## Add a Configuration Option

Configuration is global and some options are read only once, so the hard part of a new option is deciding (and documenting) when it's read.

1. Add the accessor and its default to `lib/blueprinter/configuration.rb`.
2. Read it at the right moment. Options read at render time can change at any point; options read when views are created, or memoized on first use, _must_ be set before blueprints are defined or rendered. Say which in the README, the YARD comment, and [configuration.md](configuration.md#when-a-change-takes-effect).
3. Add a case to `spec/units/configuration_spec.rb`, and reset the configuration after it ([testing.md](testing.md#configuration)).

## Add an Extension Hook

Every registered extension receives every hook, so a new hook affects existing extensions, not just new ones. `pre_render` is the model to copy:

```ruby
# lib/blueprinter/extension.rb: a no-op default
def pre_render(object, _blueprint, _view, _options)
  object
end

# lib/blueprinter/extensions.rb: pass the object through each extension in turn
def pre_render(object, blueprint, view, options = {})
  @extensions.reduce(object) do |acc, ext|
    ext.pre_render(acc, blueprint, view, options)
  end
end
```

1. Add the no-op default to `Blueprinter::Extension` and the matching method to `Blueprinter::Extensions`.
2. Call it from `lib/blueprinter/rendering.rb` at the right point. `pre_render` is called from `hashify`, so it fires for associated objects too; a call in `build_result` would fire only at the top level.
3. Extensions don't have to subclass `Blueprinter::Extension`, and any that don't will raise `NoMethodError` on the new hook. That makes a new hook **breaking** for them, so say so in the CHANGELOG.
4. Unit test it in `spec/units/extensions_spec.rb`, and document it under README "Available Hooks".

## Add an Extractor

Extractor instances are reused across every field that names them, so set up anything expensive once. The contract and a worked example are in [extension-points.md](extension-points.md#extractor).

1. Subclass `Blueprinter::Extractor` and implement `extract`.
2. Build helper objects in `initialize`, as `AutoExtractor` does.
3. To add a case to the default extractor, subclass `AutoExtractor`, override `extractor(object, options)`, and set `config.extractor_default` (README "Configurable Extractors").
4. Test it with the `extractor:` contexts in the shared examples and in `base_spec.rb`.

## Add an Error Class

Every Blueprinter error subclasses `BlueprinterError`, so existing `rescue Blueprinter::BlueprinterError` blocks keep working while callers can rescue the new case on its own (for example, `Errors::UnknownView` lets apps answer a bad view name with a 400 without also catching server faults). The smallest example is the whole file:

```ruby
# lib/blueprinter/errors/unknown_view.rb
module Blueprinter
  module Errors
    class UnknownView < BlueprinterError; end
  end
end
```

1. Add the class in its own file under `lib/blueprinter/errors/` (`invalid_root.rb` shows one with a default message).
2. Make it loadable: either add an `autoload` line to `lib/blueprinter/errors.rb` (as for `InvalidBlueprint`), or `require` it where it's raised (as `rendering.rb` does for `InvalidRoot` and `MetaRequiresRoot`).
3. Raise it from the narrowest point that has the information, with a message the caller can act on (`UnknownView` names the view).
4. Spec the class and message in `spec/integrations/base_spec.rb`.

## Add a Deprecation

Public methods can't be removed outright ([public API](architecture.md#public-api-and-compatibility)), so a removal starts with a warning that ships at least one release earlier. `prepare` is the current example:

```ruby
def prepare(object, view_name:, local_options:)
  Blueprinter::Deprecation.report(
    <<~MESSAGE
      The `prepare` method is no longer supported will be removed in the next minor release.
      If similar functionality is needed, use `.render_as_hash` instead.
    MESSAGE
  )
  render_as_hash(object, view_name:, local_options:)
end
```

1. Keep the old behavior working.
2. Call `Blueprinter::Deprecation.report` at the deprecated call site, naming the replacement and the release that will remove it.
3. Tag the method `@deprecated` in YARD, and add a CHANGELOG entry in the release that introduces the warning.
4. Spec the exact message ([testing.md](testing.md#deprecations)).
5. Remove it in a later minor or major release, with a ‼️ `[BREAKING]` entry.

## Common Mistakes

- Reading the view from an extractor's fourth argument. That's the field's own options; the view is in `local_options[:view]`.
- Passing an `:if` / `:unless` value that's neither a `Proc` nor a `Symbol`. It raises `ArgumentError` at the first render, not when the field is defined.
