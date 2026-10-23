# Guidance for Robots

## Project Overview

Blueprinter is a pure-Ruby JSON presenter. Additional context can be found in [docs/architecture.md](docs/architecture.md).

## Guidance

Before any code exploration or implementation, consult the existing documentation through [docs/index.md](docs/index.md).

A document under `docs/` counts as human-reviewed only when its latest `verified` entry from a `human:` actor is at or after its `generated.at` ([trust](docs/writing-docs.md#trust-signals)). Otherwise treat its claims as leads and confirm them against the code before relying on them.

## Useful Commands

| Purpose         | Command                                                      |
| --------------- | ------------------------------------------------------------ |
| Install         | `bundle install`                                             |
| Run Tests       | `bundle exec rspec`                                          |
| Full Validation | `bundle exec rake` ([tasks](docs/testing.md#run-the-checks)) |

## Hard Rules

1. Do not break a downstream caller. Public API is everything not tagged `@api private` that users call, subclass, or override as the README or YARD documents, whatever its Ruby visibility: `Base`'s class methods, every `Configuration` accessor, `Extension`, `Extractor`, `AutoExtractor` (including the private `extractor` hook), `Transformer`, the error hierarchy, and the `reflections` structs. Removals and output changes need a ‼️ `[BREAKING]` CHANGELOG entry and a prior deprecation release for removals, and never ship in a patch. Adding a key to `local_options` counts, because field blocks receive it as keyword arguments ([public API](docs/architecture.md#public-api-and-compatibility)).
2. CHANGELOG entry for every user-facing change under `## Unreleased` ([format](docs/releasing.md#changelog-format)).
3. DCO: every commit signed off (`git commit -s`), email matching the GitHub primary email ([CONTRIBUTING.md](CONTRIBUTING.md)).
4. No new runtime dependencies without maintainer agreement; never `require` `ActiveRecord`, `ActiveSupport`, `Oj`, or `Yajl` under `lib/` ([external dependencies](docs/architecture.md#external-dependencies)).
5. No new allocations on the render hot path (`rendering.rb`, `field.rb`, `extractors/`), even in a one-line change ([render performance](docs/architecture.md#render-performance)).
6. Never bump `lib/blueprinter/version.rb` in a feature PR; a merged version change on `main` publishes the gem ([releasing.md](docs/releasing.md#how-publishing-works)).

## Verification Gates

While in the inner-development loop, pass the following gates before pushing changes:

1. New or changed behavior has a spec that exercises it, in the place that [testing.md](docs/testing.md#add-a-test) describes. For a bug fix, the spec fails on `main` and passes on the branch.
2. `bundle exec rake` passes (specs and `RuboCop`). `bundle exec rubocop -a` fixes safe lint offenses.
3. Render-path changes don't regress performance beyond normal run-to-run variation. Run `bundle exec rake benchmarks` on the branch and on `main`, on the same machine, and put both numbers in the PR ([check performance](docs/testing.md#check-performance)).
4. Relevant documentation is created or updated, and each doc under `docs/` whose claims changed has its `generated` field (`by` and `at`) updated ([frontmatter](docs/writing-docs.md#frontmatter)). Typo, link, and formatting fixes leave `generated` alone. Add or update a `verified` entry only when a person says they reviewed the doc, keeping one entry per `human:` handle ([trust](docs/writing-docs.md#trust-signals)).

## Gotchas

- `view` blocks do not nest; the inner block resets scope to `:default`.
- Field blocks must accept `**` if they name keywords: every render passes `view:` plus all render options.
- `if: :symbol` resolves against the class that defined the field, so the method must be `def self.`; an inherited field still resolves against the parent ([how a render works](docs/architecture.md#how-a-render-works)).
- `sort_fields_by` and `extractor_default` must be set before blueprints are defined. `custom_array_like_classes`, `datetime_format`, `field_default`, `if`, `unless`, and `default_transformers` take effect on the next render; all but `custom_array_like_classes` do so by bumping the configuration generation ([when a change takes effect](docs/configuration.md#when-a-change-takes-effect)).
- `reflections` is memoized separately from the view cache and never refreshed ([reflection](docs/extension-points.md#reflection)).
- `pre_render` fires for every association value, not just the top-level object ([extension](docs/extension-points.md#extension)).
- The README spells the `deprecations` value `:stderr`; the code expects `:stderror` ([configuration.md](docs/configuration.md#notes)). Its "Releasing a New Version" section is out of date ([releasing.md](docs/releasing.md#how-publishing-works)).
