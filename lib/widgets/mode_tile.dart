import 'package:flutter/material.dart';

import 'glass_card.dart';

/// Tappable icon+label tile used for 3-way mode grids (Video Mode, Night
/// Mode, etc.). Highlights with a primary-color border/fill when selected.
class ModeTile extends StatelessWidget {
  const ModeTile({
    super.key,
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return GlassCard(
      padding: EdgeInsets.zero,
      borderRadius: 16,
      child: Material(
        color: selected
            ? colorScheme.primary.withValues(alpha: 0.18)
            : Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: selected
                    ? colorScheme.primary
                    : colorScheme.outlineVariant.withValues(alpha: 0.4),
                width: selected ? 2 : 1,
              ),
            ),
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: 28,
                  color: selected
                      ? colorScheme.primary
                      : colorScheme.onSurfaceVariant,
                ),
                const SizedBox(height: 8),
                Text(
                  label,
                  style: TextStyle(
                    fontFamily: 'Manrope',
                    fontWeight: FontWeight.w600,
                    color: selected ? colorScheme.primary : null,
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
