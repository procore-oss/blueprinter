---
description: Basic information about Blueprinter
user-invocable: false
---

* Blueprinter is a Ruby gem for serializing objects to JSON or Hashes.
* Blueprints are Ruby classes that inherit from a base class and implement the Blueprinter DSL.
* Blueprints are usually implemented as class literals, but some may use `Class.new` with a block.
* A Blueprint may contain multiple "views", which inherit fields from the parent context.
* Each Blueprint has an implicit `default` view at the top level of the class.
* V2 of the DSL has several breaking changes.
