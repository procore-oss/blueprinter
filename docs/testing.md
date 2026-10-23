---
title: "Running and Writing Tests"
type: how-to
description: "Run the checks CI runs, and know where a new test belongs."
generated: { by: claude-code/claude-opus-5-5, at: "2026-10-21T22:02:01Z" }
verified:
  - { by: human:lessthanjacob, at: "2026-10-21T22:30:20Z" }
---

# Running and Writing Tests

## Run the Checks

CI runs the same two commands on every supported Ruby (see `.github/workflows/test.yaml`), so if they pass locally, the PR _should_ pass too:

```sh
bundle install
bundle exec rake                                       # specs, then RuboCop
bundle exec rake benchmarks                            # after touching the render path
bundle exec rspec spec/integrations/base_spec.rb:51    # one example
bundle exec rubocop -a                                 # fix safe lint offenses
```

## Add a Test

Blueprinter renders plain objects, `Hash`es, and `ActiveRecord` models, and a behavior that works for one can break for another (a `Hash` is read by key, the others by method call), so most rendering behavior needs to hold for all three. The **shared examples** exist to make that the default rather than something each test has to remember.

### Behavior Every Object Must Support

Add a `context` to `spec/integrations/shared/base_render_examples.rb` that defines a blueprint and the JSON it should produce:

```ruby
context 'Given blueprint has ::field' do
  let(:result) { '{"first_name":"Meg","id":' + obj_id + '}' }
  let(:blueprint) do
    Class.new(Blueprinter::Base) do
      field :id
      field :first_name
    end
  end
  it('returns json with specified fields') { should eq(result) }
end
```

`spec/integrations/base_spec.rb` runs that context three times (once per object type), and supplies `obj`, `obj_id`, and `subject { blueprint.render(obj) }` for each.

### Everything Else That Renders

Behavior that only makes sense for one object type (associations, `ActiveRecord` relations, array-like classes, `render_as_hash`, `render_as_json`, inheritance) goes directly in `spec/integrations/base_spec.rb`.

### Class-Level Behavior

Field ordering, transformer ordering, and the view cache are internal to a class, so test them on the class itself (in the `spec/units/` file named after it) rather than through a full render:

```ruby
it 'caches fields_for results across calls' do
  first_call = view_collection.fields_for(:view)
  second_call = view_collection.fields_for(:view)

  expect(first_call).to equal(second_call)
end
```

### Configuration

**Configuration is global**, so a test that changes it _must_ reset it. Otherwise the change leaks into every test that runs after it (and the failure shows up somewhere unrelated):

```ruby
before { Blueprinter.configure { |config| config.generator = JSON } }
after { reset_blueprinter_config! }
```

### Deprecations

Assert the exact warning, since the message is what users act on:

```ruby
it 'logs a deprecation warning' do
  expect(Blueprinter::Deprecation).to receive(:report).with(expected_message)
  subject
end
```

Define each blueprint inside a `let` with `Class.new(Blueprinter::Base)` (as above), so every test gets its own class and nothing carries over between them.

## Check Performance

The **benchmarks** guard the render path, since that path runs once per field of every rendered object. `bundle exec rake benchmarks` fails if rendering a 10-object array drops below 2,500 iterations per second (`spec/benchmarks/ips_test.rb`), or if render time stops scaling linearly (`big_o_test.rb`). The `ActiveRecord` versions run the same checks against database records, with a lower floor (2,000 iterations per second) and a looser linearity threshold.

CI only checks those floors, though. A change that makes rendering slower but stays above them will pass, so for any change to the render path, run the benchmarks on your branch _and_ on `main` (on the same machine), and put both iterations-per-second results in the PR.

## When a Spec Fails Alone

`spec/units/view_spec.rb` fails with `NameError: uninitialized constant Blueprinter::View` when run by itself. `View` only loads once something loads `Blueprinter::Base` ([why](architecture.md#loading-model)), and this spec doesn't `require` anything. Run it with another spec:

```sh
bundle exec rspec spec/units/view_collection_spec.rb spec/units/view_spec.rb
```

## Test Support Files

- `spec/spec_helper.rb` loads the library and defines `reset_blueprinter_config!`.
- `spec/activerecord_helper.rb` sets up an in-memory `SQLite` database with `User` and `Vehicle` models and their `FactoryBot` factories (`create(:user)`).
- `spec/generator_helper.rb` sets up `ammeter` for the `Rails` generator specs (which write into `tmp/`).
- `spec/support/mock_field.rb` provides `MockField` for the `View` and `ViewCollection` unit specs.
