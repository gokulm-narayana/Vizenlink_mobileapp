import 'package:flutter/material.dart';

import '../../app_state/camera_scan.dart';
import '../../models/scanned_camera.dart';
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

/// Runs a real LAN discovery scan ([scanForCameras]) while showing a
/// centered popup over whatever screen [context] belongs to (the Dashboard,
/// via its "Add camera" entry point) — cancelable via the back gesture/
/// button, which confirms first ("Do you want to stop scanning?", SCAN-014)
/// rather than discarding an in-flight scan silently. If the scan finds
/// nothing, the popup itself shows a "No cameras found" message (SCAN-018)
/// instead of closing straight into an empty results screen.
///
/// Returns the found cameras once the scan completes with at least one
/// result, or `null` if the user confirmed they wanted to stop, or if the
/// scan completed but found nothing. Stopping only makes the *app* treat the
/// scan as over — cancelling the in-flight LAN discovery/probe calls
/// themselves isn't supported by `camera_api` today, so they're left to
/// finish in the background; their eventual result is just discarded.
Future<List<ScannedCamera>?> showDashboardScanningPopup(
  BuildContext context,
) async {
  final scanFuture = scanForCameras();
  var stopped = false;

  await showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) => _DashboardScanPopup(
      scanFuture: scanFuture,
      onStopped: () => stopped = true,
    ),
  );

  return stopped ? null : await scanFuture;
}

/// Content of [showDashboardScanningPopup]'s dialog. A `StatefulWidget`
/// (rather than attaching a `scanFuture` listener straight in the
/// `showDialog` `builder`) so that listener is only ever registered once in
/// [initState] — `builder` itself can run more than once over the dialog's
/// lifetime (e.g. a `MediaQuery`/theme change triggers a rebuild), and
/// re-registering it on every one of those calls popped the navigator once
/// per registration when the scan finished, which — once the first pop had
/// already removed the dialog — popped the underlying page route instead
/// and crashed go_router ("popped the last page off of the stack").
class _DashboardScanPopup extends StatefulWidget {
  const _DashboardScanPopup({
    required this.scanFuture,
    required this.onStopped,
  });

  final Future<List<ScannedCamera>> scanFuture;
  final VoidCallback onStopped;

  @override
  State<_DashboardScanPopup> createState() => _DashboardScanPopupState();
}

enum _ScanPhase { scanning, notFound }

class _DashboardScanPopupState extends State<_DashboardScanPopup> {
  _ScanPhase _phase = _ScanPhase.scanning;
  bool _closing = false;

  @override
  void initState() {
    super.initState();
    widget.scanFuture.then(
      (results) {
        if (!mounted || _closing) return;
        if (results.isEmpty) {
          widget.onStopped();
          setState(() => _phase = _ScanPhase.notFound);
        } else {
          _closing = true;
          Navigator.of(context, rootNavigator: true).pop();
        }
      },
      onError: (Object _) {
        if (!mounted || _closing) return;
        widget.onStopped();
        setState(() => _phase = _ScanPhase.notFound);
      },
    );
  }

  Future<bool> _confirmStop() async {
    final stop = await showDialog<bool>(
      context: context,
      builder: (confirmContext) => AlertDialog(
        key: const Key('SCAN-014'),
        title: const Text('Stop scanning?'),
        content: const Text(
          'The camera scan is still in progress. Do you want to stop '
          'scanning?',
        ),
        actions: [
          TextButton(
            key: const Key('SCAN-016'),
            onPressed: () => Navigator.of(confirmContext).pop(false),
            child: const Text('Keep scanning'),
          ),
          FilledButton(
            key: const Key('SCAN-015'),
            onPressed: () => Navigator.of(confirmContext).pop(true),
            child: const Text('Stop scanning'),
          ),
        ],
      ),
    );
    return stop ?? false;
  }

  Future<void> _stopAndClose() async {
    if (_closing) return;
    if (!await _confirmStop()) return;
    if (!mounted || _closing) return;
    _closing = true;
    widget.onStopped();
    Navigator.of(context, rootNavigator: true).pop();
  }

  void _close() {
    if (_closing) return;
    _closing = true;
    Navigator.of(context, rootNavigator: true).pop();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _phase == _ScanPhase.notFound,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        await _stopAndClose();
      },
      child: Center(
        child: GlassCard(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 28),
          child: _phase == _ScanPhase.scanning
              ? Column(
                  key: const Key('SCAN-001'),
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(height: 16),
                    Text(
                      'Scanning for cameras…',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                )
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.search_off,
                      size: 32,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      key: const Key('SCAN-018'),
                      'No cameras found on the network.',
                      style: Theme.of(context).textTheme.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    TextButton(
                      key: const Key('SCAN-017'),
                      onPressed: _close,
                      child: const Text('Close'),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
