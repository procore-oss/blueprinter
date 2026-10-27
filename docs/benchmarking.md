---
title: "Benchmarking"
type: explanation
description: "Understand what `rake perf` measures, why each number is computed the way it is, and how far to trust a difference between two runs."
generated: { by: cursor/claude-fable-5.1, at: "2026-10-27T22:02:30Z" }
verified:
---

# Benchmarking

Blueprinter's render path runs once per field of every rendered object, so a small cost there is multiplied by the size of every response an application serializes. CI guards that path with two floors (`spec/benchmarks/ips_test.rb` and `big_o_test.rb`, run by `rake benchmarks`), but a floor only catches a large regression. `bundle exec rake perf` (`spec/benchmarks/perf/`) exists to answer the finer question a render-path change raises: what got faster or slower, by how much, for which inputs, and is the difference larger than the measurement's own noise. The commands are in [testing.md](testing.md#check-performance).

## One Factor at a Time

A single "render 100 records" number can't say where time goes or which change moved it. The suite instead fixes a **baseline shape** and varies one thing at a time from it. The baseline is 100 Symbol-keyed Hash widgets, each with an id, 20 plain fields (alternating strings and integers), one company (an object association with 3 fields), and 3 parts (a collection association with 3 fields each), rendered to a Hash through the default view with warm classes ([`blueprints.rb`](../spec/benchmarks/perf/blueprints.rb)).

Each **sweep** under [`sweeps/`](../spec/benchmarks/perf/sweeps/) changes one axis of that shape and holds everything else: the kind of input object (`input_kind`), collection size, fields per object, nesting depth and fan-out, the kind of association, repeated child objects, nil values and `exclude_if_nil`, defaults, value types and date formatting, how a field is defined (plain, renamed, block, `Symbol#to_proc`, custom extractor), conditions, views, transformers, extensions, render options, the output path (Hash, stdlib JSON, Oj, `render_as_json`), and the lifecycle (first render, definition, boot). Reading down a sweep's table shows the cost of that axis alone; reading the same row across two runs shows what a change did to it.

Two sweeps work differently. `breakdown` builds the baseline up one part at a time (id only, then 20 fields, then the object association, then the collection, then JSON), so the differences between adjacent rows attribute the baseline's time to its parts without a sampling profiler. `profiles` goes the other way and combines many axes into shapes resembling real endpoints (an ActiveRecord list to JSON at depth 3, an order tree at depth 4, a 5,000-row export); these catch interactions that no single-factor sweep would, at the cost of not saying which factor is responsible.

ActiveRecord scenarios use in-memory SQLite models ([`records.rb`](../spec/benchmarks/perf/records.rb)) with associations preloaded, and they reload the records for every job (`fresh_input: true`) because ActiveRecord caches attribute casting on the record (`ActiveModel::Attribute#value` memoizes the cast value). Reusing one set of records would measure the second render of each attribute, which an application rarely does.

## What a Scenario Is

A scenario is a label, an optional configuration block, and a build block that returns a `Setup`: an input builder and one or more **engines**, each a way of rendering that input ([`harness.rb`](../spec/benchmarks/perf/harness.rb)). The build block is deferred rather than run at definition time so that the runner can `Blueprinter.reset_configuration!`, apply the scenario's configuration, and only then define the blueprint classes. Every scenario defines fresh classes, through the builders in `blueprints.rb` or `Class.new` in the sweep, for the same reason: a view compiled under one configuration must not be reused by the next scenario.

An engine's `prepare` hook separates setup from the timed work. The lifecycle sweep uses it to define a fresh blueprint tree before each timed first render, so the measured time is compile-plus-render and the class definition itself is excluded.

A scenario that needs an optional gem declares `requires:`; when the gem isn't loadable the scenario is recorded as skipped with the reason instead of failing the run (`multi_json` is the one such gem, and it isn't in the `Gemfile`).

## The Gate

