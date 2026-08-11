import 'package:flutter/material.dart';

import 'glass_card.dart';

/// Full-screen blocking overlay shown while a camera-settings Save (or
/// similar in-flight action, e.g. connecting to Wi-Fi) is in progress: dims
/// and intercepts all touches on [child], with a centered glass card
/// showing a spinner and [label].
class SavingOverlay extends StatelessWidget {
  const SavingOverlay({
    super.key,
    required this.isSaving,
    required this.child,
    this.label = 'Saving…',
  });

  final bool isSaving;
  final Widget child;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        if (isSaving)
          Positioned.fill(
            child: ColoredBox(
              color: Colors.black.withValues(alpha: 0.45),
              child: Center(
                child: GlassCard(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircularProgressIndicator(),
                      const SizedBox(height: 16),
                      Text(
                        label,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
