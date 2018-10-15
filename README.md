[![CircleCI](https://circleci.com/gh/procore/blueprinter.svg?style=svg)](https://circleci.com/gh/procore/blueprinter)
[![Gem Version](https://badge.fury.io/rb/blueprinter.svg)](https://badge.fury.io/rb/blueprinter)

<img src="blueprinter_logo.svg" width="25%">

# Blueprinter
Blueprinter is a JSON Object Presenter for Ruby that takes business objects and breaks them down into simple hashes and serializes them to JSON. It can be used in Rails in place of other serializers (like JBuilder or ActiveModelSerializers). It is designed to be simple, direct, and performant.

It heavily relies on the idea of `views` which, similar to Rails views, are ways of predefining output for data in different contexts.

## Documentation
Docs can be found [here](http://www.rubydoc.info/gems/blueprinter).

## Usage
### Basic
If you have an object you would like serialized, simply create a blueprint. Say, for example, you have a User record with the following attributes `[:uuid, :email, :first_name, :last_name, :password, :address]`.

You may define a simple blueprint like so:

```ruby
class UserBlueprint < Blueprinter::Base
  identifier :uuid

  fields :first_name, :last_name, :email
end
```

and then, in your code:
```ruby
puts UserBlueprint.render(user) # Output is a JSON string
```

And the output would look like:

```json
{
  "uuid": "733f0758-8f21-4719-875f-262c3ec743af",
  "email": "john.doe@some.fake.email.domain",
  "first_name": "John",
  "last_name": "Doe"
}
```

### Renaming

You can rename the resulting JSON keys in both fields and associations by using the `name` option.

```ruby
class UserBlueprint < Blueprinter::Base
  identifier :uuid

  field :email, name: :login

  association :user_projects, name: :projects
end
```

This will result in JSON that looks something like this:

```json
{
  "uuid": "92a5c732-2874-41e4-98fc-4123cd6cfa86",
  "login": "my@email.com",
  "projects": []
}
```

### Views
You may define different outputs by utilizing views:
```ruby
class UserBlueprint < Blueprinter::Base
  identifier :uuid
  field :email, name: :login

  view :normal do
    fields :first_name, :last_name
  end

  view :extended do
    include_view :normal
    field :address
    association :projects
  end
end
```

Usage:
```ruby
puts UserBlueprint.render(user, view: :extended)
```

Output:
```json
{
  "uuid": "733f0758-8f21-4719-875f-262c3ec743af",
  "address": "123 Fake St.",
  "first_name": "John",
  "last_name": "Doe",
  "login": "john.doe@some.fake.email.domain"
}
```

### Associations
You may include associated objects. Say for example, a user has projects:
```ruby
class ProjectBlueprint < Blueprinter::Base
  identifier :uuid
  field :name
end

class UserBlueprint < Blueprinter::Base
  identifier :uuid
  field :email, name: :login

  view :normal do
    fields :first_name, :last_name
    association :projects, blueprint: ProjectBlueprint
  end
end
```

Usage:
```ruby
puts UserBlueprint.render(user, view: :normal)
```

Output:
```json
{
  "uuid": "733f0758-8f21-4719-875f-262c3ec743af",
  "first_name": "John",
  "last_name": "Doe",
  "login": "john.doe@some.fake.email.domain",
  "projects": [
    {
      "uuid": "dca94051-4195-42bc-a9aa-eb99f7723c82",
      "name": "Beach Cleanup"
    },
    {
      "uuid": "eb881bb5-9a51-4d27-8a29-b264c30e6160",
      "name": "Storefront Revamp"
    }
  ]
}
```

#### Default option
By default, an association that evaluates to `nil` is serialized as `nil`. A default serialized value can be
specified as option on the association for cases when the association could potentially evaluate to `nil`.
```ruby
class UserBlueprint < Blueprinter::Base
  identifier :uuid

  view :normal do
    fields :first_name, :last_name
    association :company, blueprint: CompanyBlueprint, default: {}
  end
end
```

### Defining a field directly in the Blueprint

You can define a field directly in the Blueprint by passing it a block. This is especially useful if the object does not already have such an attribute or method defined, and you want to define it specifically for use with the Blueprint. For example:

```ruby
class UserBlueprint < Blueprinter::Base
  identifier :uuid
  field :full_name do |user|
    "#{user.first_name} #{user.last_name}"
  end
end
```

Usage:

```ruby
puts UserBlueprint.render(user)
```

Output:

```json
{
  "uuid": "733f0758-8f21-4719-875f-262c3ec743af",
  "full_name": "John Doe"
}
```

#### Defining an association directly in the Blueprint

You can also pass a block to an association:

```ruby
class ProjectBlueprint < Blueprinter::Base
  identifier :uuid
  field :name
end

class UserBlueprint < Blueprinter::Base
  identifier :uuid

  association :projects, blueprint: ProjectBlueprint do |user|
    user.projects + user.company.projects
  end
end
```

Usage:

```ruby
puts UserBlueprint.render(user)
```

Output:

```json
{
  "uuid": "733f0758-8f21-4719-875f-262c3ec743af",
  "projects": [
    {"uuid": "b426a1e6-ac41-45ab-bfef-970b9a0b4289", "name": "query-console"},
    {"uuid": "5bd84d6c-4fd2-4e36-ae31-c137e39be542", "name": "blueprinter"},
    {"uuid": "785f5cd4-7d8d-4779-a6dd-ec5eab440eff", "name": "uncontrollable"}
  ]
}
```

### Passing additional properties to `render`

`render` takes an options hash which you can pass additional properties, allowing you to utilize those additional properties in the `field` block. For example:

```ruby
class UserBlueprint < Blueprinter::Base
  identifier :uuid
  field(:company_name) do |_user, options|
    options[:company].name
  end
end
```

Usage:

```ruby
puts UserBlueprint.render(user, company: company)
```

Output:

```json
{
  "uuid": "733f0758-8f21-4719-875f-262c3ec743af",
  "company_name": "My Company LLC"
}
```

### Conditional field

`field` supports `:if` and `:unless` options argument that can be used to serialize the field conditionally.

```ruby
class UserBlueprint < Blueprinter::Base
  identifier :uuid
  field :last_name, if: ->(user, options) { user.first_name != options[:first_name] }
  field :age, unless: ->(user, _options) { user.age < 18 }
end
```

### Custom formatting for dates and times
To define a custom format for a Date or DateTime field, include the option `datetime_format` with the associated `strptime` format.

Usage:
```ruby
class UserBlueprint < Blueprinter::Base
  identifier :name
  field :birthday, datetime_format: "%m/%d/%Y"
end
```

Output:
```json
{
  "name": "John Doe",
  "birthday": "03/04/1994"
}
```

## Installation
Add this line to your application's Gemfile:

```ruby
gem 'blueprinter'
```

And then execute:
```bash
$ bundle
```

Or install it yourself as:
```bash
$ gem install blueprinter
```

You should also have `require 'json'` already in your project if you are not using Rails or if you are not using Oj.

## OJ

By default, Blueprinter will be calling `JSON.generate(object)` internally and it expects that you have `require 'json'` already in your project's code. You may use `Oj` to generate in place of `JSON` like so:

```ruby
require 'oj' # you can skip this if OJ has already been required.

Blueprinter.configure do |config|
  config.generator = Oj # default is JSON
end
```

Ensure that you have the `Oj` gem installed in your Gemfile if you haven't already:

```ruby
# Gemfile
gem 'oj'
```

## How to Document

We use [Yard](https://yardoc.org/) for documentation. Here are the following
documentation rules:

- Document all public methods we expect to be utilized by the end developers.
- Methods that are not set to private due to ruby visibility rule limitations should be marked with `@api private`.

## Contributing
Feel free to browse the issues, converse, and make pull requests. If you need help, first please see if there is already an issue for your problem. Otherwise, go ahead and make a new issue.

### Tests
You can run tests with `bundle exec rake`.

### Maintain The Docs
We use Yard for documentation. Here are the following documentation rules:

- Document all public methods we expect to be utilized by the end developers.
- Methods that are not set to private due to ruby visibility rule limitations should be marked with `@api private`.

### Releasing a New Version
To release a new version, change the version number in `version.rb`, and update the `CHANGELOG.md`. Finally, maintainers need to run `bundle exec rake release`, which will automatically create a git tag for the version, push git commits and tags to Github, and push the `.gem` file to rubygems.org.

## License
The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).
