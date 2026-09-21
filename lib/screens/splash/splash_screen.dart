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

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final _entranceController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 400),
  );
  late final _entranceOpacity = CurvedAnimation(
    parent: _entranceController,
    curve: Curves.easeOut,
  );
  late final _entranceScale = Tween<double>(begin: 0.9, end: 1.0).animate(
    CurvedAnimation(parent: _entranceController, curve: Curves.easeOut),
  );

  @override
  void initState() {
    super.initState();
    _entranceController.forward();
    widget.appReady.then((_) async {
      if (!mounted) return;
      // Fade back out before handing off so the transition isn't an
      // instant cut to the next screen.
      await _entranceController.reverse(from: 1.0).orCancel.catchError((_) {});
      if (!mounted) return;
      final destination =
          widget.authController.status == AuthStatus.authenticated
          ? DashboardScreen.routeName
          : LoginScreen.routeName;
      context.go(destination);
    });
  }

  @override
  void dispose() {
    _entranceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      key: const Key('SPLASH-001'),
      backgroundColor: isDark ? AppColors.darkBase : AppColors.lightBase,
      body: Center(
        child: FadeTransition(
          opacity: _entranceOpacity,
          child: ScaleTransition(
            scale: _entranceScale,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset(
                  key: const Key('SPLASH-002'),
                  isDark
                      ? 'assets/branding/vizenlink_dark.png'
                      : 'assets/branding/vizenlink_light.png',
                  width: 320,
                ),
                const SizedBox(height: 32),
                SizedBox(
                  key: const Key('SPLASH-003'),
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor: AlwaysStoppedAnimation(
                      (isDark ? Colors.white : Colors.black).withValues(
                        alpha: 0.35,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
