## 0.2.0  - 2018/01/22

Breaking Changes. To upgrade, ensure that any associated objects have a blueprint. For example:
```
association :comments, blueprint: CommentsBlueprint
```

* [BUGFIX] Remove Optimizer class. See #61.
* [BUGFIX] Require associated objects to have a Blueprint, so that objects will always serialize properly. See #60.

## 0.1.0  - 2018/01/17

* [FEATURE] Initial release of Blueprinter
