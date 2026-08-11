import 'package:flutter/material.dart';

import '../../widgets/glass_card.dart';

/// Shows a small centered popup with a spinner for the duration of the
/// simulated scan, then dismisses itself. Callers await this before
/// navigating to the results page.
Future<void> showScanningPopup(BuildContext context) async {
  final dialogFuture = showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) {
      return Center(
        child: GlassCard(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 28),
          child: Column(
            key: const Key('SCAN-001'),
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(
                'Scanning for cameras…',
                style: Theme.of(dialogContext).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      );
    },
  );

  await Future<void>.delayed(const Duration(seconds: 2));
  if (context.mounted) {
    Navigator.of(context, rootNavigator: true).pop();
  }
  await dialogFuture;
}
