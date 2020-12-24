## 0.25.3 - 2020/12/25
💅 [ENHANCEMENT] Add `frozen_string_literal: true` pragma to all files. [251](https://github.com/procore/blueprinter/pull/251). Thanks to [@ritikesh](https://github.com/ritikesh).

## 0.25.2  - 2020/11/19
* 🚀 [FEATURE] Make deprecation behavior configurable (`:silence`, `:stderror`, `:raise`). See [#248](https://github.com/procore/blueprinter/pull/248) thanks to [@mcclayton](https://github.com/mcclayton)

## 0.25.1  - 2020/8/18
* 🐛 [BUGFIX] Raise Blueprinter::BlueprinterError if Blueprint given is not of class Blueprinter::Base. Before it just raised a generic `undefined method 'prepare'`. See [#233](https://github.com/procore/blueprinter/pull/233) thanks to [@caws](https://github.com/caws)

## 0.25.0  - 2020/7/06
* 🚀 [FEATURE] Enable default `Blueprinter::Transformer`s to be set in the global configuration. [#222](https://github.com/procore/blueprinter/pull/222). Thanks to [@supremebeing7](https://github.com/supremebeing7).

## 0.24.0  - 2020/6/22
* 🚀 [FEATURE] Add an `options` option to associations to facilitate passing options from one blueprint to another. [#220](https://github.com/procore/blueprinter/pull/220). Thanks to [@mcclayton](https://github.com/mcclayton).

## 0.23.4  - 2020/4/28
* 🚀 [FEATURE] Public class method `has_view?` on Blueprinter::Base subclasses introduced in [#213](https://github.com/procore/blueprinter/pull/213). Thanks to [@spencerneste](https://github.com/spencerneste).

## 0.23.3  - 2020/4/7
* 🐛 [BUGFIX] Fixes issue where `exclude` fields in deeply nested views were not respected. Resolved issue [207](https://github.com/procore/blueprinter/issues/207) in [#208](https://github.com/procore/blueprinter/pull/208) by [@tpltn](https://github.com/tpltn).

## 0.23.2  - 2020/3/16
* 🐛 [BUGFIX] Fixes issue where fields "bled" into other views due to merge side-effects. Resolved issue [205](https://github.com/procore/blueprinter/issues/205) in [#204](https://github.com/procore/blueprinter/pull/204) by [@trevorrjohn](https://github.com/trevorrjohn).

## 0.23.1  - 2020/3/13
* 🐛 [BUGFIX] Fixes #172 where views would unintentionally ignore `sort_fields_by: :definition` configuration. Resolved in [#197](https://github.com/procore/blueprinter/pull/197) by [@wlkrw](https://github.com/wlkrw).

## 0.23.0  - 2020/1/31
* 🚀 [FEATURE] Configurable default extractor introduced in [#198](https://github.com/procore/blueprinter/pull/198) by [@wlkrw](https://github.com/wlkrw). You can now set a default extractor like so:
```
Blueprinter.configure do |config|
  config.extractor_default = MyAutoExtractor
end
```

## 0.22.0  - 2019/12/26
* 🚀 [FEATURE] Add rails generators. See `rails g blueprinter:blueprint --help` for usage. Introduced in [#176](https://github.com/procore/blueprinter/pull/176) by [@wlkrw](https://github.com/wlkrw).

## 0.21.0  - 2019/12/19
* 🚀 [FEATURE] Ability to specify `default_if` field/association option for more control on when the default value is applied. [191](https://github.com/procore/blueprinter/pull/191). Thanks to [@mcclayton](https://github.com/mcclayton).

## 0.20.0  - 2019/10/15
* 🚀 [FEATURE] Ability to include multiple views in a single method call with `include_views`. [184](https://github.com/procore/blueprinter/pull/184). Thanks to [@narendranvelmurugan](https://github.com/narendranvelmurugan).

* 💅 [ENHANCEMENT] Update field-level conditional settings to reflect new three-argument syntax. [183](https://github.com/procore/blueprinter/pull/183). Thanks to [@danirod](https://github.com/danirod).

* 💅 [ENHANCEMENT] Modify Extractor access control in documentation. [182](https://github.com/procore/blueprinter/pull/182). Thanks to [@cagmz](https://github.com/cagmz).

* 💅 [ENHANCEMENT] Fix the Transformer example documentation. [174](https://github.com/procore/blueprinter/pull/174). Thanks to [@tjwallace](https://github.com/tjwallace).

## 0.19.0  - 2019/07/24
* 🚀 [FEATURE] Added ability to specify transformers for Blueprinter views to further process the resulting hash before serialization. [#164](https://github.com/procore/blueprinter/pull/164). Thanks to [@amalarayfreshworks](https://github.com/amalarayfreshworks).

## 0.18.0  - 2019/05/29

* ⚠️ [DEPRECATION] :if/:unless procs with two arguments are now deprecated. *These procs now take in three arguments (field_name, obj, options) instead of just (obj, options).*
  In order to be compliant with the the next major release, all conditional :if/:unless procs must be augmented to take in three arguments instead of two. i.e. `(obj, options)` to `(field_name, obj, options)`.

## 0.17.0  - 2019/05/23
* 🐛 [BUGFIX] Fixing view: :identifier including non-identifier fields. [#154](https://github.com/procore/blueprinter/pull/154). Thanks to [@AllPurposeName](https://github.com/AllPurposeName).

* 💅 [ENHANCEMENT] Add ability to override :extractor option for an ::association. [#152](https://github.com/procore/blueprinter/pull/152). Thanks to [@hugopeixoto](https://github.com/hugopeixoto).

## 0.16.0  - 2019/04/03
* 🚀 [FEATURE] Add ability to exclude multiple fields inline using `excludes`. [#141](https://github.com/procore/blueprinter/pull/141). Thanks to [@pabhinaya](https://github.com/pabhinaya).

## 0.15.0  - 2019/04/01
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

* 🐛 [BUGFIX] Fix boolean `false` values getting serialized as `null`. Please see PR [#132](https://github.com/procore/blueprinter/pull/132). Thanks to [@samsongz](https://github.com/samsongz).

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
