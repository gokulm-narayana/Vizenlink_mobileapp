---
name: flutter-run
description: Build and run the mobilecctvapp Flutter app on a connected device, simulator, or desktop/web target. Use when the user asks to run, launch, start, or test the app interactively (not for CI/release builds).
---

# flutter-run

Launch the app for manual testing.

## Steps

1. List available targets:
   ```
   flutter devices
   ```
2. If no mobile simulator is listed and the user wants iOS/Android specifically:
   - iOS: `open -a Simulator` then re-run `flutter devices` once it boots.
   - Android: `flutter emulators` to list, then `flutter emulators --launch <id>`.
3. Run the app on the chosen target:
   ```
   flutter run -d <device-id>
   ```
   Use `-d macos` or `-d chrome` for quick desktop/web checks when no simulator is needed.
4. For a one-shot non-interactive run (e.g. to confirm it builds and launches without attaching), add `--no-resident` or just let it build and then send `q` via stdin to detach.

## Notes

- First run per platform can take a few minutes (CocoaPods / Gradle setup).
- If `flutter run` fails on iOS with a signing error, that's expected without a configured Apple Developer team — desktop (`-d macos`) or web (`-d chrome`) targets don't require signing and are fine for quick UI checks.
- Always run `flutter-lint` before considering a change done, not as part of this skill.
