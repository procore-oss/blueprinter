[![CircleCI](https://circleci.com/gh/procore/blueprinter.svg?style=svg)](https://circleci.com/gh/procore/blueprinter)
[![Gem Version](https://badge.fury.io/rb/blueprinter.svg)](https://badge.fury.io/rb/blueprinter)

# Blueprinter
Blueprinter is a JSON Object Presenter for Ruby that takes business objects and breaks them down into simple hashes and serializes them to JSON. It can be used in Rails in place of other serializers (like JBuilder or ActiveModelSerializers). It is designed to be simple, direct, and performant.

It heavily relies on the idea of `views` which, similar to Rails views, are ways of predefining output for data in different contexts.

## Documentation
!TODO Link to the docs

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

### Views
You may define different ouputs by utilizing views:
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
class UserBlueprint < Blueprinter::Base
  identifier :uuid
  field :email, name: :login

  view :normal do
    fields :first_name, :last_name
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

## Documentation

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

## License
The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).
