import 'package:auth_api/auth_api.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../theme/app_colors.dart';
import '../dashboard/dashboard_screen.dart';
import '../login/login_screen.dart';

/// In-app splash shown until the app has finished loading, replacing the
/// native Android launch splash (removed — see `pubspec.yaml`'s
/// `flutter_native_splash: android: false`; Android's native Splash Screen
/// API only supports a centered icon on a solid color, so it couldn't render
/// the full VizenLink wordmark anyway). Stays up for exactly as long as
/// [appReady] takes to complete — which includes [AuthController.restore]
/// — then routes to the dashboard or the login screen depending on whether
/// a session was restored. No arbitrary fixed delay.
class SplashScreen extends StatefulWidget {
  const SplashScreen({
    super.key,
    required this.appReady,
    required this.authController,
  });

  static const routeName = '/splash';

  /// Resolves once app-level startup work (theme preference, AI consent
  /// state, auth session restore, etc. — see `_MobileCctvAppState.initState`)
  /// has finished.
  final Future<void> appReady;

  final AuthController authController;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    widget.appReady.then((_) {
      if (!mounted) return;
      final destination =
          widget.authController.status == AuthStatus.authenticated
          ? DashboardScreen.routeName
          : LoginScreen.routeName;
      context.go(destination);
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
