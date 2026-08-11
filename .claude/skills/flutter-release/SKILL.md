---
name: flutter-release
description: Produce release build artifacts for mobilecctvapp (Android APK/AAB, iOS IPA). Use when the user asks to build a release, produce an installable artifact, or prepare for distribution/store submission — not for everyday development runs.
---

# flutter-release

Build distributable artifacts. This is a heavier, less frequent operation than `flutter-run` — confirm with the user which platform(s) they need before running, since iOS builds require a configured signing team.

## Android

```
flutter build apk --release        # single APK for direct install/testing
flutter build appbundle --release  # AAB for Play Store submission
```
Output: `build/app/outputs/flutter-apk/app-release.apk` or `build/app/outputs/bundle/release/app-release.aab`.

## iOS

```
flutter build ipa --release
```
Requires a valid Apple Developer signing team configured in Xcode (`ios/Runner.xcworkspace`). If signing isn't set up, this will fail — don't attempt to bypass signing; ask the user to configure it in Xcode first.
Output: `build/ios/ipa/`.

## Before releasing

- Run the `flutter-lint` skill and ensure it's clean.
- Confirm the version/build number in `pubspec.yaml` (`version: x.y.z+build`) has been bumped if this is a new release, per the user's instruction — don't bump it unprompted.

## Notes

- Release builds are slower and produce artifacts meant for distribution — never run this as a substitute for `flutter-run` during normal development iteration.
- Signing credentials and store submission (App Store Connect / Play Console upload) are outside this skill's scope — that always requires explicit user action/confirmation.