Before anything is timed, each engine renders the scenario once ([`Gate`](../spec/benchmarks/perf/runner.rb)). An engine that raises is excluded with the exception; an engine that issues SQL during the render is excluded with the query count, because a render that lazy-loads associations measures the database, not Blueprinter. The gate also records two facts the timing needs: the number of Hashes in the output, which is the **rendered objects** that allocations are normalized by, and a SHA-256 digest of the output with Hash keys sorted. Field order doesn't affect the digest, so a change that only reorders keys compares as the same output, while a change that alters a value or drops a field is reported even when it made rendering faster.

## How a Scenario Is Timed

Per-render times in this suite span four orders of magnitude, from a single Struct in tens of microseconds to 10,000 widgets in hundreds of milliseconds, so one fixed loop count would either take minutes on the large scenarios or measure clock overhead on the small ones. Each engine is first warmed for at least 30 renders and `WARMUP_MS`, and the fastest of the last five renders sets the batch size: enough renders to fill `SAMPLE_MS`, so every batch is long enough to time, and as many batches as `BUDGET_S` affords up to `SAMPLES`.

Batches of different engines in the same scenario are interleaved in shuffled order, so a load spike lands on all of them rather than on whichever ran second. Each batch records wall time and thread CPU time (`CLOCK_THREAD_CPUTIME_ID`). The reported `ms` and `CPU ms` are medians of the batch means. CPU time is kept alongside wall time because they disagree in a characteristic way under load: a wall time that rose while CPU time didn't is the machine, not the code.

The **IQR** column is the interquartile range of the batch means divided by the median. It is the run's own noise estimate, and it is what the comparison uses to decide whether a difference means anything.

Allocations are counted once per render with `GC.stat(:total_allocated_objects)` while GC is disabled, so nothing is collected mid-count. The minimum of three renders is kept to drop first-use effects. Allocation counts don't depend on load, which makes them the steadiest signal in the suite: a change of more than a couple of objects per render is a real change in the code's behavior, whatever the timings say. They are reported per rendered object so that scenarios of different sizes compare.

GC share comes from a separate, longer run (`GC_MS`) in which input construction happens between measured stretches: its garbage still raises the heap the renders run against, but its time isn't counted. The column shows what fraction of wall time GC took during that run.

For a handful of scenarios the report also lists the top allocation sites from `ObjectSpace` allocation tracing ([`profile.rb`](../spec/benchmarks/perf/profile.rb)). Those are exact and usually explain an allocation-count difference between two runs by file and line. No sampling profiler is in the `Gemfile`, so wall-time attribution comes from the `breakdown` sweep instead.

## Comparing Two Runs

Every run writes its results as JSON next to the markdown report. `BASELINE=` (a file, or `latest` for the newest run under the same YJIT setting) compares the finished run against it, and `rake perf:compare` does the same for two existing files ([`compare.rb`](../spec/benchmarks/perf/compare.rb)).

A time change is reported as within noise (`~`) when it is no larger than the larger of the two runs' IQR ratios. A difference that size already shows up between batches inside a single run, so seeing it between two runs is not evidence of anything. The threshold is a plain cutoff rather than a significance test. The batch means aren't independent samples, and the bigger risks (a load spike, a different machine, YJIT on in one run) are better handled by the warnings the comparison prints when the Ruby version, YJIT setting, machine, load, sample count, or working-tree cleanliness differ between the runs.

The comparison leads with the scenarios that changed, which is any of: a time change beyond noise, an allocation change of more than two objects per render, or a different output digest. The full per-sweep tables follow, collapsed. The cutoff scales with each run's own spread, so a scenario with a tight IQR gets a small threshold: on identical code at full samples, two back-to-back runs flagged 5 of 104 rows, none by more than 6.3%, with every allocation count and digest unchanged. A single-digit time change with no allocation change is a lead to confirm with a second run, not a result. Under `QUICK=1` the `Changed` table fills with time rows on identical code, because three batches give a poor IQR, and the comparison says so.

## Reading an Example

