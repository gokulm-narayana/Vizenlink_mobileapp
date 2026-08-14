/// Single source of truth for the app's brand name, per
/// `.claude/rules/mobile-app.md`. Native manifests (Android, iOS, macOS,
/// web, etc.) can't read this constant since they're evaluated before the
/// Dart VM starts, so they carry their own copy — keep those in sync
/// whenever this changes.
const String kAppBrandName = 'VizenLink';
