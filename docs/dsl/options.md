# Options

Numerous options can be defined on Blueprints, views, partials, or individual fields. Some can also be passed to `render`.

```ruby
class WidgetBlueprint < ApplicationBlueprint
  # Blueprint options apply to all fields, associations, views, and partials in
  # the Blueprint. They are inherited from the parent class but can be overridden.
  options[:exclude_if_empty] = true

  # Field options apply to individual fields or associations. They can override
  # Blueprint options.
  field :name, exclude_if_empty: false

  # Options in views apply to all fields, associations, partials and nested views
  # in the view. They inherit options from the Blueprint, or from parent views,
  # and can override them.
  view :foo do
    options[:exclude_if_empty] = false
  end

  # Options in partials apply to all fields, associations, views, and partials in
  # the partial. All of these are applied to the views that use the partial.
  partial :bar do
    options[:exclude_if_empty] = false
  end

  # Some options accept Procs/labmdas. These can call instance methods defined on
  # your Blueprint. Or you can pass a method name as a symbol.
  field :foo, if: ->(ctx) { long_complex_check? ctx }
  field :bar, if: :long_complex_check?

  def long_complex_check?(ctx)
    # ...
  end
end

# Passing a supported option to render will override what's in the blueprint
WidgetBlueprint.render(widget, exclude_if_empty: false).to_json
```

For easier reference, options are grouped into the following categories:

