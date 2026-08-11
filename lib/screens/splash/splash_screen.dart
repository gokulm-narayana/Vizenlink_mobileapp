import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../theme/app_colors.dart';
import '../dashboard/dashboard_screen.dart';

/// In-app splash shown until the app has finished loading, replacing the
/// native Android launch splash (removed — see `pubspec.yaml`'s
/// `flutter_native_splash: android: false`; Android's native Splash Screen
/// API only supports a centered icon on a solid color, so it couldn't render
/// the full VizenLink wordmark anyway). Stays up for exactly as long as
/// [appReady] takes to complete, then hands off to the dashboard — no
/// arbitrary fixed delay.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key, required this.appReady});

  static const routeName = '/splash';

  /// Resolves once app-level startup work (theme preference, AI consent
  /// state, etc. — see `_MobileCctvAppState.initState`) has finished.
  final Future<void> appReady;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    widget.appReady.then((_) {
      if (mounted) context.go(DashboardScreen.routeName);
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      key: const Key('SPLASH-001'),
      backgroundColor: isDark ? AppColors.darkBase : AppColors.lightBase,
      body: Center(
        child: Image.asset(
          key: const Key('SPLASH-002'),
          isDark
              ? 'assets/branding/vizenlink_dark.png'
              : 'assets/branding/vizenlink_light.png',
          width: 320,
        ),
      ),
    );
  }
}
