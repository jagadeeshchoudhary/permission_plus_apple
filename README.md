# permission_plus_apple

The Apple (iOS & macOS) implementation of [`permission_plus`](https://github.com/jagadeeshchoudhary/permission_plus).

## Usage

This package is [endorsed](https://dart.dev/tools/pub/dependencies#endorsed-packages) and will be automatically included when you depend on `permission_plus`. There is no need to add this package to your `pubspec.yaml` directly.

**Users should depend on [`permission_plus`](https://pub.dev/packages/permission_plus) instead of this package.**

## Implementation Details

- Written in **Swift** using **Swift Package Manager** (no CocoaPods dependency).
- Uses **shared darwin source** for both iOS and macOS from a single codebase.

## Supported Permissions

| Permission      | iOS | macOS |
|-----------------|-----|-------|
| Camera          | ✅  | ✅    |
| Microphone      | ✅  | ✅    |
| Photos          | ✅  | ✅    |
| Location        | ✅  | ✅    |
| Notifications   | ✅  | ✅    |
| Contacts        | ✅  | ✅    |
| Calendar        | ✅  | ✅    |
| Reminders       | ✅  | ✅    |
| Bluetooth       | ✅  | ✅    |

## Issues

Please file any issues or feature requests at the [issue tracker](https://github.com/jagadeeshchoudhary/permission_plus_apple/issues).
