# Reflection

The [V2 Reflection API](../api/reflection.md) has very few changes from Legacy/V1.

## Reflecting on fields

Regular fields (no change):

```ruby
MyBlueprint.reflections[:default].fields
```

Objects and collections:

```ruby
# Legacy/V1 does not differentiate between objects and collections
MyV1Blueprint.reflections[:default].associations

# V2 does
MyV2Blueprint.reflections[:default].objects
MyV2Blueprint.reflections[:default].collections
```

## Field names

[V2's field metadata](../api/reflection.md#field-metadata) is similar, but there's an important different in `name`.

#### Legacy/V1

In Legacy/V1, `name` refers to what the field is called in the *input*.

```ruby
class MyV1Blueprint < Blueprinter::Base
  field :foo, name: :bar
end

ref = MyV1Blueprint.reflections[:default]

# What the field is called in the source object
ref.fields[:foo].name
=> :foo

# What the field will be called in the output
ref.fields[:foo].display_name
=> :bar
```

#### V2

In V2, `name` refers to what the field is called in the *output*. Note that this change is also reflected in the Hash key.

```ruby
class MyV2Blueprint < Blueprinter::Blueprint
  field :bar, from: :foo
end

ref = MyV1Blueprint.reflections[:default]

# What the field will be called in the output
ref.fields[:bar].name
=> :bar

# What the field is called in the source object
ref.fields[:bar].from
=> :foo
```
