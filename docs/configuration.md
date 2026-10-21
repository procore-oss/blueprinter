---
title: "Configuration Reference"
type: reference
description: "Find out what a configuration option does and when changing it takes effect."
generated: { by: claude-code/claude-opus-5-5, at: "2026-10-21T22:02:01Z" }
verified:
  - { by: human:lessthanjacob, at: "2026-10-21T22:30:20Z" }
---

# Configuration Reference

**Configuration** is global, and several options are read only once, so _when_ you set an option matters as much as its value. Read it with `Blueprinter.configuration`, change it with `Blueprinter.configure { |config| ... }`, and restore the defaults with `Blueprinter.reset_configuration!`. The options live in `lib/blueprinter/configuration.rb`.

## Options

| Option | Default | Read by |
|---|---|---|
| `association_default` | `nil` | `AssociationExtractor`, when an association's value is `nil` (or matches `:default_if`) and the association sets no `:default` |
| `custom_array_like_classes` | `[]` | `Configuration#array_like_classes`, which treats these classes like `Array` when rendering a collection |
| `datetime_format` | `nil` | `DateTimeFormatter`, when a field sets no `:datetime_format`. A `String` is passed to `strftime`, a `Proc` is called, and anything else raises `InvalidDateTimeFormatterError` |
| `default_transformers` | `[]` | `ViewCollection#build_transformers`, only when a view has no transformers of its own, including inherited and included ones. Any transformer on the blueprint replaces these rather than adding to them |
| `deprecations` | `:stderror` | `Deprecation.report`. Accepted values are `:silence`, `:stderror`, and `:raise`; anything else behaves as `:stderror` |
| `extensions` | empty | `Rendering#hashify`. The writer wraps the given `Array` without copying it, and `<<` appends |
| `extractor_default` | `AutoExtractor` | `Configuration#default_extractor`, which memoizes one instance; the writer resets that memo |
| `field_default` | `nil` | `AutoExtractor`, when an extracted value is `nil` (or matches `:default_if`) and the field sets no `:default` |
| `generator` | `JSON` | `Configuration#jsonify`, as `generator.public_send(method, data)`, in `render` only |
| `if`, `unless` | `nil` | `Field#skip?`, when a field sets no `:if` / `:unless`. A `Proc`, or a `Symbol` naming a method on the blueprint class |
| `method` | `:generate` | `Configuration#jsonify` |
| `sort_fields_by` | `:name_asc` | `View` and `ViewCollection` when they are created; `:definition` sorts by definition order and any other value sorts by name |

## When a Change Takes Effect

Surprises come from changing an option after it has already been read:

- Set before any blueprint is defined: `sort_fields_by` and `extractor_default`. Both are read when views and fields are created, so blueprints defined earlier keep the old value. Changing `sort_fields_by` away from `:definition` after a blueprint was defined with it is _worse_ than ignored: views created later in that blueprint drop their own fields, because they no longer track definition order.
- Set before the first render: `custom_array_like_classes`. `Configuration#array_like_classes` memoizes the full list on first use, and only `reset_configuration!` clears it.
- `if` and `unless`: a field looks up the global condition on every check until it finds one, then keeps it. Setting a condition where none was set takes effect at the next render; changing one after a field has used it is ignored for that field.
- Takes effect at the next compile: `default_transformers`.
- Takes effect at the next render: `association_default`, `field_default`, `datetime_format`, `deprecations`, `extensions`, `generator`, and `method`.

## Notes

- The README's "Deprecations" section spells the default `:stderr`. The code expects `:stderror` (`lib/blueprinter/deprecation.rb`), and `:stderr` works only because unrecognized values fall back to `:stderror`.
- The README's "OJ" and "Yajl-ruby" sections show swapping the serializer with `config.generator = Oj`, or `config.generator = Yajl::Encoder` plus `config.method = :encode`. Neither gem is a runtime dependency of Blueprinter.
