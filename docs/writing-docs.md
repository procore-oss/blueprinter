---
title: "Writing Docs"
type: how-to
description: "Add or update a doc under `docs/` so readers can find it, trust it, and tell whether it is still current."
generated: { by: claude-code/claude-opus-5-5, at: "2026-10-21T23:37:33Z" }
verified:
  - { by: human:lessthanjacob, at: "2026-10-21T23:42:19Z" }
---

# Writing Docs

Humans and agents both read documentation and act based on its content, so clear and up-to-date documentation can make working within the codebase much easier.

## Keeping Docs Current

A stale doc is often _worse_ than a missing one. Correct guidance can usually be inferred from the codebase when docs are missing, while an incorrect document misleads readers entirely.

To help keep docs current, please ensure the following:

- Changes that alter behavior described within `docs/` or in `AGENTS.md` update the relevant documentation in the same PR. To verify, search for the classes, methods, and signatures the change touches (e.g. `rg -n 'invalidate_cache!' docs AGENTS.md`).
- Every change to a doc's claims updates its `generated` field to the current date and time ([Frontmatter](#frontmatter)).

## Creating a New Doc

### Choosing a Type
Every doc has one [Diátaxis](https://diataxis.fr/) type, which decides what belongs in it.

| Type        | The reader wants to                            | Test                                                      | Examples                                                             |
| ----------- | ---------------------------------------------- | --------------------------------------------------------- | -------------------------------------------------------------------- |
| tutorial    | Learn by doing a guided exercise               | Would a newcomer follow it start to finish once?          | README "Basic" through "Identifiers"                                 |
| how-to      | Complete a task they already have              | Does it start from a goal and stop when the goal is met?  | `making-changes.md`, `testing.md`, `releasing.md`, `writing-docs.md` |
| reference   | Look up a fact                                 | Would a reader scan it rather than read it top to bottom? | `configuration.md`, `extension-points.md`                            |
| explanation | Understand why something works the way it does | Does it answer "why"?                                     | `architecture.md`                                                    |

When a doc starts mixing types, move the stray part to a doc of the right type. A procedure inside a reference doc belongs in a how-to; a long rationale inside a how-to belongs in the explanation.

### Frontmatter

Name each file for its subject (`configuration.md`), not its type; the type lives in frontmatter. Every doc under `docs/` except `index.md` starts with:

```yaml
---
title: "Configuration Reference"
type: reference
description: "Find out what a configuration option does and when changing it takes effect."
generated: { by: human:octocat, at: "2026-10-19T14:00:00Z" }
verified:
  - { by: human:octocat, at: "2026-10-19T14:00:00Z" }
---
```

| Field         | Meaning                                                                                                                                                                      |
| ------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `title`       | Matches the doc's `#` heading.                                                                                                                                               |
| `type`        | One of the four types in [Choosing a Type](#choosing-a-type).                                                                                                                |
| `description` | Why a reader opens the doc: their goal, not a list of its sections.                                                                                                          |
| `generated`   | Who or what last changed the content, and when. Update it with every change to the doc's claims. Use `human:<github-handle>` for a person and `<tool>/<model>` for an agent. |
| `verified`    | Who checked the content against the code, and when. One entry per reviewer: a re-review updates that reviewer's `at` instead of adding an entry.                             |

`generated` and `verified` are the trust fields from the [Open Knowledge Format](https://github.com/GoogleCloudPlatform/knowledge-catalog/blob/main/okf/SPEC.md) (§5.2). After adding, renaming, or removing a doc, or changing its `title`, `type`, or `description`, update the table in [index.md](index.md) in the same PR.

### Writing Guidelines

- State facts about the code and the reasons behind them. Leave out how a decision was reached (PR threads, review comments, release-by-release history); the git history keeps that.
- Put design rationale next to the mechanism it explains in [architecture.md](architecture.md), and rules for how contributors work in [making-changes.md](making-changes.md#every-change). To overturn one, edit that text in the same PR as the change.
- Link to code paths instead of pasting implementations. Short usage examples are fine; run them and show their real output.
- No sentence takes the doc itself as its subject ("This section covers…"). Headings name the content, in title case.
- Open a section with why it matters before what to do, so readers can judge cases the doc doesn't cover.
- Format classes, methods, gems, and options as code. Bold Blueprinter's own concepts (**shared examples**, **view collection**), not tool names. Use italics sparingly for qualifiers (_must_, _per render_), and parentheticals for consequences a reader would otherwise miss.
- Write one line per paragraph or list item; don't hard-wrap prose.

## Trust Signals

A doc counts as **human-reviewed** when its latest `verified` entry from a `human:` actor is at or after `generated.at`. Otherwise nobody has reviewed it, or it changed after the last review, so treat its claims as leads to confirm against the code.

To review a doc, check each claim against the code, run any examples, then add `{ by: human:<github-handle>, at: <now> }` to `verified`, or update `at` on your existing entry. Earlier review dates stay in the git history. A human author who checked their own change can add both entries at once.

An agent can write the `verified` entry, but only on behalf of a person: when that person says they have reviewed the doc, the agent records it under their `human:` handle. An agent never verifies a doc on its own behalf, since its own check is what `generated` already records.

Fixes that change no claim (typos, broken links, formatting) leave `generated` alone, so they don't reset a doc's review.

