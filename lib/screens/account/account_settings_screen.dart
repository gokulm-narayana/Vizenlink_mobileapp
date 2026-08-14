import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../app_state/profile_controller.dart';
import '../../theme/app_colors.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/gradient_background.dart';
import 'account_screen.dart';
import 'active_sessions_screen.dart';
import 'change_password_screen.dart';

/// Account settings: edit display name, change email/phone (via a stubbed
/// OTP flow — no client code exists for that yet), change password (pushes
/// [ChangePasswordScreen], a full screen — calls real `auth_api`
/// `AuthController.changePassword`), toggle 2FA, view active sessions,
/// delete account. Display name/email/phone write through
/// [profileController] so the Profile tab stays in sync.
///
/// Every text-entry dialog below (`_TextFieldDialog`, `_CodeDialog`) owns
/// its `TextEditingController`(s) in its own `State`, disposed via
/// `State.dispose()` rather than manually right after `showDialog` returns.
/// **Manual disposal there is a real bug, not just style** — `showDialog`'s
/// Future completes as soon as `Navigator.pop()` is called, which is before
/// the dialog's exit *animation* finishes; its `TextFormField`s are still
/// mounted and can still rebuild mid-transition, referencing a controller
/// that's already been disposed ("A TextEditingController was used after
/// being disposed", cascading into a framework `_dependents.isEmpty`
/// assertion — hit on real hardware 2026-08-14, originally on the
/// change-password dialog, which has since moved to its own screen for
/// unrelated UI reasons but the same latent bug existed in every dialog in
/// this file).
class AccountSettingsScreen extends StatefulWidget {
  const AccountSettingsScreen({super.key, required this.profileController});

  static const routeName = 'settings';

  final ProfileController profileController;

  @override
  State<AccountSettingsScreen> createState() => _AccountSettingsScreenState();
}

class _AccountSettingsScreenState extends State<AccountSettingsScreen> {
  late final _nameController = TextEditingController(
    text: widget.profileController.value.displayName,
  );
  bool _twoFactorEnabled = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  void _saveName() {
    widget.profileController.updateDisplayName(_nameController.text.trim());
    _showSnackBar('Saved');
  }

  Future<void> _changeValue({
    required String label,
    required String currentValue,
    required ValueChanged<String> onVerified,
  }) async {
    final newValue = await showDialog<String>(
      context: context,
      builder: (dialogContext) => _TextFieldDialog(
        title: 'New $label',
        initialValue: currentValue,
        fieldKey: const Key('ACSET-010'),
        labelText: label,
        confirmLabel: 'Send code',
        confirmKey: const Key('ACSET-011'),
      ),
    );

    if (newValue == null || newValue.isEmpty || !mounted) return;

    final verified = await _showOtpDialog();
    if (verified && mounted) {
      onVerified(newValue);
      _showSnackBar('$label updated');
    }
  }

