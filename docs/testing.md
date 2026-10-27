---
title: "Running and Writing Tests"
type: how-to
description: "Run the checks CI runs, and know where a new test belongs."
generated: { by: claude-code/claude-sonnet-5-5, at: "2026-10-26T15:20:14Z" }
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
LIST=1 bundle exec rake engines                       # render scenarios (not run by CI)
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

CI only checks those floors, though. A change that makes rendering slower but stays above them will pass, so for any change to the render path, show before and after with `rake engines`.

`bundle exec rake engines` (`spec/benchmarks/engines/`) measures rendering across many setups and inputs. It varies one thing at a time from a baseline (input kind, collection size, width, nesting, nil values, defaults, value types, field kinds, conditions, views, transformers, extensions, render options, output path, lifecycle, and concurrency) and adds a few composite profiles that combine many of them. Before timing a scenario it renders it with every engine and drops any engine whose output differs, listing the reason under the table. It prints one markdown table per sweep (median and p95 time, allocations per rendered object, and GC share), the top allocation sites for a few scenarios, and writes everything as JSON under `benchmarks/results/` (gitignored; `OUT_DIR` changes it). The default location is outside `tmp/` because the generator specs wipe that directory when `rake spec` runs.

To show the effect of a change, run it on `main`, run it on the branch, and compare:

```sh
git switch main
bundle exec rake engines                         # writes benchmarks/results/engines-<timestamp>-<interp|yjit>.json
git switch my-branch
BASELINE=benchmarks/results/engines-<timestamp>-interp.json bundle exec rake engines
```

The second run prints, for every scenario and engine, the change in median time and in allocations per rendered object against the baseline file (for example `−12%`), lists scenarios missing from either run, and warns when the Ruby version, YJIT setting, machine, or system load differ notably between the two. Run both on the same machine with nothing else running, and keep the settings identical (`SAMPLES`, `SIZES`, `SWEEPS`, `RUBYOPT`). Allocations are counted with GC disabled; timing deltas are subject to run-to-run variation, so repeat a run before trusting a small one, and put the allocation and time changes for the affected scenarios in the PR.

```sh
SWEEPS=input_kind,size SAMPLES=5 SIZES=1,100 bundle exec rake engines   # a quick subset
RUBYOPT=--yjit bundle exec rake engines                                  # the same under YJIT
LIST=1 bundle exec rake engines                                          # the sweep names
```

When `Blueprinter::V2` is defined, the run also measures the V2 and V2+Legacy engines next to V1 and adds ratio columns. Without it, V1 runs every scenario that applies to V1 and the report ends with a "Skipped scenarios" list: V2-only scenarios (V2 hook kinds) and scenarios that need a gem that isn't installed (`multi_json`, `opentelemetry-api`, neither of which is in the `Gemfile`).

Each sweep is a file under `spec/benchmarks/engines/sweeps/` that defines the blueprints for every scenario explicitly. A new scenario goes in the sweep for the axis it varies; one that combines several axes goes in `profiles.rb`. A scenario that needs an optional feature passes `requires:` (see `FEATURES` in `harness.rb`). The knobs (`SAMPLES`, `SAMPLE_MS`, `BUDGET_S`, `GC_MS`, `WARMUP_MS`, `SEED`, `PROFILE=0`) are listed at the top of `run.rb`.

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
