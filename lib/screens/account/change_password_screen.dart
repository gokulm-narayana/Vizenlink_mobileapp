import 'package:auth_api/auth_api.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../widgets/glass_card.dart';
import '../../widgets/gradient_background.dart';
import '../../widgets/gradient_button.dart';
import '../../widgets/password_form_field.dart';

/// Full-screen change-password flow, reached from AccountSettingsScreen's
/// "Change password" row — replaces a previous `AlertDialog`-based popup
/// that looked inconsistent with the rest of the app's screens. Calls real
/// `auth_api` `AuthController.changePassword` (AWS Cognito) — no OTP step,
/// Cognito verifies the current password itself.
class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  static const routeName = 'change-password';

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _currentController = TextEditingController();
  final _newController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _isSubmitting = false;
  String? _errorText;

  @override
  void dispose() {
    _currentController.dispose();
    _newController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  /// Cognito throttles `ChangePassword` like most sensitive account
  /// operations, surfaced only as raw, unfriendly text
  /// (`LimitExceededException`/`TooManyRequestsException`) — a documented
  /// known gap in `packages/auth_api`'s own API_REFERENCE.md ("Friendly
  /// Cognito throttling messages" — not implemented in that package).
  /// Mapped to friendlier copy here at the screen layer instead.
  String _friendlyMessage(CognitoAuthException e) => switch (e.code) {
    'LimitExceededException' || 'TooManyRequestsException' =>
      'Too many attempts. Please wait a few minutes and try again.',
    _ => e.message,
  };

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
      _errorText = null;
    });
    try {
      await AuthController.instance.changePassword(
        _currentController.text,
        _newController.text,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Password updated')));
      context.pop();
    } on CognitoAuthException catch (e) {
      setState(() => _errorText = _friendlyMessage(e));
    } catch (_) {
      setState(
        () => _errorText =
            'Could not reach the server. Check your connection and try again.',
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        key: const Key('CHPW-001'),
        title: const Text('Change password'),
      ),
      body: GradientBackground(
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    GlassCard(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          PasswordFormField(
                            key: const Key('CHPW-002'),
                            controller: _currentController,
                            labelText: 'Current password',
                            textInputAction: TextInputAction.next,
                            validator: (value) =>
                                (value == null || value.isEmpty)
                                ? 'Required'
                                : null,
                          ),
                          const SizedBox(height: 16),
                          PasswordFormField(
                            key: const Key('CHPW-003'),
                            controller: _newController,
                            labelText: 'New password',
                            textInputAction: TextInputAction.next,
                            validator: (value) =>
                                (value == null || value.length < 6)
                                ? 'At least 6 characters'
                                : null,
                          ),
                          const SizedBox(height: 16),
                          PasswordFormField(
                            key: const Key('CHPW-004'),
                            controller: _confirmController,
                            labelText: 'Confirm new password',
                            textInputAction: TextInputAction.done,
                            onFieldSubmitted: (_) => _submit(),
                            validator: (value) => value != _newController.text
                                ? 'Passwords do not match'
                                : null,
                          ),
                          if (_errorText != null) ...[
                            const SizedBox(height: 12),
                            Text(
                              key: const Key('CHPW-005'),
                              _errorText!,
                              style: TextStyle(color: colorScheme.error),
                            ),
                          ],
                          const SizedBox(height: 24),
                          GradientButton(
                            key: const Key('CHPW-006'),
                            onPressed: _isSubmitting ? null : _submit,
                            child: _isSubmitting
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation(
                                        Colors.white,
                                      ),
                                    ),
                                  )
                                : const Text('Update'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
