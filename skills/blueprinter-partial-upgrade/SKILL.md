---
description: Upgrade select Blueprints to V2
arguments: [$dir]
disable-model-invocation: true
allowed-tools: Read Grep
skills:
  - blueprinter-v2-basics
  - blueprinter-v2-breaking-changes
---

1. Find each Blueprint class Ruby file in ${dir}.
2. Does it ultimately inherit from Blueprinter V2's base class? If so, skip.
3. Trace inheritance back to V1's base class, creating V2-compatible copies for each. (The "root" V2 base class, e.g. `ApplicationBlueprintV2`, should follow V2 Base Blueprint Suggested Layout.)
4. Change the Blueprint's parent class to the V2-compatible copy.
5. Update the Blueprint's body to V2, applying best practices for V2.
