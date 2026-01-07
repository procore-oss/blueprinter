# Extensions

The [V2 Extension API](../api/extensions.md), as well as the DSL for [enabling V2 extensions](../dsl/extensions.md), are vastly different and more powerful than V1. Legacy/V1 had only one extension hook: `pre_render`. V2 [has eight](../api/extensions.md#hooks).

## Porting pre_render

Legacy/V1's `pre_render` hook does not exist in V2, but it has several possible replacements:

* [around_result](../api/extensions.md#around_result) runs once around each entire result
* [around_serialize_object](../api/extensions.md#around_serialize_object) runs around each object's serialization
* [around_serialize_collection](../api/extensions.md#around_serialize_collection) runs around each collection's serialization
* [around_blueprint](../api/extensions.md#around_blueprint) runs each time a blueprint serializes an object
