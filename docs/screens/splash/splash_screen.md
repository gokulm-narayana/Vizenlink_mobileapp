# SplashScreen

- **Dart file:** `lib/screens/splash/splash_screen.dart`
- **Route:** `/splash` (the app's `initialLocation`)
- **Purpose:** In-app splash shown from app launch until startup work finishes, then hands off to the dashboard. This is now the *only* splash — Android's native splash was removed (`pubspec.yaml`'s `flutter_native_splash: android: false`, native files reset via `dart run flutter_native_splash:remove`) because Android 12+'s native Splash Screen API only supports a centered icon on a solid background color and couldn't render the full "VizenLink" wordmark. iOS and web keep their native `flutter_native_splash`-generated splash (shown for the brief native-engine-attach moment before this screen's first frame); Android goes straight to this screen. Uses the same background colors the removed native splash used (`#F4F6FB` light / `#0B1120` dark) so there's no visible color flash where the native/iOS/web splash hands off to this screen.

## Elements

| Design ID | Element | Type | Notes |
|-----------|---------|------|-------|
| SPLASH-001 | Screen background | `Scaffold` | Background color follows `Theme.of(context).brightness` — light/dark, matching the colors the native splash used to use |
| SPLASH-002 | Wordmark image | `Image.asset`, centered | `assets/branding/vizenlink_light.png` (dark text) in light mode, `assets/branding/vizenlink_dark.png` (white text) in dark mode |

## Navigation

Registered as the router's `initialLocation` in `main.dart` (replacing the previous `DashboardScreen.routeName`). Takes an `appReady` constructor param — `Future<void>` built in `_MobileCctvAppState.initState()` as `Future.wait([_themeController.load(), _aiModelManager.load(), Future.delayed(_splashMinDuration)])` (app-level startup work: theme preference, AI chat consent state; `_splashMinDuration` is currently 15 seconds, for testing/review — turn it back down before shipping). Once `appReady` resolves, calls `context.go(DashboardScreen.routeName)` if still mounted.

`_splashMinDuration` exists because real startup work (a couple of `SharedPreferences` reads) usually finishes in a few milliseconds on a real device — without a floor, the splash would resolve and navigate away before it was ever visible. It's a floor, not a fixed delay: if real loading ever takes longer than that, the splash waits for that instead.

## Design notes

- Android's native splash is fully removed (not just skipped) — `android: false` in `pubspec.yaml`'s `flutter_native_splash` config, plus a `flutter_native_splash:remove` pass to restore `android/app/src/main/res/{values,values-v31,values-night,values-night-v31}/styles.xml` and the `drawable*/launch_background.xml` files to Flutter's stock defaults (no image, no `windowSplashScreenAnimatedIcon`). Re-running `dart run flutter_native_splash:create` after this only touches iOS/web, since `android: false` makes it skip that platform — Android's default files are left alone.
- Flutter's stock default `android:windowBackground` is a plain white 1×1 drawable (`drawable*/background.png`), which flashes visibly for the brief moment between process launch and Flutter's first frame now that there's no native splash to fill that gap. Fixed by pointing `LaunchTheme.windowBackground` (in `values/styles.xml` and `values-night/styles.xml`) at a solid color instead — `values/colors.xml`'s `launch_background_color` (`#F4F6FB`, matching this screen's light mode) and `values-night/colors.xml`'s (`#0B1120`, matching dark mode) — so the native window blends straight into this screen instead of flashing white first.
- If `pubspec.yaml`'s `flutter_native_splash` config needs regenerating again in the future (e.g. after changing the wordmark images), temporarily remove the `android: false` line before running `flutter_native_splash:remove`/`:create` only if Android's native splash needs to be touched again — otherwise leave it in place so Android stays on its default (this screen is what actually brands the launch there).
- Test notes (`test/widget_test.dart`, "Dashboard is the initial route"):
  - `SharedPreferences.getInstance()` (called by both `ThemeController.load()` and `AiModelManager.load()`, which `appReady` waits on) never resolves in a test environment without a mocked store — it just hangs silently, no exception, and `pumpAndSettle()` reports "settled" without ever reaching the dashboard. Fixed with `SharedPreferences.setMockInitialValues({})` once at the top of `main()`.
  - `pumpAndSettle()` alone also doesn't reliably advance past the `_splashMinDuration` `Future.delayed` timer — an explicit `tester.pump(const Duration(seconds: 15))` before `pumpAndSettle()` is needed.
