[![Test](https://github.com/procore-oss/blueprinter/actions/workflows/test.yaml/badge.svg?branch=master)](https://github.com/procore-oss/blueprinter/actions/workflows/test.yaml)
[![Gem Version](https://badge.fury.io/rb/blueprinter.svg)](https://badge.fury.io/rb/blueprinter)
[![Discord](https://img.shields.io/badge/Chat-EDEDED?logo=discord)](https://discord.gg/PbntEMmWws)

<img src="blueprinter_logo.svg" width="25%">

# Recent Organization Move

Please change your local remote to pull from this repository:

```bash
git remote set-url [previous-remote-name] git@github.com:procore-oss/blueprinter.git
```

to see the previous upstream remote name, run:

```bash
git remote -v
```

# Blueprinter

Blueprinter is a JSON Object Presenter for Ruby that takes business objects and breaks them down into simple hashes and serializes them to JSON. It can be used in Rails in place of other serializers (like JBuilder or ActiveModelSerializers). It is designed to be simple, direct, and performant.

It heavily relies on the idea of `views` which, similar to Rails views, are ways of predefining output for data in different contexts.

## Documentation

Docs can be found [here](http://www.rubydoc.info/gems/blueprinter).

## Usage

<details open>
<summary>Basic</summary>

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
</details>

<details>
<summary>Collections</summary>


You can also pass a collection object or an array to the render method.

```ruby
puts UserBlueprint.render(User.all)
```

This will result in JSON that looks something like this:

```json
[
  {
    "uuid": "733f0758-8f21-4719-875f-262c3ec743af",
    "email": "john.doe@some.fake.email.domain",
    "first_name": "John",
    "last_name": "Doe"
  },
  {
    "uuid": "733f0758-8f21-4719-875f-743af262c3ec",
    "email": "john.doe.2@some.fake.email.domain",
    "first_name": "John",
    "last_name": "Doe 2"
  }
]
```


You can also configure other classes to be treated like collections. For example, if you are using Mongoid, you can configure it to treat `Mongoid::Criteria` objects as collections:

```ruby
Blueprinter.configure do |config|
  config.custom_array_like_classes = [Mongoid::Criteria]
end
```

Or if you wanted it to treat the `Set` class as a collection:

```ruby
Blueprinter.configure do |config|
  config.custom_array_like_classes = [Set]
end
```

</details>

<details>
<summary>Renaming</summary>


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

</details>

<details>
<summary>Views</summary>


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

A view can include fields from another view by utilizing `include_view` and `include_views`.

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

</details>

<details>
<summary>Identifiers</summary>


`identifier`s are used to specify a field or method name used as an identifier. Usually, this is something like `:id`.

Example:

```rb
class UserBlueprint < Blueprinter::Base
  identifier :uuid
end
```

Blueprinter `identifier`s have a few properties that set them apart from `field`s.

1. Identifiers are **always** rendered and considered their own view (the `:identifier` view).
2. When rendering, identifier fields are always sorted first, before other fields.

If either of the above two developer conveniences are not desired, you can simply create your identifier fields as regular `field`s.


</details>

<details>
<summary>Root</summary>
<a name="root"></a>

You can also optionally pass in a root key to wrap your resulting json in:

```ruby
class UserBlueprint < Blueprinter::Base
  identifier :uuid
  field :email, name: :login

  view :normal do
    fields :first_name, :last_name
  end
end
```

Usage:

```ruby
puts UserBlueprint.render(user, view: :normal, root: :user)
```

Output:

```json
{
  "user": {
    "uuid": "733f0758-8f21-4719-875f-262c3ec743af",
    "first_name": "John",
    "last_name": "Doe",
    "login": "john.doe@some.fake.email.domain"
  }
}
```

</details>

<details>
<summary>Meta Attributes</summary>


You can additionally add meta-data to the json as well:

```ruby
class UserBlueprint < Blueprinter::Base
  identifier :uuid
  field :email, name: :login

  view :normal do
    fields :first_name, :last_name
  end
end
```

Usage:

```ruby
json = UserBlueprint.render(user, view: :normal, root: :user, meta: {links: [
  'https://app.mydomain.com',
  'https://alternate.mydomain.com'
]})
puts json
```

Output:

```json
{
  "user": {
    "uuid": "733f0758-8f21-4719-875f-262c3ec743af",
    "first_name": "John",
    "last_name": "Doe",
    "login": "john.doe@some.fake.email.domain"
  },
  "meta": {
    "links": [
      "https://app.mydomain.com",
      "https://alternate.mydomain.com"
    ]
  }
}
```

_NOTE:_ For meta attributes, a [root](#root) is mandatory.

</details>

<details>
<summary>Exclude Fields</summary>


You can specifically choose to exclude certain fields for specific views

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
    exclude :last_name
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
  "login": "john.doe@some.fake.email.domain"
}
```

Use `excludes` to exclude multiple fields at once inline.

```ruby
class UserBlueprint < Blueprinter::Base
  identifier :uuid
  field :email, name: :login

  view :normal do
    fields :age, :first_name, :last_name,
  end

  view :extended do
    include_view :normal
    field :address
    excludes :age, :last_name
  end
end
```

</details>

<details>
<summary>Associations</summary>


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

It is also possible to pass options from one Blueprint to another via an association.
For example:

```ruby
class VehicleBlueprint < Blueprinter::Base
  identifier :uuid
  field :full_name do |vehicle, options|
    "#{vehicle.model} #{options[:trim]}"
  end
end

class DriverBlueprint < Blueprinter::Base
  identifier :uuid

  view :normal do
    fields :first_name, :last_name
    association :vehicles, blueprint: VehicleBlueprint, options: { trim: 'LX' }
  end
end
```

</details>

<details>
<summary>Default Association/Field Option</summary>


By default, an association or field that evaluates to `nil` is serialized as `nil`. A default serialized value can be specified as an option on the association or field for cases when the association/field could potentially evaluate to `nil`. You can also specify a global `field_default` or `association_default` in the Blueprinter config which will be used for all fields/associations that evaluate to nil.

### Global Config Setting

```ruby
Blueprinter.configure do |config|
  config.field_default = "N/A"
  config.association_default = {}
end
```

### Field-level/Association-level Setting

```ruby
class UserBlueprint < Blueprinter::Base
  identifier :uuid

  view :normal do
    field :first_name, default: "N/A"
    association :company, blueprint: CompanyBlueprint, default: {}
  end
end
```

</details>

<details>
<summary>default_if</summary>


Sometimes, you may want certain "empty" values to pass through to the default value.
Blueprinter provides the ability to treat the following empty types as the default value (or `nil` if no default provided).

### Blueprinter::EMPTY_COLLECTION

An empty array or empty active record collection.

### Blueprinter::EMPTY_HASH

An empty hash.

### Blueprinter::EMPTY_STRING

An empty string or symbol.

#### Field-level/Association-level Setting - EMPTY_STRING

```ruby
class UserBlueprint < Blueprinter::Base
  identifier :uuid

  view :normal do
    # If first_name is an empty string, it will become "N/A"
    field :first_name, default_if: Blueprinter::EMPTY_STRING, default: "N/A"
    # If the projects association collection is empty, it will become nil
    association :projects, blueprint: ProjectBlueprint, default_if: Blueprinter::EMPTY_COLLECTION
  end
end
```

</details>

<details>
<summary>Supporting Dynamic Blueprints For Associations</summary>


When defining an association, we can dynamically evaluate the blueprint. This comes in handy when adding polymorphic associations, by allowing reuse of existing blueprints.

```ruby
class Task < ActiveRecord::Base
  belongs_to :taskable, polymorphic: true
end

class Project < ActiveRecord::Base
  has_many :tasks, as: :taskable

  def blueprint
    ProjectBlueprint
  end
end

class TaskBlueprint < Blueprinter::Base
  identifier :uuid

  view :normal do
    field :title, default: "N/A"
    association :taskable, blueprint: ->(taskable) {taskable.blueprint}, default: {}
  end
end
```

_NOTE:_ `taskable.blueprint` should return a valid Blueprint class. Currently, `has_many` is not supported because of the very nature of polymorphic associations.

</details>

<details>
<summary>Defining A Field Directly In The Blueprint</summary>


You can define a field directly in the Blueprint by passing it a block. This is especially useful if the object does not already have such an attribute or method defined, and you want to define it specifically for use with the Blueprint. This is done by passing `field` a block. The block also yields the object and any options that were passed from `render`. For example:

```ruby
class UserBlueprint < Blueprinter::Base
  identifier :uuid
  field :full_name do |user, options|
    "#{options[:title_prefix]} #{user.first_name} #{user.last_name}"
  end
end
```

Usage:

```ruby
puts UserBlueprint.render(user, title_prefix: "Mr")
```

Output:

```json
{
  "uuid": "733f0758-8f21-4719-875f-262c3ec743af",
  "full_name": "Mr John Doe"
}
```

</details>

<details>
<summary>Accessing the View Option</summary>


The `view` provided to the `render` call is implicitly available in the `options` hash within a `field` block, and can be referenced as needed. For example:

```ruby
class UserBlueprint < Blueprinter::Base
  identifier :uuid
  field :full_name do |user, options|
    prefix = options[:view] == :admin ? '[Admin]' : options[:title_prefix]
    "#{prefix} #{user.first_name} #{user.last_name}"
  end

  view :admin do
    field :access_level
  end
end
```

Usage:

```ruby
puts UserBlueprint.render(user, title_prefix: "Mr", view: :admin)
```

Output:

```json
{
  "uuid": "733f0758-8f21-4719-875f-262c3ec743af",
  "full_name": "[Admin] John Doe",
  "access_level": "4"
}
```

</details>

<details>
<summary>Defining An Identifier Directly In The Blueprint</summary>


You can also pass a block to an identifier:

```ruby
class UserBlueprint < Blueprinter::Base
  identifier :uuid do |user, options|
    options[:current_user].anonymize(user.uuid)
  end
end
```

Usage:

```ruby
puts UserBlueprint.render(user, current_user: current_user)
```

Output:

```json
{
  "uuid": "733f0758-8f21-4719-875f-262c3ec743af",
}
```

</details>

<details>
<summary>Defining An Association Directly In The Blueprint</summary>


You can also pass a block to an association:

```ruby
class ProjectBlueprint < Blueprinter::Base
  identifier :uuid
  field :name
end

class UserBlueprint < Blueprinter::Base
  identifier :uuid

  association :projects, blueprint: ProjectBlueprint do |user, options|
    user.projects + options[:draft_projects]
  end
end
```

Usage:

```ruby
puts UserBlueprint.render(user, draft_projects: Project.where(draft: true))
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

</details>

<details>
<summary>Passing Additional Properties To #render</summary>


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

</details>

<details>
<summary>Conditional Fields</summary>


Both the `field` and the global Blueprinter Configuration supports `:if` and `:unless` options that can be used to serialize fields conditionally.

### Global Config Setting - if and unless

```ruby
Blueprinter.configure do |config|
  config.if = ->(field_name, obj, _options) { !obj[field_name].nil? }
  config.unless = ->(field_name, obj, _options) { obj[field_name].nil? }
end
```

#### Field-level Setting

```ruby
class UserBlueprint < Blueprinter::Base
  identifier :uuid
  field :last_name, if: ->(_field_name, user, options) { user.first_name != options[:first_name] }
  field :age, unless: ->(_field_name, user, _options) { user.age < 18 }
end
```

_NOTE:_ The field-level setting overrides the global config setting (for the field) if both are set.

</details>

<details>
<summary>Exclude Fields with nil Values</summary>


By default, fields with `nil` values are included when rendering. You can override this behavior by setting `:exclude_if_nil: true` in the field definition. 

Usage:

```ruby
class UserBlueprint < Blueprinter::Base
  identifier :uuid

  field :name
  field :birthday, exclude_if_nil: true
end

user = User.new(name: 'John Doe')
puts UserBlueprint.render(user)
```

Output:

```json
{
  "name": "John Doe"
}
```

</details>

<details>
<summary>Custom Formatting for Dates and Times</summary>


To define a custom format for a Date or DateTime field, include the option `datetime_format`.
This global or field-level option can be either a string representing the associated `strftime` format,
or a Proc which receives the original Date/DateTime object and returns the formatted value.
When using a Proc, it is the Proc's responsibility to handle any errors in formatting.

#### Global Config Setting - datetime

If a global datetime_format is set (either as a string format or a Proc), this option will be
invoked and used to format all fields that respond to `strftime`.

```ruby
Blueprinter.configure do |config|
  config.datetime_format = ->(datetime) { datetime.nil? ? datetime : datetime.strftime("%s").to_i }
end
```

#### Field-level Setting - datetime_format

Usage (String Option):

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

Usage (Proc Option):

```ruby
class UserBlueprint < Blueprinter::Base
  identifier :name
  field :birthday, datetime_format: ->(datetime) { datetime.nil? ? datetime : datetime.strftime("%s").to_i }
end
```

Output:

```json
{
  "name": "John Doe",
  "birthday": 762739200
}
```

_NOTE:_ The field-level setting overrides the global config setting (for the field) if both are set.

</details>

<details>
<summary>Transform Classes</summary>


Blueprinter provides the ability to specify `transform`s on views, which enable further
processing and transforming of resulting view field hashes prior to serialization.

Use `transform` to specify one transformer to be included for serialization.
A transformer is a class, extending `Blueprinter::Transformer` and implementing the `transform` method.
The modified `hash` object will be the resulting hash passed to serialization.

#### Example

Create a Transform class extending from `Blueprinter::Transformer`

```ruby
class DynamicFieldTransformer < Blueprinter::Transformer
  def transform(hash, object, _options)
    hash.merge!(object.dynamic_fields)
  end
end
```

```ruby
class User
  def dynamic_fields
    case role
    when :admin
      {
        employer: employer,
        time_in_role: determine_time_in role
      }
    when :maintainer
      {
        label: label,
        settings: generate_settings_hash
      }
    when :read_only
      {
        last_login_at: last_login_at
      }
    end
  end
end
```

Then specify the transform to use for the view.

```ruby
class UserBlueprint < Blueprinter::Base
  fields :first_name, :last_name
  transform DynamicTransformer
end
```

#### Transform across views

Transformers can be included across views:

```ruby
class UserBlueprint < Blueprinter::Base
  transform DefaultTransformer

  view :normal do
    transform ViewTransformer
  end

  view :extended do
    include_view :normal
  end
end
```

Both the `normal` and `extended` views have `DefaultTransformer` and `ViewTransformer` applied.

Transformers are executed in a top-down order, so `DefaultTransformer` will be executed first, followed by `ViewTransformer`.

#### Global Transforms

You can also specify global default transformers. Create one or more transformer classes extending from `Blueprinter::Transformer` and set the `default_transformers` configuration

```ruby
class LowerCamelTransformer < Blueprinter::Transformer
  def transform(hash, _object, _options)
    hash.transform_keys! { |key| key.to_s.camelize(:lower).to_sym }
  end
end
```

```ruby
Blueprinter.configure do |config|
  config.default_transformers = [LowerCamelTransformer]
end
```

**Note: Any transforms specified on a per-blueprint or per-view level will override the `default_transformers` in the configuration.**

</details>

<details>
<summary>Configurable Extractors</summary>


Blueprinter gets a given objects' values from the fields definitions using extractor classes. You can substitute your own extractor class globally or per-field.

#### Examples

For a specific kind of field, create an extractor class extending from `Blueprinter::Extractor`

```ruby
class MyFieldExtractor < Blueprinter::Extractor
  def extract(_field_name, _object, _local_options, _options={})
    # process your obscure_object
    _object.clarified
  end
end
```

```ruby
class MysteryBlueprint < Blueprinter::Base
  field :obscure_object, extractor: MyFieldExtractor
end
```

For a global default, create an extractor class extending from `Blueprinter::AutoExtractor` and set the `extractor_default` configuration

```ruby
class MyAutoExtractor < Blueprinter::AutoExtractor
  def initialize
    super
    @my_field_extractor = MyFieldExtractor.new
  end
  def extractor(object, options)
    # dispatch to any class AutoExtractor can, plus more
    if detect_obscurity(object)
      @my_field_extractor
    else
      super
    end
  end
end
```

```ruby
Blueprinter.configure do |config|
  config.extractor_default = MyAutoExtractor
end
```

</details>

<details>
<summary>Sorting Fields</summary>


By default the response sorts the keys by name. If you want the fields to be sorted in the order of definition, use the below configuration option.

Usage:

```ruby
Blueprinter.configure do |config|
  config.sort_fields_by = :definition
end
```

```ruby
class UserBlueprint < Blueprinter::Base
  identifier :name
  field :email
  field :birthday, datetime_format: "%m/%d/%Y"
end
```

Output:

```json
{
  "name": "John Doe",
  "email": "john.doe@some.fake.email.domain",
  "birthday": "03/04/1994"
}
```

</details>

<details>
<summary>Reflection</summary>

Blueprint classes may be reflected on to inspect their views, fields, and associations. Extensions often make use of this ability.

```ruby
class WidgetBlueprint < Blueprinter::Base
  fields :name, :description
  association :category, blueprint: CategoryBlueprint

  view :extended do
    field :price
    association :parts, blueprint: WidgetPartBlueprint
  end
end

# A Hash of views keyed by name
views = WidgetBlueprint.reflections
views.keys
=> [:default, :extended]

# Hashes of fields and associations, keyed by name
fields = views[:default].fields
assoc = views[:default].associations

# Get info about a field
fields[:description].name
fields[:description].display_name
fields[:description].options

# Get info about an association
assoc[:category].name
assoc[:category].display_name
assoc[:category].blueprint
assoc[:category].view
assoc[:category].options
```
</details>

<details>
<summary>Extensions</summary>

Blueprinter offers an extension system to hook into and modify certain behavior.

```ruby
Blueprinter.configure do |config|
  config.extensions << MyExtension.new
  config.extensions << OtherExtension.new
end
```

Extension hooks:

* [pre_render](https://github.com/procore-oss/blueprinter/blob/abca9ca8ed23edd65a0f4b5ae43e25b8e27a2afc/lib/blueprinter/extension.rb#L18): Intercept the object before rendering begins

Some known extensions are:

* [blueprinter-activerecord](https://github.com/procore-oss/blueprinter-activerecord)
</details>

<details>
<summary>Deprecations</summary>


When functionality in Blueprinter is invoked, that has been deprecated, the default behavior is to
write a deprecation notice to stderror.

However, deprecations can be configured to report at three different levels:

|        Key        |                              Result                             |
|:-----------------:|:---------------------------------------------------------------:|
| `:stderr` (Default) | Deprecations will be written to stderror                        |
| `:raise`            | Deprecations will be raised as `Blueprinter::BlueprinterError`s |
| `:silence`          | Deprecations will be silenced and will not be raised or logged  |

### Example - deprecations

```ruby
Blueprinter.configure do |config|
  config.deprecations = :raise
end
```

</details>

<details>
<summary>render_as_hash</summary>


Same as `render`, returns a Ruby Hash.

Usage:

```ruby
puts UserBlueprint.render_as_hash(user, company: company)
```

Output:

```ruby
{
  uuid: "733f0758-8f21-4719-875f-262c3ec743af",
  company_name: "My Company LLC"
}
```

</details>

<details>
<summary>render_as_json</summary>


Same as `render`, returns a Ruby Hash JSONified. This will call JSONify all keys and values.

Usage:

```ruby
puts UserBlueprint.render_as_json(user, company: company)
```

Output:

```ruby
{
  "uuid" => "733f0758-8f21-4719-875f-262c3ec743af",
  "company_name" => "My Company LLC"
}
```

</details>

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'blueprinter'
```

And then execute:

```bash
bundle
```

Or install it yourself as:

```bash
gem install blueprinter
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

## Yajl-ruby

[yajl-ruby](https://github.com/brianmario/yajl-ruby) is a fast and powerful JSON generator/parser. To use `yajl-ruby` in place of `JSON / OJ`, use:

```ruby
require 'yajl' # you can skip this if yajl has already been required.

Blueprinter.configure do |config|
  config.generator = Yajl::Encoder # default is JSON
  config.method = :encode # default is generate
end
```

_NOTE:_ You should be doing this only if you aren't using `yajl-ruby` through the JSON API by requiring `yajl/json_gem`. More details [here](https://github.com/brianmario/yajl-ruby#json-gem-compatibility-api). In this case, `JSON.generate` is patched to use `Yajl::Encoder.encode` internally.

## Contributing

Please read our [Contributing](CONTRIBUTING.md) file

### Tests

You can run tests with `bundle exec rake`.

### Maintain The Docs

We use Yard for documentation. Here are the following documentation rules:

- Document all public methods we expect to be utilized by the end developers.
- Methods that are not set to private due to ruby visibility rule limitations should be marked with `@api private`.

## How to Document

We use [Yard](https://yardoc.org/) for documentation. Here are the following
documentation rules:

- Document all public methods we expect to be utilized by the end developers.
- Methods that are not set to private due to ruby visibility rule limitations should be marked with `@api private`.

### Releasing a New Version

To release a new version, change the version number in `version.rb`, and update the `CHANGELOG.md`. Finally, maintainers need to run `bundle exec rake release`, which will automatically create a git tag for the version, push git commits and tags to Github, and push the `.gem` file to rubygems.org.

## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).
