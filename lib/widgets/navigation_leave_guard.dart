import 'package:flutter/material.dart';

/// Registry of the currently-visible screen's "is it OK to leave right now"
/// check, shared by both leave vectors: the back gesture (via [LeaveGuard]'s
/// internal [PopScope]) and a bottom-nav tab tap (via [MainShell] calling
/// [confirmLeave] before switching branches).
class NavigationGuardController extends ChangeNotifier {
  final _guards = <Future<bool> Function()>[];

  void register(Future<bool> Function() onLeaveAttempt) {
    _guards.add(onLeaveAttempt);
  }

  void unregister(Future<bool> Function() onLeaveAttempt) {
    _guards.remove(onLeaveAttempt);
  }

  /// Only the currently visible guarded screen should have a registered
  /// callback at any given time, so the most recently registered one wins.
  Future<bool> confirmLeave() async {
    if (_guards.isEmpty) return true;
    return _guards.last();
  }
}

class NavigationGuardScope
    extends InheritedNotifier<NavigationGuardController> {
  const NavigationGuardScope({
    super.key,
    required NavigationGuardController controller,
    required super.child,
  }) : super(notifier: controller);

  static NavigationGuardController of(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<NavigationGuardScope>()!
        .notifier!;
  }
}

/// Wraps a screen so both leaving via the back gesture and leaving via a
/// bottom-nav tab tap run through the same [canLeave] check.
class LeaveGuard extends StatefulWidget {
  const LeaveGuard({super.key, required this.canLeave, required this.child});

  /// Returns true once it's OK to leave (either there was nothing to guard,
  /// or the user resolved it via a dialog shown inside this callback).
  final Future<bool> Function() canLeave;
  final Widget child;

  @override
  State<LeaveGuard> createState() => _LeaveGuardState();
}

class _LeaveGuardState extends State<LeaveGuard> {
  NavigationGuardController? _controller;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _controller = NavigationGuardScope.of(context);
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _controller?.register(widget.canLeave);
    });
  }

  @override
  void dispose() {
    _controller?.unregister(widget.canLeave);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        if (await widget.canLeave() && context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: widget.child,
    );
  }
}

enum LeaveChoice { save, discard }

/// Shared "unsaved changes" dialog used by every camera-settings screen that
/// stages edits locally behind a Save button. Callers pass their own Design
/// IDs so each screen keeps distinct, doc'd keys.
Future<bool> confirmDiscardOnLeave({
  required BuildContext context,
  required bool isDirty,
  required Future<void> Function() onSave,
  required bool Function() isDirtyAfterSave,
  required Key dialogKey,
  required Key discardKey,
  required Key saveKey,
}) async {
  if (!isDirty) return true;
  final choice = await showDialog<LeaveChoice>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      key: dialogKey,
      title: const Text('Unsaved changes'),
      content: const Text(
        'You have unsaved changes. Save them before leaving?',
      ),
      actions: [
        TextButton(
          key: discardKey,
          onPressed: () => Navigator.of(dialogContext).pop(LeaveChoice.discard),
          child: const Text('Discard'),
        ),
        FilledButton(
          key: saveKey,
          onPressed: () => Navigator.of(dialogContext).pop(LeaveChoice.save),
          child: const Text('Save'),
        ),
      ],
    ),
  );
  if (choice == LeaveChoice.save) {
    await onSave();
    return !isDirtyAfterSave();
  }
  return choice == LeaveChoice.discard;
}
