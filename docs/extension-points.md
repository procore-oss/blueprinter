---
title: "Extension Points Reference"
type: reference
description: "Know the exact contract before writing or changing an extractor, transformer, extension, or reflection consumer, or raising a new error."
generated: { by: claude-code/claude-opus-5-5, at: "2026-10-21T23:22:41Z" }
verified:
  - { by: human:lessthanjacob, at: "2026-10-21T23:24:23Z" }
---

# Extension Points Reference

The examples below share these objects:

```ruby
User = Struct.new(:id, :name, :vehicles, keyword_init: true)
Vehicle = Struct.new(:id, :make, keyword_init: true)
user = User.new(id: 1, name: "Ada", vehicles: [Vehicle.new(id: 7, make: "Rivian")])
```

## Extractor

An **extractor** decides how a field's value is read from the object being rendered. Write one when neither a method call, a `Hash` lookup, nor a block fits.

```ruby
class UpcaseExtractor < Blueprinter::Extractor
  def extract(field_name, object, _local_options, _options = {})
    object.public_send(field_name).to_s.upcase
  end
end

class UserBlueprint < Blueprinter::Base
  identifier :id
  field :name, extractor: UpcaseExtractor.new
end

UserBlueprint.render_as_hash(user) # => {id: 1, name: "ADA"}
```

- `extract(field_name, object, local_options, options)` returns the value. `field_name` is the source method (not the output name, if the field was renamed), and `options` is the field's own options hash.
- Pass an _instance_ to `extractor:`. A class works too, but it builds a new extractor on every extraction (on the hottest path in the gem).
- Define the class only after something has loaded `Blueprinter::Base` or `Blueprinter.configuration`. `Blueprinter::Extractor` isn't autoloaded, so referencing it straight after `require 'blueprinter'` raises `NameError` ([why](architecture.md#loading-model)).

The default, `AutoExtractor`, calls the field's block if there is one, reads `object[name]` from a `Hash` (symbol keys only), and calls `object.public_send(name)` on anything else. It then formats dates and applies `:default` / `:default_if`. Without `:default_if`, only `nil` gets the default. With it, `Blueprinter::EMPTY_COLLECTION` matches an empty array-like value, `EMPTY_HASH` an empty `Hash`, and `EMPTY_STRING` anything whose `to_s` is empty (including `nil`); any other `:default_if` value never matches.

Associations use `AssociationExtractor` (one per blueprint class), which reads the value, applies defaults, merges the association's `:options` into `local_options`, and renders the value with the association's blueprint and view.

In the code: `lib/blueprinter/extractor.rb`, `lib/blueprinter/extractors/`, `lib/blueprinter/empty_types.rb`, `lib/blueprinter/formatters/date_time_formatter.rb`.

## Reserved Field Option Keys

Every field option (including your own) lands in the same hash, so a new option name _must not_ collide with the keys the gem reads: `:block`, `:association`, `:blueprint`, `:view`, `:if`, `:unless`, `:default`, `:default_if`, `:exclude_if_nil`, `:datetime_format`, `:options` (associations), `:name`, and `:extractor`.

## Transformer

A **transformer** edits a view's finished output, for changes that depend on the whole hash rather than one field.

```ruby
class TypeTransformer < Blueprinter::Transformer
  def transform(hash, object, _options)
    hash[:type] = object.class.name
  end
end

class UserBlueprint < Blueprinter::Base
  identifier :id
  field :name
  transform TypeTransformer
end

UserBlueprint.render_as_hash(user) # => {id: 1, name: "Ada", type: "User"}
```

- `transform(hash, object, options)` edits `hash` in place; its return value is ignored.
- It runs after every field in the view has been extracted, with `local_options` as `options`. `local_options` isn't frozen, so a transformer _can_ change it to pass derived values downstream.
- `transform` accepts a class or an instance.

Which transformers run, and in what order: [architecture.md](architecture.md#transformer-order). In the code: `lib/blueprinter/transformer.rb`.

## Extension

An **extension** sees (and can replace) every object before it's rendered, across every blueprint. It exists for cross-cutting work like preloading `ActiveRecord` associations.

```ruby
class FirstUserOnly < Blueprinter::Extension
  def pre_render(object, blueprint, _view, _options)
    blueprint == UserBlueprint && object.is_a?(Array) ? object.first : object
  end
end

Blueprinter.configure { |config| config.extensions << FirstUserOnly.new }

# UserBlueprint as defined under Transformer
UserBlueprint.render_as_hash([user, user]) # => {id: 1, name: "Ada", type: "User"}
```

- `pre_render(object, blueprint, view, options)` returns the object to render. The base class returns `object` unchanged.
- Extensions run in registration order, each receiving the previous one's result. Any object with a `pre_render` method works (it doesn't have to subclass `Extension`).
- It runs once for the top-level object _and_ once per associated object, with `blueprint` and `view` set to the association's. `options` is the render options minus `:view`, `:root`, and `:meta`; for an associated object, it's the parent's options (which already carry the parent's `:view`) merged with the association's `:options`.
- `pre_render` is the only hook. `blueprinter-activerecord` and `blueprinter_schema` build on it and on reflection (README "Gem Extensions").

