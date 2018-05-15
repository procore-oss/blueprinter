## 0.5.0  - 2018/05/15

* [FEATURE] Add `default` option to `association` which will be used as the serialized value instead of `null` when the association evaluates to null.
See PR #78 by @vinaya-procore.

## 0.4.0  - 2018/05/02

* [FEATURE] Add `render_as_hash` which will output a hash instead of
a JSON String. See PR #76 by @amayer171 and Issue #73.

## 0.3.0  - 2018/04/05

Sort of a breaking Change. Serializer classes has been renamed to Extractor. To upgrade, if you passed in a specific serializer to `field` or `identifier` such as:

```
field(:first_name, serializer: CustomSerializer)
```

Please rename that to:

```
field(:first_name, extractor: CustomExtractor)
```

* [ENHANCEMENT] Renamed Serializer classes to Extractor. See #72.
* [ENHANCEMENT] Updated README. See #66, #65

## 0.2.0  - 2018/01/22

Breaking Changes. To upgrade, ensure that any associated objects have a blueprint. For example:
```
association :comments, blueprint: CommentsBlueprint
```

* [BUGFIX] Remove Optimizer class. See #61.
* [BUGFIX] Require associated objects to have a Blueprint, so that objects will always serialize properly. See #60.

## 0.1.0  - 2018/01/17

* [FEATURE] Initial release of Blueprinter
