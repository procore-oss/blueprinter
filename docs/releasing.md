---
title: "Releasing a Version"
type: how-to
description: "Cut and publish a release safely."
generated: { by: claude-code/claude-opus-5-5, at: "2026-10-21T22:05:17Z" }
verified:
  - { by: human:lessthanjacob, at: "2026-10-21T22:30:20Z" }
---

# Releasing a Version

Merging a version bump to `main` publishes the gem with no manual approval step ([How Publishing Works](#how-publishing-works)), so the **release PR** _is_ the release: everything has to be right before it merges.

## Steps

1. Confirm `main` is green and the `## Unreleased` section of `CHANGELOG.md` lists every user-facing change since the last version.
2. Choose the version: a patch for fixes only; a minor or major for anything with a ‼️ `[BREAKING]` entry or a removal ([removal policy](architecture.md#public-api-and-compatibility)).
3. In `CHANGELOG.md`, rename `## Unreleased` to `## X.Y.Z - YYYY/MM/DD` (slash-separated date, as in `## 1.3.0 - 2026/04/14`) and add a fresh `## Unreleased` with the `--` placeholder above it.
4. Set `VERSION` in `lib/blueprinter/version.rb`.
5. Open a PR titled `Release vX.Y.Z` containing only the CHANGELOG and version changes, signed off (`git commit -s`).
6. Merge. Watch the `Test` workflow, then the `Release` workflow; confirm the gem on rubygems.org and the new `vX.Y.Z` tag.
7. If the gem must be withdrawn, yank it on rubygems.org and mark its CHANGELOG heading `[REMOVED]`, as in `## [REMOVED] 1.2.0 - 2025/09/10`.

## How Publishing Works

`.github/workflows/release.yaml` runs after every successful `Test` workflow on `main`, and on manual dispatch. After a `Test` run it publishes only if `tj-actions/changed-files` reports a change to `lib/blueprinter/version.rb`; on manual dispatch it skips that check and publishes unconditionally. Publishing builds the gem on Ruby 3.2 (`bundle exec rake build`), sets rubygems credentials from the `RUBY_GEMS_API_KEY` secret, and pushes through `fac/ruby-gem-push-action`, which also pushes the `v{VERSION}` git tag.

- Merging any change to `version.rb` into `main` publishes a gem. Feature PRs must not bump the version (`.github/PULL_REQUEST_TEMPLATE.md`).
- README "Releasing a New Version" describes `bundle exec rake release`, which pushes the gem and tag from a local machine; the workflow already does both.

## CHANGELOG Format

The CHANGELOG (with the version tag) is the only release record, so entries follow one format:

```markdown
## Unreleased
--

## 1.3.0 - 2026/04/14
- 🚀 [FEATURE] Adds support for `Symbol#to_proc` syntax in fields and identifiers. See [#546](https://github.com/procore-oss/blueprinter/pull/546). Thanks to [@tob1k](https://github.com/tob1k).
- 🐛 [BUGFIX] ...
- 🚜 [REFACTOR] ...
```

- One line per change: emoji, bracketed type, sentence, then `See [#NNN](<pr url>).` and `Thanks to [@handle](<profile url>).` as Markdown links.
- Types in use: 🚀 `[FEATURE]`, 🐛 `[BUGFIX]`, 💅 `[ENHANCEMENT]`, 🚜 `[REFACTOR]`, ‼️ `[BREAKING]`, ⚠️ `[DEPRECATION]`. Tag a bug fix that changes observable behavior for extension authors `[BUGFIX] [BREAKING]`.
- Use `-` bullets, as the newest sections do.
- A deprecation gets a `[DEPRECATION]` entry in the release that introduces the warning; the removal appears later as a `[BREAKING]` entry.

## Version-Adjacent Files

- `blueprinter.gemspec` reads `Blueprinter::VERSION`; nothing else to bump.
- `SECURITY.md` lists the supported Ruby versions; update it when the CI matrix or gemspec floor changes.
- `.github/workflows/test.yaml` is the Ruby matrix; dropping a version there without a gemspec and CHANGELOG `[BREAKING]` change is incomplete.
