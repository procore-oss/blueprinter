---
description: Basic information about Blueprinter V2
user-invocable: false
skills:
  - blueprinter-basics
---

## V2 Inheritance

* V2 Blueprints inherit everything from their parent class: fields, associations, options, extensions, formatters, views, and partials.
* V2 views inherit everthing from their parent class, except for views.
* Nested views inherit everything from their parent view.
* A Blueprint or view may locally override anything it inherits.

## V2 Associations

* V2 associations are defined like `association :category, CategoryBlueprint`.
* Reference a specific view with `CategoryBlueprint[:my_view]`.
* Associations to collections are defined like `association :categories, [CategoryBlueprint]`.

## V2 Extensions

An extension can be added to any Blueprint or view with: `add MyExtension.new`.

## V2 Base Blueprint Suggested Layout

The application's base Blueprint should define common fields, views, options, methods, etc.

### The `:id` field

It should have a field called `:id`.

### The `:identifier` view

* Should have `exclude fields: true`.
* Should have an `:id` field.

### The `empty_field?` method

Should take two arguments: `ctx` and `val`. It will branch on `ctx.field.type`:

* For `:object` or `:collection, return true if `val.empty?`
* Otherwise, return true if `val` is an empty string.
