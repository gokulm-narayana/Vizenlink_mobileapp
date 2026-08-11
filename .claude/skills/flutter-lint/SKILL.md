---
name: flutter-lint
description: Run static analysis and formatting checks on mobilecctvapp (flutter analyze + dart format). Use as a quality gate before considering any Dart/Flutter code change complete.
---

# flutter-lint

Quality gate for Dart/Flutter changes. Run after any edit to files under `lib/` or `test/`.

## Steps

1. Format check (auto-fixes in place):
   ```
   dart format lib test
   ```
2. Static analysis:
   ```
   flutter analyze
   ```
3. Fix any reported issues before proceeding. `flutter analyze` uses the rules in `analysis_options.yaml` (`flutter_lints` package) — don't weaken or suppress rules to silence warnings; fix the underlying code instead.
4. If tests exist, also run:
   ```
   flutter test
   ```

## Notes

- Zero warnings/errors from `flutter analyze` is the bar — treat any output as blocking, not advisory.
- Don't add `// ignore:` comments to suppress lints unless the user explicitly asks for it.