  Future<bool> _showOtpDialog() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => _CodeDialog(
        title: 'Enter verification code',
        fieldKey: const Key('ACSET-012'),
        confirmKey: const Key('ACSET-013'),
        confirmLabel: 'Verify',
        showCancel: false,
        onResend: () => _showSnackBar('Code resent'),
        resendKey: const Key('ACSET-014'),
      ),
    );
    return result ?? false;
  }

  Future<void> _toggleTwoFactor(bool requestedValue) async {
    final confirmed = requestedValue
        ? await _enableTwoFactor()
        : await _disableTwoFactor();

    if (confirmed) {
      setState(() => _twoFactorEnabled = requestedValue);
    }
  }

  Future<bool> _enableTwoFactor() async {
    final proceedToVerify = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Scan to enable 2FA'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              key: const Key('ACSET-021'),
              width: 160,
              height: 160,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Theme.of(
                  dialogContext,
                ).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.qr_code_2,
                size: 120,
                color: Theme.of(dialogContext).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Scan this QR code with your authenticator app, or enter the '
              'key manually:',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            SelectableText(
              key: const Key('ACSET-022'),
              'JBSW-Y3DP-EHPK-3PXP',
              style: Theme.of(
                dialogContext,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            key: const Key('ACSET-023'),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Continue'),
          ),
        ],
      ),
    );

    if (proceedToVerify ?? false) {
      return _confirmTwoFactorCode(title: 'Enable two-factor authentication?');
    }
    return false;
  }

  Future<bool> _disableTwoFactor() =>
      _confirmTwoFactorCode(title: 'Disable two-factor authentication?');

  Future<bool> _confirmTwoFactorCode({required String title}) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => _CodeDialog(
        title: title,
        fieldKey: const Key('ACSET-019'),
        confirmKey: const Key('ACSET-020'),
        confirmLabel: 'Confirm',
      ),
    );
    return confirmed ?? false;
  }

  Future<void> _deleteAccount() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete account?'),
        content: const Text(
          'This permanently deletes your account and all its data. '
          "This can't be undone.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed ?? false) {
      _showSnackBar('Account deletion — coming soon');
    }
  }

  @override
  Widget build(BuildContext context) {
    return GradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          key: const Key('ACSET-001'),
          title: const Text('Account Settings'),
        ),
        body: ValueListenableBuilder<ProfileData>(
          valueListenable: widget.profileController,
          builder: (context, profile, _) => ListView(
            padding: const EdgeInsets.all(16),
            children: [
              GlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextFormField(
                      key: const Key('ACSET-002'),
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Display name',
                      ),
                    ),
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerRight,
                      child: ElevatedButton(
                        key: const Key('ACSET-009'),
                        onPressed: _saveName,
                        child: const Text('Save'),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              GlassCard(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    ListTile(
                      key: const Key('ACSET-003'),
                      title: const Text('Email'),
                      subtitle: Text(profile.email),
                      trailing: TextButton(
                        onPressed: () => _changeValue(
                          label: 'email',
                          currentValue: profile.email,
                          onVerified: widget.profileController.updateEmail,
                        ),
                        child: const Text('Change'),
                      ),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      key: const Key('ACSET-004'),
                      title: const Text('Phone number'),
                      subtitle: Text(profile.phone),
                      trailing: TextButton(
                        onPressed: () => _changeValue(
                          label: 'phone number',
                          currentValue: profile.phone,
                          onVerified: widget.profileController.updatePhone,
                        ),
                        child: const Text('Change'),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              GlassCard(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    ListTile(
                      key: const Key('ACSET-005'),
                      leading: const Icon(Icons.lock_outline),
                      title: const Text('Change password'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => context.push(
                        '${AccountScreen.routeName}/${AccountSettingsScreen.routeName}/${ChangePasswordScreen.routeName}',
                      ),
                    ),
                    const Divider(height: 1),
                    SwitchListTile(
                      key: const Key('ACSET-006'),
                      secondary: const Icon(Icons.shield_outlined),
                      title: const Text('Two-factor authentication'),
                      value: _twoFactorEnabled,
                      onChanged: _toggleTwoFactor,
                    ),
                    const Divider(height: 1),
                    ListTile(
                      key: const Key('ACSET-007'),
                      leading: const Icon(Icons.devices_outlined),
                      title: const Text('Active sessions'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => context.push(
                        '${AccountScreen.routeName}/${AccountSettingsScreen.routeName}/${ActiveSessionsScreen.routeName}',
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              GlassCard(
                padding: EdgeInsets.zero,
                child: ListTile(
                  key: const Key('ACSET-008'),
                  leading: const Icon(
                    Icons.delete_forever_outlined,
                    color: AppColors.offline,
                  ),
                  title: const Text(
                    'Delete account',
                    style: TextStyle(color: AppColors.offline),
                  ),
                  onTap: _deleteAccount,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Single-field text-entry dialog (email/phone change) — see this file's
/// top doc comment for why it owns its own controller instead of the caller
/// disposing one manually after `showDialog` returns.
class _TextFieldDialog extends StatefulWidget {
  const _TextFieldDialog({
    required this.title,
    required this.initialValue,
    required this.fieldKey,
    required this.labelText,
    required this.confirmLabel,
    required this.confirmKey,
  });

  final String title;
  final String initialValue;
  final Key fieldKey;
  final String labelText;
  final String confirmLabel;
  final Key confirmKey;

  @override
  State<_TextFieldDialog> createState() => _TextFieldDialogState();
}

class _TextFieldDialogState extends State<_TextFieldDialog> {
  late final _controller = TextEditingController(text: widget.initialValue);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: TextFormField(
        key: widget.fieldKey,
        controller: _controller,
        decoration: InputDecoration(labelText: widget.labelText),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          key: widget.confirmKey,
          onPressed: () => Navigator.of(context).pop(_controller.text.trim()),
          child: Text(widget.confirmLabel),
        ),
      ],
    );
  }
}

/// 6-digit code entry dialog, shared by the OTP-verification step
/// ([showCancel] false, has [onResend]) and the 2FA enable/disable
/// confirmation ([showCancel] true, no resend). Same controller-ownership
/// reasoning as [_TextFieldDialog].
class _CodeDialog extends StatefulWidget {
  const _CodeDialog({
    required this.title,
    required this.fieldKey,
    required this.confirmKey,
    required this.confirmLabel,
    this.showCancel = true,
    this.onResend,
    this.resendKey,
  });

  final String title;
  final Key fieldKey;
  final Key confirmKey;
  final String confirmLabel;
  final bool showCancel;
  final VoidCallback? onResend;
  final Key? resendKey;

  @override
  State<_CodeDialog> createState() => _CodeDialogState();
}

class _CodeDialogState extends State<_CodeDialog> {
  final _controller = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: Form(
        key: _formKey,
        child: TextFormField(
          key: widget.fieldKey,
          controller: _controller,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          maxLength: 6,
          decoration: const InputDecoration(labelText: '6-digit code'),
          validator: (value) =>
              (value?.length ?? 0) == 6 ? null : 'Enter the 6-digit code',
        ),
      ),
      actions: [
        if (widget.onResend != null)
          TextButton(
            key: widget.resendKey,
            onPressed: widget.onResend,
            child: const Text('Resend code'),
          ),
        if (widget.showCancel)
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
        ElevatedButton(
          key: widget.confirmKey,
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              Navigator.of(context).pop(true);
            }
          },
          child: Text(widget.confirmLabel),
        ),
      ],
    );
  }
}
