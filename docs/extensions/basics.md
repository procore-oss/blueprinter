# Basics

An extension will subclass `Blueprinter::Extension` and define one or more hook methods. (See `Blueprinter::Extension` for documentation about all hooks.)

```ruby
class ExcludeIfBlankExtension < Blueprinter::Extension
  def around_field_value(ctx)
    # get the value by yielding to other extensions and Blueprinter's internals
    val = yield ctx

    # skip this field and halt further extensions if the value is blank
    skip! if ctx.field.options[:exclude_if_blank] && val.blank?

    # return the value for the next extension (or Blueprinter) to use
    val
  end
end
```

Then add the extension to a blueprint:

```ruby
class ApplicationBlueprint < Blueprinter::V2::Base
  add ExcludeIfBlankExtension.new
end
```

## Context Objects

All extension hooks take a single argument: a context object. It contains the "context" of the current operation (Blueprint, options, field, the object, etc.) so you can react to it and, in some cases, alter it.

There are several different context object types. See the `Blueprinter::V2::Context` module for documentation on which hooks receive which types, and what can be done with them.
