# Field Filter

This extension filters out sensitive fields based on the user's permissions. (Is this the *best* way to do that? No, a view is probably better, but this is just an example.)

```ruby
class FieldFilterExtension < Blueprinter::Extension
  def initialize(field_matchers, &check)
    @field_matchers = field_matchers
    @check = check
  end

  # @param ctx [Blueprinter::V2::Context::Init]
  def around_blueprint_init(ctx)
    ctx.fields.reject! do |field|
      sensitive_field = @field_matchers.any? { |matcher| matcher === field.name.to_s }
      sensitive_field && !@check.call
    end
    yield ctx
  end
end
```

Then add it to your Blueprints, defining the fields and logic:

```ruby
class ApplicationBlueprint < Blueprinter::V2::Base
  add FieldFilterExtension.new([/ssn/i, /dob/i]) {
    GlobalVariables.current_user&.admin?
  }
end
```

This could also be implemented using `skip!` inside an `around_field_value` hook, but entirely eliminating the fields up-front will be more performant.
