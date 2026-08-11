import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Full-screen gradient mesh backdrop. Wrap a Scaffold's body (with a
/// transparent Scaffold background) so glass cards have something to float over.
class GradientBackground extends StatelessWidget {
  const GradientBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        gradient: isDark
            ? const RadialGradient(
                center: Alignment(-0.7, -0.9),
                radius: 1.6,
                colors: [AppColors.darkMid, AppColors.darkBase, Colors.black],
                stops: [0.0, 0.55, 1.0],
              )
            : const RadialGradient(
                center: Alignment(-0.7, -0.9),
                radius: 1.6,
                colors: [
                  AppColors.lightMid,
                  AppColors.lightBase,
                  AppColors.lightBase,
                ],
                stops: [0.0, 0.55, 1.0],
              ),
      ),
      child: child,
    );
  }
}
