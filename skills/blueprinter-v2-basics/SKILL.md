---
description: Basic information about Blueprinter V2
user-invocable: false
skills:
  - blueprinter-basics
---

## V2 Inheritance

* V2 Blueprints inherit everything from their parent class: fields, associations, options, extensions, formatters, views, and partials.
* V2 views inherit everthing from their parent class.
* Nested views inherit everything from their parent view.
* A Blueprint or view may locally override anything it inherits.

## V2 Associations

* V2 associations are defined like `association :category, CategoryBlueprint`.
* Reference a specific view with `CategoryBlueprint[:my_view]`.
* Associations to collections are defined like `association :categories, [CategoryBlueprint]`.
* Recursive associations (associations to the current view) should just use `self` as the Blueprint class, with new view argument.

## V2 Extensions

An extension can be added to any Blueprint or view with: `extensions << MyExtension.new`.

## V2 Base Blueprint Suggested Layout

The application's base Blueprint should define common fields, views, options, methods, etc.

### The `:id` field

It should have a field called `:id`.

### The `:identifier` view

* Should have the `empty: true` option so it inherits no fields. (Don't use this with other views.)
* Should contain only an `:id` field.

### The `empty_field?` method

Should take two arguments: `ctx` and `val`. It will branch on `ctx.field.type`:

* For `:object` or `:collection, return true if `val.empty?`
* Otherwise, return true if `val` is an empty string.
