# Field Filter

This extension filters out sensitive fields based on the user's permissions.

```ruby
class PIIFilterExtension < Blueprinter::Extension
  def initialize(field_matchers, &check)
    @field_matchers = field_matchers
    @check = check
  end

  def around_blueprint_init(ctx)
    ctx.fields.reject! do |field|
      sensitive_field = @field_matchers.any? { |matcher| matcher === field.name.to_s }
      sensitive_field && !@check.call
    end
    yield ctx
  end
end
```

Then add it to your Blueprints, define the fields and the check logic:

```ruby
class ApplicationBlueprint < Blueprinter::V2::Base
  extensions << PIIFilterExtension.new([/ssn/i, /dob/i]) do
    GlobalVariables.current_user&.admin?
  end
end
```

This could also be implemented using `skip!` inside an `around_field_value` hook, but entirely eliminating the fields up-front should be more performant.
