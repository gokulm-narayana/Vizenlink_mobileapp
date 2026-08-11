import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Extended floating action button filled with a solid cyan background —
/// the app's brightest accent, used here (unlike the toned-down indigo tint
/// elsewhere) since this is the Dashboard's single most important action.
/// Collapses to an icon-only circle when [expanded] is false (e.g. while
/// the user is scrolling down through an already-populated camera list),
/// so it takes up less space once it's no longer the most useful action on
/// screen — still one tap away, never fully hidden.
class GradientFab extends StatelessWidget {
  const GradientFab({
    super.key,
    required this.onPressed,
    required this.icon,
    required this.label,
    this.expanded = true,
  });

  final VoidCallback onPressed;
  final Widget icon;
  final Widget label;
  final bool expanded;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      decoration: BoxDecoration(
        color: AppColors.cyan,
        borderRadius: BorderRadius.circular(expanded ? 16 : 28),
        boxShadow: [
          BoxShadow(
            color: AppColors.cyan.withValues(alpha: 0.45),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(expanded ? 16 : 28),
          onTap: onPressed,
          child: AnimatedPadding(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            padding: expanded
                ? const EdgeInsets.symmetric(horizontal: 20, vertical: 16)
                : const EdgeInsets.all(16),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconTheme(
                  data: const IconThemeData(color: AppColors.darkBase),
                  child: icon,
                ),
                AnimatedSize(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOut,
                  child: expanded
                      ? Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const SizedBox(width: 8),
                            DefaultTextStyle(
                              style: const TextStyle(
                                fontFamily: 'Manrope',
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: AppColors.darkBase,
                              ),
                              child: label,
                            ),
                          ],
                        )
                      : const SizedBox(width: 0),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