Commit 29069ec fixed `||=` memoization of a field's `:if`/`:unless` callables, which returned `false` for fields without a condition and so re-ran the lookup on every field of every object. Running the suite with that hunk reversed as the baseline and the fixed code as current, on one laptop with the before run under somewhat higher load (1-minute average 9.9 against 7.7, so the magnitudes are indicative), gives:

> 104 scenarios compared, 94 changed: 94 faster and 0 slower beyond noise, 0 with a different allocation count, 0 with different output.

| scenario | ms | time | CPU | alloc/obj | alloc | output |
| --- | --- | --- | --- | --- | --- | --- |
| size / 100 | 2.49 -> 1.65 | −34% | −34% | 2.81 -> 2.81 | 0% | same |
| width / 50 | 4.47 -> 2.72 | −39% | −39% | 2.81 -> 2.81 | 0% | same |
| breakdown / + 20 plain fields | 1.62 -> 0.81 | −50% | −47% | 1.06 -> 1.06 | 0% | same |
| conditions / Proc if, 0% skipped | 2.44 -> 1.78 | −27% | −28% | 2.81 -> 2.81 | 0% | same |
| input_kind / ActiveRecord | 6.26 -> 5.09 | −19% | −18% | 11.3 -> 11.3 | 0% | same |
| profiles / AR orders: 100 orders to a Hash, depth 4 | 16.0 -> 13.7 | −15% | −15% | 9.95 -> 9.95 | 0% | same |

The sweeps say more than the headline. The gain is largest where plain fields dominate (`breakdown / + 20 plain fields`, `width / 50`) and smaller where other work does (ActiveRecord attribute casting, the deep order tree), which matches the fix's mechanism. Allocations and output digests are unchanged everywhere, so the change is pure CPU and didn't alter what is rendered. One row, `conditions / none`, showed wall `~ +12%` against CPU `~ −11%` and was marked within noise: wall and CPU disagreeing with a wide IQR is what a load spike on one scenario looks like, and the `~` kept it out of the `Changed` table.

## What the Suite Doesn't Tell You

Numbers from different machines, Ruby versions, or YJIT settings aren't comparable, and the comparison refuses to pretend otherwise: it warns and leaves the judgment to the reader. Load on the same machine shifts wall times by tens of percent, which is why the IQR, the CPU column, and the load warning all exist. Allocation counts are the thing to trust when the timings are in doubt.

The concurrency sweep measures contention overhead and first-render races under the GVL, not parallel speedup. CI doesn't run `rake perf` (it would be noise on a shared runner); the floors in `rake benchmarks` remain the automated check, and `rake perf` is the evidence a render-path PR carries ([making-changes.md](making-changes.md)).

## Where Things Live

| Path | Holds |
| --- | --- |
| [`run.rb`](../spec/benchmarks/perf/run.rb) | Entry point: environment knobs, sweep order, progress, which scenarios get allocation-site profiles |
| [`harness.rb`](../spec/benchmarks/perf/harness.rb) | `Sweep`, `Scenario`, `Setup`, `Engine`, optional-gem features |
| [`runner.rb`](../spec/benchmarks/perf/runner.rb) | The gate and the measurement of one scenario |
| [`report.rb`](../spec/benchmarks/perf/report.rb), [`markdown.rb`](../spec/benchmarks/perf/markdown.rb) | The markdown report and the JSON results file |
| [`compare.rb`](../spec/benchmarks/perf/compare.rb) | Two results files to a comparison |
| [`fixtures.rb`](../spec/benchmarks/perf/fixtures.rb), [`records.rb`](../spec/benchmarks/perf/records.rb) | Deterministic Hash/object/Struct inputs and the SQLite models |
| [`blueprints.rb`](../spec/benchmarks/perf/blueprints.rb) | The baseline blueprint builders and the extractor, transformer, and extension the sweeps share |
| [`sweeps/`](../spec/benchmarks/perf/sweeps/) | One file per group of axes; `profiles.rb` for composites, `lifecycle.rb` for first renders and concurrency |
