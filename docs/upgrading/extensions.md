# Extensions

The [V2 Extension API](../api/extensions.md), as well as the DSL for [enabling V2 extensions](../dsl/extensions.md), are vastly different and more powerful than V1. Legacy/V1 had only one extension hook: `pre_render`. V2 has [over a dozen](../api/extensions.md#hooks).

## Porting pre_render

Legacy/V1's `pre_render` hook does not exist in V2, but it has three possible replacements:

* [object_input](../api/extensions.md#object_input) intercept an object before it's serialized
* [collection_input](../api/extensions.md#collection_input) intercept a collection before it's serialized
* [blueprint_input](../api/extensions.md#blueprint_input) runs each time a blueprint serializes an object
