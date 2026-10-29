#!/usr/bin/env python3
"""Compare two directories of Blueprint snapshots produced by snapshot.rb.

Differences are split into two buckets, because they mean very different things in a V1 -> V2
migration:

  VALUE DIFFERENCES  - added keys, removed keys, changed values, render errors.
                       These are bugs unless you can explain every one.
  KEY ORDER ONLY     - the same keys and values in a different order. Expected, because V1 sorts
                       fields alphabetically (identifiers first) and V2 uses definition order.
                       Harmless if that reordering was a deliberate choice; a bug if the plan was
                       to preserve V1's order with the FieldOrder extension.

Usage:
    python3 compare_snapshots.py BEFORE_DIR AFTER_DIR [--strict-order] [--quiet]

Exit codes:
    0  no value differences (key-order differences may still be reported)
    1  value differences found, or key-order differences with --strict-order
    2  bad invocation
"""

import argparse
import json
import os
import sys
from collections import OrderedDict

MANIFEST = "_manifest.json"


def load(path):
    with open(path, encoding="utf-8") as handle:
        return json.load(handle, object_pairs_hook=OrderedDict)


def snapshot_files(directory):
    return {
        name
        for name in os.listdir(directory)
        if name.endswith(".json") and name != MANIFEST
    }


def compare(before, after, path, values, orders):
    """Walk two parsed snapshots, appending findings to `values` and `orders`."""
    if isinstance(before, OrderedDict) and isinstance(after, OrderedDict):
        before_keys, after_keys = list(before.keys()), list(after.keys())

        for key in before_keys:
            if key not in after:
                values.append(f"{path}.{key}: removed (was {short(before[key])})")
        for key in after_keys:
            if key not in before:
                values.append(f"{path}.{key}: added ({short(after[key])})")

        if before_keys != after_keys and sorted(before_keys) == sorted(after_keys):
            orders.append(f"{path or '(root)'}: {before_keys} -> {after_keys}")

        for key in before_keys:
            if key in after:
                compare(before[key], after[key], f"{path}.{key}", values, orders)
        return

    if isinstance(before, list) and isinstance(after, list):
        if len(before) != len(after):
            values.append(f"{path}: length {len(before)} -> {len(after)}")
        for index, (b_item, a_item) in enumerate(zip(before, after)):
            compare(b_item, a_item, f"{path}[{index}]", values, orders)
        return

    if type(before) is not type(after) and not (before is None or after is None):
        values.append(f"{path}: type {type(before).__name__} -> {type(after).__name__}")
        return

    if before != after:
        values.append(f"{path}: {short(before)} -> {short(after)}")


def error_of(snapshot):
    """snapshot.rb records a failed render as {"__error__": "..."} instead of output."""
    if isinstance(snapshot, dict):
        return snapshot.get("__error__")
    return None


def short(value, limit=60):
    text = json.dumps(value, default=str)
    return text if len(text) <= limit else text[: limit - 3] + "..."


def main():
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("before")
    parser.add_argument("after")
    parser.add_argument(
        "--strict-order",
        action="store_true",
        help="treat key-order differences as failures (use when preserving V1 field order)",
    )
    parser.add_argument("--quiet", action="store_true", help="only print differences")
    args = parser.parse_args()

    for directory in (args.before, args.after):
        if not os.path.isdir(directory):
            parser.error(f"not a directory: {directory}")

    before_files = snapshot_files(args.before)
    after_files = snapshot_files(args.after)

    value_findings = []
    order_findings = []

    for name in sorted(before_files - after_files):
        value_findings.append(f"{name}: snapshot missing after conversion")
    for name in sorted(after_files - before_files):
        value_findings.append(f"{name}: new snapshot, no baseline to compare against")

    compared = 0
    clean = 0
    for name in sorted(before_files & after_files):
        before = load(os.path.join(args.before, name))
        after = load(os.path.join(args.after, name))

        values, orders = [], []
        before_error, after_error = error_of(before), error_of(after)
        if before_error or after_error:
            # One line beats a key-by-key diff against a crash. The error is the finding.
            if after_error and not before_error:
                values.append(f"render now raises: {after_error}")
            elif before_error and not after_error:
                values.append(f"render used to raise ({before_error}) and now succeeds")
            elif before_error != after_error:
                values.append(f"render raises differently: {before_error} -> {after_error}")
        else:
            compare(before, after, "", values, orders)
        compared += 1

        label = name[: -len(".json")]
        if values:
            value_findings.append(f"\n  {label}")
            value_findings.extend(f"    {line}" for line in values)
        if orders:
            order_findings.append(f"\n  {label}")
            order_findings.extend(f"    {line}" for line in orders)
        if not values and not orders:
            clean += 1

    if not args.quiet:
        print(f"Compared {compared} snapshot(s): {clean} identical.")

    if value_findings:
        print("\nVALUE DIFFERENCES (investigate every one):")
        for line in value_findings:
            print(line)

    if order_findings:
        print("\nKEY ORDER ONLY (same keys and values, different order):")
        for line in order_findings:
            print(line)
        if not args.strict_order:
            print(
                "\n  Expected if you chose definition order. If you meant to preserve V1's order,"
                "\n  add the FieldOrder extension to the base Blueprint and re-run with --strict-order."
            )

    if not value_findings and not order_findings:
        print("No differences.")

    failed = bool(value_findings) or (args.strict_order and bool(order_findings))
    return 1 if failed else 0


if __name__ == "__main__":
    sys.exit(main())