- [Default values](#default-values): Provide defaults for empty fields
- [Conditional fields](#conditional-fields): Exclude fields based on conditions
- [Field mapping](#field-mapping): Change how field values are extracted from objects
- [Metadata](#other): Wrap or add metadata to the output

#### A note about context objects

Options that accept Procs, lambdas, or method names are usually passed a [Field context](../api/context-objects.md#field-context) argument. It contains the object being rendered as well as other useful information.

## Default Values

These options allow you to set default values for fields and associations, and customize when they're used.

#### default

A default value used when the field or assocation is nil.

> *Available in field, object, collection*\
> **@param** [Field context](../api/context-objects.md#field-context)

```ruby
field :foo, default: "Foo"
field :foo, default: ->(ctx) { "Foo" }
field :foo, default: :foo

def foo(ctx) = "Foo"
```

#### field_default

Default value for any nil non-association field in its scope.

> *Available in blueprint, view, partial, render*\
> **@param** [Field context](../api/context-objects.md#field-context)

```ruby
options[:field_default] = "Foo"
options[:field_default] = ->(ctx) { "Foo" }
options[:field_default] = :foo

def foo(ctx) = "Foo"

WidgetBluerpint.render(widget, field_default: "Foo").to_json
```

#### object_default

Default value for any nil object field in its scope.

> *Available in blueprint, view, partial, render*\
> **@param** [Field context](../api/context-objects.md#field-context)

```ruby
options[:object_default] = { name: "Foo" }
options[:object_default] = ->(ctx) { { name: "Foo" } }
options[:object_default] = :foo

def foo(ctx) = { name: "Foo" }

WidgetBluerpint.render(widget, object_default: { name: "Foo" }).to_json
```

#### collection_default

Default value for any nil collection field.

> *Available in blueprint, view, partial, render*\
> **@param** [Field context](../api/context-objects.md#field-context)

```ruby
options[:collection_default] = [{ name: "Foo" }]
options[:collection_default] = ->(ctx) { [{ name: "Foo" }] }
options[:collection_default] = :foo

def foo(ctx) = [{ name: "Foo" }]

WidgetBluerpint.render(widget, collection_default: [{ name: "Foo" }]).to_json
```

#### default_if

Use the default value if the given Proc or method name returns truthy.

> *Available in field, object, collection*\
> **@param** [Field context](../api/context-objects.md#field-context)

```ruby
field :foo, default: "Foo", default_if: ->(ctx) { ctx.object.disabled? }
field :foo, default: "Foo", default_if: :disabled?

def disabled?(ctx) = ctx.object.disabled?
```

#### field_default_if

Same as [default_if](#default_if), but applies to any non-association field in scope.

> *Available in blueprint, view, partial, render*\
> **@param** [Field context](../api/context-objects.md#field-context)

```ruby
options[:field_default_if] = ->(ctx) { ctx.object.disabled? }
options[:field_default_if] = :disabled?

def disabled?(ctx) = ctx.object.disabled?

WidgetBluerpint.render(widget, field_default_if: :disabled?).to_json
```

#### object_default_if

Same as [default_if](#default_if), but applies to any object field in scope.

> *Available in blueprint, view, partial, render*\
> **@param** [Field context](../api/context-objects.md#field-context)

```ruby
options[:object_default_if] = ->(ctx) { ctx.object.disabled? }
options[:object_default_if] = :disabled?

def disabled?(ctx) = ctx.object.disabled?

WidgetBluerpint.render(widget, object_default_if: :disabled?).to_json
```

#### collection_default_if

Same as [default_if](#default_if), but applies to any collection field in scope.

> *Available in blueprint, view, partial, render*\
> **@param** [Field context](../api/context-objects.md#field-context)

```ruby
options[:collection_default_if] = ->(ctx) { ctx.object.disabled? }
options[:collection_default_if] = :disabled?

def disabled?(ctx) = ctx.object.disabled?

WidgetBluerpint.render(widget, collection_default_if: :disabled?).to_json
```

## Conditional Fields

These options allow you to exclude fields from the output.

#### exclude_if_nil

Exclude fields if they're nil.

> *Available in blueprint, view, partial, field, object, collection, render*

```ruby
options[:exclude_if_nil] = true

field :description, exclude_if_nil: true

WidgetBluerpint.render(widget, exclude_if_nil: true).to_json
```

#### exclude_if_empty

Exclude fields if they're nil, or if they respond to `empty?` and it returns true.

> *Available in blueprint, view, partial, field, object, collection, render*

```ruby
options[:exclude_if_empty] = true

field :description, exclude_if_empty: true

WidgetBluerpint.render(widget, exclude_if_empty: true).to_json
```

#### if

Only include the field if the given Proc or method name returns truthy.

> *Available in field, object, collection*\
> **@param** [Field context](../api/context-objects.md#field-context)

```ruby
field :foo, if: ->(ctx) { ctx.object.enabled? }
field :foo, if: :enabled?

def enabled?(ctx) = ctx.object.enabled?
```

#### field_if

Only include non-association fields if the given Proc or method name returns truthy.

> *Available in blueprint, view, partial, render*\
> **@param** [Field context](../api/context-objects.md#field-context)

```ruby
options[:field_if] = ->(ctx) { ctx.object.enabled? }
options[:field_if] = :enabled?

def enabled?(ctx) = ctx.object.enabled?

WidgetBluerpint.render(widget, field_if: :enabled?).to_json
```

#### object_if

Only include object fields if the given Proc or method name returns truthy.

> *Available in blueprint, view, partial, render*\
> **@param** [Field context](../api/context-objects.md#field-context)

```ruby
options[:object_if] = ->(ctx) { ctx.object.enabled? }
options[:object_if] = :enabled?

def enabled?(ctx) = ctx.object.enabled?

WidgetBluerpint.render(widget, object_if: :enabled?).to_json
```

#### collection_if

Only include collection fields if the given Proc or method name returns truthy.

> *Available in blueprint, view, partial, render*\
> **@param** [Field context](../api/context-objects.md#field-context)

```ruby
options[:collection_if] = ->(ctx) { ctx.object.enabled? }
options[:collection_if] = :enabled?

def enabled?(ctx) = ctx.object.enabled?

WidgetBluerpint.render(widget, collection_if: :enabled?).to_json
```

#### unless

Inverse of [if](#if).

#### field_unless

Inverse of [field_if](#field_if).

#### object_unless

Inverse of [object_if](#object_if).

#### collection_unless

Inverse of [collection_if](#collection_if).

## Field mapping

These options let you change how fields values are extracted from your objects.

#### from

Populate the field using a method/Hash key other than the field name.

> *Available in field, object, collection*

```ruby
field :desc, from: :description
```

#### extractor

Pass a [custom extractor](../api/extractors.md) class or instance.

> *Available in field, object, collection*

```ruby
# Pass as a class
object :category, CategoryBlueprint, extractor: MyCategoryExtractor
# or an instance
object :category, CategoryBlueprint, extractor: MyCategoryExtractor.new(args)
```

Note that when you pass a class, it will be initialized _once per render_.

## Metadata

These options allow you to add metadata to the rendered output.

#### root

Pass a root key to wrap the output.

> *Available in blueprint, view, partial, render*

```ruby
options[:root] = :data

WidgetBlueprint.render(widget, root: :data).to_json
```

#### meta

Add a `meta` key and data to the wrapped output (requires the `root` option).

> *Available in blueprint, view, partial, render*\
> **@param** [Result context](../api/context-objects.md#result-context)

```ruby
options[:root] = :data
options[:meta] = { page: 1 }

# If you pass a Proc/lambda, it can call instance methods defined on the Blueprint
options[:meta] = ->(ctx) { { page: page_num(ctx) } }

WidgetBlueprint
  .render(widget, root: :data, meta: { page: params[:page] })
  .to_json
```
