# Reflection

V2's reflection API has very few changes from Legacy/V1.

## Reflecting on views and fields

Regular fields (no change):

```ruby
MyBlueprint.reflections[:default].fields
```

Objects and collections (no required change):

```ruby
MyBlueprint.reflections[:default].associations

# V2 also provides special access methods to split out objects and collections
MyBlueprint.reflections[:default].objects
MyBlueprint.reflections[:default].collections
```

## Field names

V2's field metadata is similar, but there's an important different in `name`.

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
class MyV2Blueprint < Blueprinter::V2::Base
  field :bar, source: :foo
end

ref = MyV1Blueprint.reflections[:default]

# What the field will be called in the output
ref.fields[:bar].name
=> :bar

# What the field is called in the source object
ref.fields[:bar].source
=> :foo
```
