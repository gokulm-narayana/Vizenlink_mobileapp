---
paths:
  - "lib/**"
  - "packages/camera_api/**"
  - "android/**"
  - "ios/**"
---

# Mobile App (Flutter) Rules

Repo-wide build/branding/lint/SDK conventions for this Flutter project (there is no separate
`mobile_app/` subfolder here — `lib/` at the repo root *is* the app). For how screens should call
`camera_api` clients (LAN/WAN transport selection, Options caching) and present state to the user
(settings-screen Apply/Reset/Reload, call-style session screens, password fields), see
[mobile-app-screen-conventions.md](mobile-app-screen-conventions.md). Root `CLAUDE.md` has the
project-wide screen-docs/design-ID and client-code-integration rules, which still apply here too.

## Brand text consistency

Every visible UI string that names the product (app label/display name, splash screen, about
screen, login/onboarding copy, etc.) should say **"VizenLink"** exactly (capital V, capital L),
sourced from one place, not hardcoded independently per platform or per screen.

**Not yet applied in this repo** — `android/app/src/main/AndroidManifest.xml`'s `android:label`
and `ios/Runner/Info.plist`'s `CFBundleDisplayName`/`CFBundleName` still read `mobilecctvapp`/
`Mobilecctvapp` (the `flutter create` defaults). Confirm with the user before renaming — this is
a product-facing decision, not a lint fix. If/when it happens:

- Define the brand string once as a Dart constant (e.g. `lib/theme/branding.dart`, alongside the
  existing `lib/theme/` files) and reference it from any in-app UI text — never repeat the
  literal string across multiple `.dart` files.
- The two native manifests can't reference that Dart constant directly (they're read before the
  Dart VM starts) — treat them as a manual sync checklist: `AndroidManifest.xml`'s
  `android:label` and `Info.plist`'s `CFBundleDisplayName`. Double-check the exact capitalization
  on both after editing — `flutter create --project-name` style renames have produced
  inconsistent casing between the two platforms before (all-lowercase on Android, wrong-case on
  iOS) when done via the scaffolding tool instead of by hand.

## Scaffold/regeneration hygiene

If `flutter create` is ever re-run against this project (regen, plugin add, template refresh),
check for two things before considering it done:

1. **Unwanted platform folders reappear.** If a Flutter install has desktop/web feature flags
   enabled globally, `flutter create` will scaffold `linux/`, `macos/`, `windows/`, `web/`
   whether or not they're wanted. This repo currently has all of `android/`, `ios/`, `macos/`,
   `linux/`, `windows/`, `web/` present — confirm with the user which platforms are actually
   targeted before deleting any of them; don't assume Android+iOS-only without asking.
2. **Brand text reverts to Flutter/package-name defaults** in the two native manifests (see
   above) — re-check both after any regeneration.

## Android SDK versions

**Not yet explicitly decided in this repo** — `android/app/build.gradle.kts` currently uses
Flutter's own defaults (`flutter.minSdkVersion` / `flutter.targetSdkVersion` /
`flutter.compileSdkVersion`), not hardcoded values. Confirm minimum/target/compile SDK versions
with the user before hardcoding them in `build.gradle.kts`. If they do get pinned, re-verify
`targetSdk` against current Google Play policy at that time (Play periodically raises the
mandatory minimum target API for new releases/updates) rather than assuming last year's number
still clears the bar.

## Secrets and credentials

Never hardcode AWS Cognito config, API keys, or camera credentials/tokens in Dart source or
commit them to this repo. Use `--dart-define` (build-time) or a gitignored config file for
environment-specific values. Never log camera credentials or auth tokens in debug builds.

## Implementing/changing `camera_api` clients — verify against its own test suite

`packages/camera_api` has its own mock-based Dart test suite (`packages/camera_api/test/*.dart`)
covering wire format for both LAN (ONVIF/NuraEye) and WAN (AWS IoT) clients — e.g.
`onvif_imaging_client_test.dart`, `mask_client_test.dart`, `nuraeye_digest_test.dart`,
`iot_command_client_test.dart`. When adding or changing a client, add/update the matching test
file rather than relying on manual verification against a real camera, and run
`cd packages/camera_api && flutter test` before considering the change done. For which client
class or capability flag governs a given camera setting, check `SETTINGS_API_GUIDE.md` before
`API_REFERENCE.md` — the reference doc is organized by client class, not by setting name.