In the code: `lib/blueprinter/extension.rb`, `lib/blueprinter/extensions.rb`.

## Reflection

**Reflection** lets tools read a blueprint's structure (its views, fields, and associations) without rendering anything.

```ruby
class VehicleBlueprint < Blueprinter::Base
  identifier :id
  field :make
end

class UserBlueprint < Blueprinter::Base
  identifier :id
  field :name
  view :extended do
    association :vehicles, blueprint: VehicleBlueprint
  end
end

UserBlueprint.reflections[:default].fields.keys                    # => [:id, :name]
UserBlueprint.reflections[:extended].associations[:vehicles].blueprint # => VehicleBlueprint
```

- `fields` and `associations` are keyed by output name, and reflect inheritance, included views, and exclusions.
- Each field is a `Reflection::Field(:name, :display_name, :options)` and each association a `Reflection::Association(:name, :display_name, :blueprint, :view, :options)`. `:name` is the source method and `:display_name` the output key. (The YARD comment says the hash is keyed by method name; it's keyed by output name.)
- The results are cached and never refreshed. The list of views is fixed at the first `reflections` call, and each view's `fields` and `associations` at their own first call, so anything added afterwards is missing from them even though rendering sees it.

In the code: `lib/blueprinter/reflection.rb`.

## Errors

Every Blueprinter error subclasses `BlueprinterError`, so `rescue Blueprinter::BlueprinterError` catches all of them, while callers can still rescue a specific one.

| Class | Parent | Raised when | Message |
|---|---|---|---|
| `Blueprinter::BlueprinterError` | `StandardError` | A deprecated method is called and `deprecations` is `:raise` | Prefixed `[DEPRECATION::WARNING] Blueprinter:` |
| `Errors::InvalidBlueprint` | `BlueprinterError` | An association's `blueprint:` is neither a `Proc` nor a `Base` subclass | Names the object |
| `Errors::UnknownView` | `BlueprinterError` | `render` is asked for a view that doesn't exist | `View 'x' is not defined` |
| `Errors::InvalidRoot` | `BlueprinterError` | `:root` is neither a `String` nor a `Symbol` | Default message in the class |
| `Errors::MetaRequiresRoot` | `BlueprinterError` | `:meta` is given without `:root` | Default message in the class |
| `DateTimeFormatter::InvalidDateTimeFormatterError` | `BlueprinterError` | A date can't be formatted | `Cannot format invalid DateTime object`, or `Cannot format DateTime object with invalid formatter: <class>` |

The same paths also raise `ArgumentError` (an association without `:blueprint`, or a condition that's neither a `Proc` nor a `Symbol`) and `NotImplementedError` (an extractor or transformer that doesn't implement its method). In the code: `lib/blueprinter/blueprinter_error.rb`, `lib/blueprinter/errors/`, and `lib/blueprinter/formatters/date_time_formatter.rb`.

## Deprecation

`Blueprinter::Deprecation.report(message)` warns, stays silent, or raises, depending on `config.deprecations` at the moment it's called (unknown values warn). To deprecate something, follow [making-changes.md](making-changes.md#add-a-deprecation).

`Rendering#prepare` is deprecated and may be removed in a minor release with a `[BREAKING]` entry. Until then it ignores `view_name:` and renders `:default` (it passes its keywords as the options `Hash`, and `render_as_hash` reads the view from `options[:view]`).

## Rails Generator

`rails g blueprinter:blueprint ModelName` writes a blueprint for a model. Its options are `--blueprints_dir`, `--identifier`, `--fields`, `--detect_fields`, `--associations`, `--detect_associations`, `--wrap_at`, and `--indentation`; the two `--detect` options read the model's `columns_hash` and `reflections`.

`require 'blueprinter'` doesn't load it, and it's excluded from `RuboCop` and `YARD`. In the code: `lib/generators/blueprinter/`; tested in `spec/generators/blueprint_generator_spec.rb`.
