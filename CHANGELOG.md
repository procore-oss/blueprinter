## 0.15.0  - 2019/04/1
* 🚀 [FEATURE] Add ability to pass in `datetime_format` field option as either a string representing the strftime format, or a Proc which takes in the Date or DateTime object and returns the formatted date. [#145](https://github.com/procore/blueprinter/pull/145). Thanks to [@mcclayton](https://github.com/mcclayton).

## 0.14.0  - 2019/04/01
* 🚀 [FEATURE] Added a global `datetime_format` option. [#135](https://github.com/procore/blueprinter/pull/143). Thanks to [@ritikesh](https://github.com/ritikesh).

## 0.13.2  - 2019/03/14
* 🐛 [BUGFIX] Replacing use of rails-specific method `Hash::except` so that Blueprinter continues to work in non-Rails environments. [#140](https://github.com/procore/blueprinter/pull/140). Thanks to [@checkbutton](https://github.com/checkbutton).

## 0.13.1  - 2019/03/02
* 💅 [MAINTENANCE | ENHANCEMENT] Cleaning up the `include_associations` section. This is not a documented/supported feature and is calling `respond_to?(:klass)` on every object passed to blueprinter. [#139](https://github.com/procore/blueprinter/pull/139). Thanks to [@ritikesh](https://github.com/ritikesh).

## 0.13.0  - 2019/02/07

* 🚀 [FEATURE] Added an option to render with a root key. [#135](https://github.com/procore/blueprinter/pull/135). Thanks to [@ritikesh](https://github.com/ritikesh).
* 🚀 [FEATURE] Added an option to render with a top-level meta attribute. [#135](https://github.com/procore/blueprinter/pull/135). Thanks to [@ritikesh](https://github.com/ritikesh).

## 0.12.1  - 2019/1/24

* 🐛 [BUGFIX] Fix boolean `false` values getting serialized as `null`. Please see PR [#132](https://github.com/procore/blueprinter/pull/132).

## 0.12.0  - 2019/1/16

* 🚀 [FEATURE] Enables the setting of global `:field_default` and `:association_default` option value in the Blueprinter Configuration that will be used as default values for fields and associations that evaluate to nil. [#128](https://github.com/procore/blueprinter/pull/128). Thanks to [@mcclayton](https://github.com/mcclayton).

## 0.11.0  - 2019/1/15

* 🚀 [FEATURE] Enables the setting of a global `:if`/`:unless` proc in the Blueprinter Configuration that will be used to evaluate the conditional render of all fields. [#127](https://github.com/procore/blueprinter/pull/127). Thanks to [@mcclayton](https://github.com/mcclayton).

## 0.10.0  - 2018/12/20

* 🚀 [FEATURE] Association Blueprints can be dynamically evaluated using a proc. [#122](https://github.com/procore/blueprinter/pull/122). Thanks to [@ritikesh](https://github.com/ritikesh).

## 0.9.0  - 2018/11/29

* 🚀 [FEATURE] Added a `render_as_json` API. Similar to `render_as_hash` but returns a JSONified hash. Please see pr [#119](https://github.com/procore/blueprinter/pull/119). Thanks to [@ritikesh](https://github.com/ritikesh).
* 🚀 [FEATURE] Sorting of fields in the response is now configurable to sort by definition or by name(asc only). Please see pr [#119](https://github.com/procore/blueprinter/pull/119). Thanks to [@ritikesh](https://github.com/ritikesh).
* 💅 [ENHANCEMENT] Updated readme for above features and some existing undocumented features like `exclude fields`, `render_as_hash`. Please see pr [#119](https://github.com/procore/blueprinter/pull/119). Thanks to [@ritikesh](https://github.com/ritikesh).

## 0.8.0  - 2018/11/19

* 🚀 [FEATURE] Extend Support for other JSON encoders like yajl-ruby. Please see pr [#118](https://github.com/procore/blueprinter/pull/118). Thanks to [@ritikesh](https://github.com/ritikesh).
* 🐛 [BUGFIX] Do not raise error on null date with `date_format` option. Please see pr [#117](https://github.com/procore/blueprinter/pull/117). Thanks to [@tpltn](https://github.com/tpltn).
* 🚀 [FEATURE] Add `default` option to `field`s which will be used as the serialized value instead of `null` when the field evaluates to null. Please see pr [#115](https://github.com/procore/blueprinter/pull/115). Thanks to [@mcclayton](https://github.com/mcclayton).
* 🐛 [BUGFIX] Made Base.associations completely private since they are not used outside of the Blueprinter base. Please see pr [#112](https://github.com/procore/blueprinter/pull/112). Thanks to [@philipqnguyen](https://github.com/philipqnguyen).
* 🐛 [BUGFIX] Fix issue where entire Blueprinter module was marked api private. Please see pr [#111](https://github.com/procore/blueprinter/pull/111). Thanks to [@philipqnguyen](https://github.com/philipqnguyen).
* 🚀 [FEATURE] Allow identifiers to be defined with a block. Please see pr [#110](https://github.com/procore/blueprinter/pull/110). Thanks to [@hugopeixoto](https://github.com/hugopeixoto).
* 💅 [ENHANCEMENT] Update docs regarding the args yielded to blocks. Please see pr [#108](https://github.com/procore/blueprinter/pull/108). Thanks to [@philipqnguyen](https://github.com/philipqnguyen).
* 💅 [ENHANCEMENT] Use `field` method in fields. Please see pr [#107](https://github.com/procore/blueprinter/pull/107). Thanks to [@hugopeixoto](https://github.com/hugopeixoto).

## 0.7.0  - 2018/10/17

* [FEATURE] Allow associations to be defined with a block. Please see pr [#106](https://github.com/procore/blueprinter/pull/106). Thanks to [@hugopeixoto](https://github.com/hugopeixoto).
* [FEATURE] Inherit view definition when using inheritance. Please see pr [#105](https://github.com/procore/blueprinter/pull/105). Thanks to [@hugopeixoto](https://github.com/hugopeixoto).

## 0.6.0  - 2018/06/05

* 🚀 [FEATURE] Add `date_time` format as an option to `field`. Please see pr #68. Thanks to [@njbbaer](https://github.com/njbbaer).
* 🚀 [FEATURE] Add conditional field support `:unless` and `:if` as an option to `field`. Please see pr [#86](https://github.com/procore/blueprinter/pull/86). Thanks to [@ojab](https://github.com/ojab).
* 🐛 [BUGFIX] Fix case where miscellaneous options were not being passed through the `AutoExtractor`. See pr [#83](https://github.com/procore/blueprinter/pull/83).

## 0.5.0  - 2018/05/15

* 🚀 [FEATURE] Add `default` option to `association` which will be used as the serialized value instead of `null` when the association evaluates to null.
See PR [#78](https://github.com/procore/blueprinter/pull/78) by [@vinaya-procore](https://github.com/vinaya-procore).

## 0.4.0  - 2018/05/02

* 🚀 [FEATURE] Add `render_as_hash` which will output a hash instead of
a JSON String. See PR [#76](https://github.com/procore/blueprinter/pull/76) by [@amayer171](https://github.com/amayer171) and Issue [#73](https://github.com/procore/blueprinter/issues/73).

## 0.3.0  - 2018/04/05

💥 [BREAKING] Sort of a breaking Change. Serializer classes has been renamed to Extractor. To upgrade, if you passed in a specific serializer to `field` or `identifier` such as:

```
field(:first_name, serializer: CustomSerializer)
```

Please rename that to:

```
field(:first_name, extractor: CustomExtractor)
```

* 💅 [ENHANCEMENT] Renamed Serializer classes to Extractor. See #72.
* 💅 [ENHANCEMENT] Updated README. See pr [#66](https://github.com/procore/blueprinter/pull/66), [#65](https://github.com/procore/blueprinter/pull/65)

## 0.2.0  - 2018/01/22

💥 [BREAKING] Breaking Changes. To upgrade, ensure that any associated objects have a blueprint. For example:
```
association :comments, blueprint: CommentsBlueprint
```

* 🐛 [BUGFIX] Remove Optimizer class. See [#61](https://github.com/procore/blueprinter/pull/61).
* 🐛 [BUGFIX] Require associated objects to have a Blueprint, so that objects will always serialize properly. See [#60](https://github.com/procore/blueprinter/pull/60).

## 0.1.0  - 2018/01/17

* 🚀 [FEATURE] Initial release of Blueprinter
