---
title: "Configuration Reference"
type: reference
description: "Find out what a configuration option does and when changing it takes effect."
generated: { by: cursor/claude-fable-5.1, at: "2026-10-23T14:00:43Z" }
verified:
  - { by: human:lessthanjacob, at: "2026-10-21T22:30:20Z" }
---

# Configuration Reference

**Configuration** is global, and several options are read only once, so _when_ you set an option matters as much as its value. Read it with `Blueprinter.configuration`, change it with `Blueprinter.configure { |config| ... }`, and restore the defaults with `Blueprinter.reset_configuration!`. The options live in `lib/blueprinter/configuration.rb`.

## Options

| Option | Default | Read by |
|---|---|---|
| `association_default` | `nil` | `AssociationExtractor`, when an association's value is `nil` (or matches `:default_if`) and the association sets no `:default` |
| `custom_array_like_classes` | `[]` | `Configuration#array_like_classes`, which treats these classes like `Array` when rendering a collection. The writer clears the memoized list |
| `datetime_format` | `nil` | `Field#compile`, which keeps a field off the plain-field path while a format is set, and `DateTimeFormatter` when a field sets no `:datetime_format`. A `String` is passed to `strftime`, a `Proc` is called, and anything else raises `InvalidDateTimeFormatterError` |
| `default_transformers` | `[]` | `ViewCollection#build_transformers`, only when a view has no transformers of its own, including inherited and included ones. Any transformer on the blueprint replaces these rather than adding to them |
| `deprecations` | `:stderror` | `Deprecation.report`. Accepted values are `:silence`, `:stderror`, and `:raise`; anything else behaves as `:stderror` |
| `extensions` | empty | `Rendering#hashify`. The writer wraps the given `Array` without copying it, and `<<` appends |
| `extractor_default` | `AutoExtractor` | `Configuration#default_extractor`, which memoizes one instance; the writer resets that memo. Each field copies that instance when the field is defined |
| `field_default` | `nil` | `Field#compile`, which keeps a field off the plain-field path while a default is set, and `AutoExtractor` when an extracted value is `nil` (or matches `:default_if`) and the field sets no `:default` |
| `generator` | `JSON` | `Configuration#jsonify`, as `generator.public_send(method, data)`, in `render` only |
| `if`, `unless` | `nil` | `Field#compile`, which checks that a condition is present, and `Field#skip?`, which resolves it. A field-level callable wins. A `Proc`, or a `Symbol` naming a method on the blueprint class. The symbol is resolved on the first `skip?` of that field |
| `method` | `:generate` | `Configuration#jsonify` |
| `sort_fields_by` | `:name_asc` | `View` and `ViewCollection` when they are created; `:definition` sorts by definition order and any other value sorts by name |

## When a Change Takes Effect

Surprises come from changing an option after it has already been read:

- Set before any blueprint is defined: `sort_fields_by` and `extractor_default`. Both are read when views and fields are created, so blueprints defined earlier keep the old value. Neither bumps the configuration generation, and a later write does not rebuild existing blueprints. Changing `sort_fields_by` away from `:definition` after a blueprint was defined with it is _worse_ than ignored: views created later in that blueprint drop their own fields, because they no longer track definition order. `extractor_default` is copied onto each field, and each blueprint's `AssociationExtractor` copies the default extractor, when that field or association is defined.
- Take effect on the next render, because the writer bumps the generation and the next render rebuilds the compiled pipeline: `datetime_format`, `default_transformers`, `field_default`, `if`, and `unless`. Setting `if` or `unless` where none was set moves the affected fields off the plain-field path on that rebuild; a field that has already resolved a condition keeps it.
- Takes effect on the next render without bumping the generation: `custom_array_like_classes`. Its writer clears the memoized class list, and no compiled pipeline depends on it.
- Read on every render, so they take effect immediately: `association_default`, `deprecations`, `extensions`, `generator`, and `method`.
- `reset_configuration!` installs a fresh `Configuration` and bumps the generation, so the next render rebuilds.

## Notes

- The README's "Deprecations" section spells the default `:stderr`. The code expects `:stderror` (`lib/blueprinter/deprecation.rb`), and `:stderr` works only because unrecognized values fall back to `:stderror`.
- The README's "OJ" and "Yajl-ruby" sections show swapping the serializer with `config.generator = Oj`, or `config.generator = Yajl::Encoder` plus `config.method = :encode`. Neither gem is a runtime dependency of Blueprinter.
