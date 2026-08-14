import 'package:auth_api/auth_api.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../widgets/glass_card.dart';
import '../../widgets/gradient_background.dart';
import '../../widgets/gradient_button.dart';
import '../../widgets/password_form_field.dart';
import 'login_screen.dart';

/// Two-step Cognito forgot-password flow, both steps on one screen (not two
/// routes) so the email entered in step 1 carries straight into step 2
/// without needing to thread it through navigation `extra`.
class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  static const routeName = '/forgot-password';

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _codeController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _codeSent = false;
  bool _isSubmitting = false;
  String? _errorText;

  @override
  void dispose() {
    _emailController.dispose();
    _codeController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) return 'Email is required';
    final emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    if (!emailPattern.hasMatch(value.trim())) return 'Enter a valid email';
    return null;
  }

  String? _validateCode(String? value) {
    if (!_codeSent) return null;
    if (value == null || value.trim().isEmpty) {
      return 'Confirmation code is required';
    }
    return null;
  }

  String? _validateNewPassword(String? value) {
    if (!_codeSent) return null;
    if (value == null || value.isEmpty) return 'Password is required';
    if (value.length < 6) return 'Password must be at least 6 characters';
    return null;
  }

  String? _validateConfirmPassword(String? value) {
    if (!_codeSent) return null;
    if (value != _newPasswordController.text) return 'Passwords do not match';
    return null;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
      _errorText = null;
    });
    try {
      if (!_codeSent) {
        await AuthController.instance.forgotPassword(
          _emailController.text.trim(),
        );
        if (!mounted) return;
        setState(() => _codeSent = true);
      } else {
        await AuthController.instance.confirmForgotPassword(
          _emailController.text.trim(),
          _codeController.text.trim(),
          _newPasswordController.text,
        );
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Password reset. Please log in.')),
        );
        context.go(LoginScreen.routeName);
      }
    } on CognitoAuthException catch (e) {
      setState(() => _errorText = e.message);
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
      appBar: AppBar(automaticallyImplyLeading: false),
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
                    Text(
                      key: const Key('FORGOT-001'),
                      'Reset password',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 28),
                    GlassCard(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          TextFormField(
                            key: const Key('FORGOT-002'),
                            controller: _emailController,
                            enabled: !_codeSent,
                            keyboardType: TextInputType.emailAddress,
                            decoration: const InputDecoration(
                              labelText: 'Email',
                              prefixIcon: Icon(Icons.mail_outline),
                            ),
                            validator: _validateEmail,
                          ),
                          if (_errorText != null && !_codeSent) ...[
                            const SizedBox(height: 4),
                            Text(
                              key: const Key('FORGOT-007'),
                              _errorText!,
                              style: TextStyle(color: colorScheme.error),
                            ),
                          ],
                          if (!_codeSent) ...[
                            const SizedBox(height: 20),
                            GradientButton(
                              key: const Key('FORGOT-003'),
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
                                  : const Text('Send code'),
                            ),
                          ] else ...[
                            const SizedBox(height: 16),
                            TextFormField(
                              key: const Key('FORGOT-004'),
                              controller: _codeController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Confirmation code',
                                prefixIcon: Icon(Icons.pin_outlined),
                              ),
                              validator: _validateCode,
                            ),
                            const SizedBox(height: 16),
                            PasswordFormField(
                              key: const Key('FORGOT-005'),
                              controller: _newPasswordController,
                              labelText: 'New password',
                              validator: _validateNewPassword,
                            ),
                            const SizedBox(height: 16),
                            PasswordFormField(
                              key: const Key('FORGOT-006'),
                              controller: _confirmPasswordController,
                              labelText: 'Confirm new password',
                              validator: _validateConfirmPassword,
                            ),
                            if (_errorText != null) ...[
                              const SizedBox(height: 4),
                              Text(
                                key: const Key('FORGOT-007'),
                                _errorText!,
                                style: TextStyle(color: colorScheme.error),
                              ),
                            ],
                            const SizedBox(height: 20),
                            GradientButton(
                              key: const Key('FORGOT-008'),
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
                                  : const Text('Reset password'),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    TextButton(
                      key: const Key('FORGOT-009'),
                      onPressed: () => context.go(LoginScreen.routeName),
                      child: const Text('Back to log in'),
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
