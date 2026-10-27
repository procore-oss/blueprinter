---
title: "Running and Writing Tests"
type: how-to
description: "Run the checks CI runs, and know where a new test belongs."
generated: { by: cursor/claude-fable-5.1, at: "2026-10-27T21:01:11Z" }
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
LIST=1 bundle exec rake perf                          # render scenarios (not run by CI)
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

CI only checks those floors, though. A change that makes rendering slower but stays above them will pass, so for any change to the render path, show before and after with `rake perf`. What it measures and how to weigh the numbers is in [benchmarking.md](benchmarking.md).

`bundle exec rake perf` (`spec/benchmarks/perf/`) measures rendering across many setups and inputs. It varies one thing at a time from a baseline (input kind, collection size, width, nesting, nil values, defaults, value types, field kinds, conditions, views, transformers, extensions, render options, output path, lifecycle, and concurrency) and adds a few composite profiles that combine many of them. Before timing a scenario it renders it once, drops it if that render raised or issued SQL, and keeps a digest of the output. While it runs it shows a progress bar naming the scenario being measured (one line per scenario instead when stderr isn't a terminal). When it finishes it writes two files under `benchmarks/results/` (gitignored; `OUT_DIR` changes it): `perf-<timestamp>-<interp|yjit>.md`, the report, with one table per sweep (median wall time, the run's own noise as `IQR`, CPU time, allocations per rendered object, and GC share) and the top allocation sites for a few scenarios; and the same results as JSON, for comparing. The terminal shows only the two paths, one line of environment, and any skipped scenarios. The default location is outside `tmp/` because the generator specs wipe that directory when `rake spec` runs.

To show the effect of a change, run it on `main`, run it on the branch, and compare:

```sh
git switch main
bundle exec rake perf
git switch my-branch
BASELINE=latest bundle exec rake perf         # or BASELINE=benchmarks/results/perf-<timestamp>-interp.json
```

`BASELINE=latest` is the newest results file written under the same YJIT setting. The second run ends with the comparison, which starts with a `Changed` table: every scenario whose time moved beyond noise, whose allocation count changed by more than two objects per render, or whose output digest changed, with the change in median wall time, median CPU time, and allocations per rendered object (for example `−12%`). A time change smaller than either run's `IQR` is marked `~`: a difference that size shows up between batches of a single run, so it is not evidence of a change. Below that, collapsed, is the same comparison for every scenario, then the scenarios missing from either run. It warns when the Ruby version, YJIT setting, machine, or system load differ between the two, when either run had uncommitted changes, or when either run used too few samples for the noise estimate to mean anything. Run both on the same machine with nothing else running, and keep the settings identical (`SAMPLES`, `SIZES`, `SWEEPS`, `RUBYOPT`). Allocation counts don't depend on load (GC is disabled during the count), so an allocation change of more than a few objects per render is real; put the `Changed` table in the PR.

```sh
QUICK=1 bundle exec rake perf                                         # every scenario in under a minute; checks that a change runs, not how fast
SWEEPS=input_kind,size SIZES=1,100 bundle exec rake perf              # a subset at full samples
RUBYOPT=--yjit bundle exec rake perf                                  # the same under YJIT
LIST=1 bundle exec rake perf                                          # the sweep names
BASELINE=a.json CURRENT=b.json bundle exec rake perf:compare          # compare two earlier runs (CURRENT defaults to the newest)
```

Each sweep is a file under `spec/benchmarks/perf/sweeps/` that defines the blueprints for every scenario explicitly. A new scenario goes in the sweep for the axis it varies; one that combines several axes goes in `profiles.rb`. A scenario that needs an optional gem passes `requires:` (see `FEATURES` in `harness.rb`; `multi_json` is the one such gem, and it is not in the `Gemfile`, so that scenario is listed under "Skipped scenarios"). The knobs (`SAMPLES`, `SAMPLE_MS`, `BUDGET_S`, `GC_MS`, `WARMUP_MS`, `SEED`, `PROFILE=0`) are listed at the top of `run.rb`; `QUICK=1` sets small values for all of them.

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
