# Compatible Changes

When you migrate a Blueprint to V2, you can enable several bundled extensions to maintain backwards-compatibility with certain features.

NOTE: These extensions don't _replace_ V2's native behavior. Instead, they detect V1-style options and convert them to V2's semantics
using the extension system. This allows you to gradually migrate to fully V2-compliant code at your own pace.
