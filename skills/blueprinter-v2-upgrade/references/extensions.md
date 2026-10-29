# Extensions

Most applications don't have custom Blueprinter extensions. Check the inventory output and the
`Blueprinter.configure` block before reading further — if `config.extensions` is empty and no
Blueprint subclasses `Blueprinter::Extension`, skip this file.

## Why a V1 extension silently stops working

V1's extension API had exactly one hook, `pre_render(object, blueprint_class, view, options)`,
which returned a replacement object. V2 never calls it.

Crucially, **adding a V1 extension to a V2 Blueprint succeeds**. `add MyExtension.new` registers
it, V2 finds no hooks it recognizes, and the extension does nothing — no error, no warning. If
the extension was doing authorization filtering or scoping, the output is now wrong in a way
that looks like valid data. Treat any V1 extension as a mandatory conversion, not an optional
cleanup.

## Choosing a V2 hook

**`pre_render` ran more often than most people assume, and this is the easiest thing in the
migration to get wrong.** It fires inside `hashify`, and V1's `AssociationExtractor` calls
`hashify` for every nested association — so `pre_render` ran on the object passed to `render`
*and* on every associated object and collection below it, once per Blueprint boundary.

So the faithful translation is:

```ruby
def initialize
  around_serialize_object :my_hook
  around_serialize_collection :my_hook
end
```

Those two together fire in the same places `pre_render` did. Registering `around_result` instead
— which is the tempting one-liner, and what the gem's own migration doc shows — runs the hook
only on the outermost object. If the extension filters or scopes data, nested associations
silently stop being filtered. The output is still well-formed, so only a golden-output diff with
a nested association in the fixture will catch it.

Use `around_result` only when you've confirmed the extension is meant to touch the top-level
object alone.

| What the V1 extension did | V2 hook |
|---|---|
| anything in `pre_render` (default) | `around_serialize_object` + `around_serialize_collection` |
| should only touch the outermost object | `around_result` |
| transformed the serialized Hash | `around_blueprint` |
| changed how a value is read off the object | `around_field_value` / `around_object_value` / `around_collection_value` |
| inspected or reordered the field list | `around_blueprint_init` |
| instrumented everything | `around_hook` |

Hooks nest outermost-first: `around_result` → `around_blueprint_init` → `around_serialize_*` →
`around_blueprint` → `around_*_value`.

## Shape of a V2 hook

Hooks are registered in `initialize` by name, and every hook is an "around" — it receives a
context and must `yield ctx` to continue the chain, or return a value to short-circuit it.

```ruby
class MyExtension < Blueprinter::Extension
  def initialize
    around_serialize_object :scope_object
    around_serialize_collection :scope_object
  end

  # @param ctx [Blueprinter::V2::Context::Object]
  def scope_object(ctx)
    ctx.object = ctx.object.visible_to(ctx.options[:current_user])
    yield ctx
  end
end
```

Forgetting `yield ctx` is the usual first bug: the render returns `nil` instead of raising.

## Supporting both APIs at once

In partial mode an extension is often used by V1 and V2 Blueprints simultaneously. Keep both
entry points and put the logic in a private method:

```ruby
class MyExtension < Blueprinter::Extension
  def initialize
    around_serialize_object :modify_object
    around_serialize_collection :modify_object
  end

  # V2
  def modify_object(ctx)
    ctx.object = modify(ctx.object, ctx.blueprint.class, ctx.blueprint.class.view_name, ctx.options)
    yield ctx
  end

  # V1
  def pre_render(object, blueprint_class, view, options)
    modify(object, blueprint_class, view, options)
  end

  private

  def modify(object, blueprint_class, view, options)
    # ...
  end
end
```

Note the argument translation: V1's `view` symbol is `ctx.blueprint.class.view_name`
(or `view_path` for nested views), and V1's `blueprint_class` is `ctx.blueprint.class` — in V2
`ctx.blueprint` is an *instance*.

## Where to add them

V1 registered extensions globally via `config.extensions`. V2 adds them to a Blueprint, view, or
partial, and children inherit them:

```ruby
add MyExtension.new                  # append
add MyExtension.new, prepend: true   # run before the others
remove MyExtension                   # in a child, by class
remove { |ext| ext.is_a? MyExtension }
exclude extensions: true             # inherit none
```

A global `config.extensions` entry goes on the base Blueprint. Put everything else at the
narrowest level that works — extensions have a per-render cost, and a few bundled ones
(`LegacyDynamicOptions` in particular) do per-object work.

`add` does not take a block. `add MyExtension.new { ... }` raises — the block was meant for the
extension's constructor.

## A custom JSON serializer

The `around_result` + `serialized` pattern, which is what `config.generator` / `config.method`
become when `multi_json` isn't an option:

```ruby
class MyJsonExtension < Blueprinter::Extension
  def initialize
    around_result :serialize
  end

  def serialize(ctx)
    case ctx.format
    when :json
      result = yield ctx
      serialized MySerializer.dump(result)   # tells Blueprinter not to JSONify again
    else
      yield ctx
    end
  end
end
```

Add it **first**, before any other extension.

## Bundled extensions

Full docs are in the `Blueprinter::Extensions` module.

**V1 compatibility** — see `options.md` and `configuration.md` for when each applies.

- `LegacyOptions` — V1-style `if`/`unless` (3-arg Procs and class methods), `default_if`
  constants, `name:`, `extractor:`, and `render(obj, view:)`. These are detected per option, so
  the extension is inert for anything already in V2 style. Add it to the base Blueprint.
- `LegacyTransformer` — runs V1 `Blueprinter::Transformer` classes. Takes the classes as
  constructor arguments.
- `LegacyDynamicOptions` — V1's `options:` on associations. Add per-Blueprint, not globally.

**General purpose**

- `FieldOrder` — reorders serialized fields; takes a comparator block. The replication of V1's
  default sort is in `configuration.md`.
- `MultiJson` — serializes via the `multi_json` gem. Must be added first.
- `OpenTelemetry` — instruments the render lifecycle. Useful after a migration for comparing V1
  and V2 performance, not part of the conversion.

## Reflection

Not an extension, but it breaks in the same quiet way. Code that reads
`MyBlueprint.reflections` keeps working, except for renamed fields:

```ruby
# V1
field.display_name  # => :desc            (serialized name)
field.name          # => :description     (source)

# V2
field.name          # => :desc            (serialized name)
field.source        # => :description     (source)
```

Anything generating API docs or JSON schema from Blueprints needs updating alongside the
Blueprints themselves, and `field.name` is the dangerous one — it still exists and still returns
a symbol, just a different one.
