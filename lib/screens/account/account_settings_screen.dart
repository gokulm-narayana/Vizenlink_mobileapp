import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../app_state/profile_controller.dart';
import '../../theme/app_colors.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/gradient_background.dart';
import 'account_screen.dart';
import 'active_sessions_screen.dart';

/// Account settings: edit display name, change email/phone (via a stubbed
/// OTP flow), change password, toggle 2FA, view active sessions, delete
/// account. No auth backend is wired up yet (see CLAUDE.md), so every
/// "verification" here always succeeds — there's nothing real to check
/// against. Display name/email/phone write through [profileController] so
/// the Profile tab stays in sync.
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
    final valueController = TextEditingController(text: currentValue);

    final newValue = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('New $label'),
        content: TextFormField(
          key: const Key('ACSET-010'),
          controller: valueController,
          decoration: InputDecoration(labelText: label),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            key: const Key('ACSET-011'),
            onPressed: () =>
                Navigator.of(dialogContext).pop(valueController.text.trim()),
            child: const Text('Send code'),
          ),
        ],
      ),
    );

    valueController.dispose();

    if (newValue == null || newValue.isEmpty || !mounted) return;

    final verified = await _showOtpDialog();
    if (verified && mounted) {
      onVerified(newValue);
      _showSnackBar('$label updated');
    }
  }

  Future<bool> _showOtpDialog() async {
    final otpController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Enter verification code'),
        content: Form(
          key: formKey,
          child: TextFormField(
            key: const Key('ACSET-012'),
            controller: otpController,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            maxLength: 6,
            decoration: const InputDecoration(labelText: '6-digit code'),
            validator: (value) =>
                (value?.length ?? 0) == 6 ? null : 'Enter the 6-digit code',
          ),
        ),
        actions: [
          TextButton(
            key: const Key('ACSET-014'),
            onPressed: () => _showSnackBar('Code resent'),
            child: const Text('Resend code'),
          ),
          ElevatedButton(
            key: const Key('ACSET-013'),
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.of(dialogContext).pop(true);
              }
            },
            child: const Text('Verify'),
          ),
        ],
      ),
    );
    otpController.dispose();
    return result ?? false;
  }

  Future<void> _changePassword() async {
    final currentController = TextEditingController();
    final newController = TextEditingController();
    final confirmController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final updated = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Change password'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                key: const Key('ACSET-015'),
                controller: currentController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Current password',
                ),
                validator: (value) =>
                    (value == null || value.isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                key: const Key('ACSET-016'),
                controller: newController,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'New password'),
                validator: (value) => (value == null || value.length < 6)
                    ? 'At least 6 characters'
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                key: const Key('ACSET-017'),
                controller: confirmController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Confirm new password',
                ),
                validator: (value) => value != newController.text
                    ? 'Passwords do not match'
                    : null,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            key: const Key('ACSET-018'),
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.of(dialogContext).pop(true);
              }
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );

    currentController.dispose();
    newController.dispose();
    confirmController.dispose();

    if ((updated ?? false) && mounted) {
      final verified = await _showOtpDialog();
      if (verified && mounted) {
        _showSnackBar('Password updated');
      }
    }
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
    final codeController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: Form(
          key: formKey,
          child: TextFormField(
            key: const Key('ACSET-019'),
            controller: codeController,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            maxLength: 6,
            decoration: const InputDecoration(labelText: '6-digit code'),
            validator: (value) =>
                (value?.length ?? 0) == 6 ? null : 'Enter the 6-digit code',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            key: const Key('ACSET-020'),
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.of(dialogContext).pop(true);
              }
            },
            child: const Text('Confirm'),
          ),
        ],
      ),
    );

    codeController.dispose();
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
                      onTap: _changePassword,
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
