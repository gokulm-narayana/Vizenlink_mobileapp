import 'package:auth_api/auth_api.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app_state/theme_controller.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/gradient_background.dart';
import '../../widgets/gradient_button.dart';
import '../../widgets/password_form_field.dart';
import '../../widgets/theme_toggle_button.dart';
import '../login/login_screen.dart';
import 'confirm_signup_screen.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key, required this.themeController});

  static const routeName = '/signup';

  final ThemeController themeController;

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isSubmitting = false;

  /// LIVE feedback only — the strength bar under SIGNUP-006 (does not affect
  /// [_validatePassword], which still just enforces the app's actual
  /// minimum, 6 chars).
  double _passwordStrength = 0;

  @override
  void initState() {
    super.initState();
    _passwordController.addListener(_updatePasswordStrength);
    _confirmPasswordController.addListener(() => setState(() {}));
  }

  void _updatePasswordStrength() {
    final value = _passwordController.text;
    var score = 0;
    if (value.length >= 6) score++;
    if (value.length >= 10) score++;
    if (RegExp(r'[A-Z]').hasMatch(value) && RegExp(r'[a-z]').hasMatch(value)) {
      score++;
    }
    if (RegExp(r'[0-9]').hasMatch(value)) score++;
    if (RegExp(r'[^A-Za-z0-9]').hasMatch(value)) score++;
    setState(() => _passwordStrength = value.isEmpty ? 0 : score / 5);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  String? _validateName(String? value) {
    if (value == null || value.trim().isEmpty) return 'Name is required';
    return null;
  }

  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) return 'Email is required';
    final emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    if (!emailPattern.hasMatch(value.trim())) return 'Enter a valid email';
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) return 'Password is required';
    if (value.length < 6) return 'Password must be at least 6 characters';
    return null;
  }

  String? _validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) return 'Please confirm your password';
    if (value != _passwordController.text) return 'Passwords do not match';
    return null;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final name = _nameController.text.trim();

    setState(() => _isSubmitting = true);
    try {
      await AuthController.instance.signUp(email, password, name: name);
      if (!mounted) return;
      context.push(
        ConfirmSignupScreen.routeName,
        extra: ConfirmSignupArgs(email: email, password: password),
      );
    } on CognitoAuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AuthController.instance.lastError ?? e.message)),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Could not reach the server. Check your connection and try again.',
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _submitWithGoogle() async {
    // Stubbed: no google_sign_in package wired up yet.
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Sign up with Google (stub)')));
  }

  void _goToLogin() {
    context.go(LoginScreen.routeName);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        actions: [
          ThemeToggleButton(
            controller: widget.themeController,
            designId: 'SIGNUP-012',
          ),
        ],
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
                    Text(
                      key: const Key('SIGNUP-001'),
                      'Create your account',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Set up access to your cameras',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 28),
                    GlassCard(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          TextFormField(
                            key: const Key('SIGNUP-002'),
                            controller: _nameController,
                            decoration: const InputDecoration(
                              labelText: 'Name',
                              prefixIcon: Icon(Icons.person_outline),
                            ),
                            validator: _validateName,
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            key: const Key('SIGNUP-004'),
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            decoration: const InputDecoration(
                              labelText: 'Email',
                              prefixIcon: Icon(Icons.mail_outline),
                            ),
                            validator: _validateEmail,
                          ),
                          const SizedBox(height: 4),
                          PasswordFormField(
                            key: const Key('SIGNUP-006'),
                            controller: _passwordController,
                            labelText: 'Password',
                            validator: _validatePassword,
                          ),
                          if (_passwordController.text.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            _PasswordStrengthBar(
                              key: const Key('SIGNUP-014'),
                              strength: _passwordStrength,
                            ),
                          ],
                          const SizedBox(height: 16),
                          PasswordFormField(
                            key: const Key('SIGNUP-007'),
                            controller: _confirmPasswordController,
                            labelText: 'Confirm password',
                            validator: _validateConfirmPassword,
                            matchIndicator:
                                _confirmPasswordController.text.isNotEmpty &&
                                    _confirmPasswordController.text ==
                                        _passwordController.text
                                ? Icon(
                                    Icons.check_circle,
                                    key: const Key('SIGNUP-015'),
                                    color: Colors.green.shade600,
                                  )
                                : null,
                          ),
                          const SizedBox(height: 24),
                          GradientButton(
                            key: const Key('SIGNUP-008'),
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
                                : const Text('Sign up'),
                          ),
                          const SizedBox(height: 20),
                          Row(
                            key: const Key('SIGNUP-009'),
                            children: [
                              const Expanded(child: Divider()),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                ),
                                child: Text(
                                  'or',
                                  style: TextStyle(
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ),
                              const Expanded(child: Divider()),
                            ],
                          ),
                          const SizedBox(height: 20),
                          OutlinedButton.icon(
                            key: const Key('SIGNUP-010'),
                            onPressed: _submitWithGoogle,
                            icon: const Icon(Icons.account_circle_outlined),
                            label: const Text('Continue with Google'),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    TextButton(
                      key: const Key('SIGNUP-011'),
                      onPressed: _goToLogin,
                      child: const Text('Already have an account? Log in'),
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

/// SIGNUP-014 — live password-strength feedback for SIGNUP-006, purely a
/// visual hint (length/case/digit/symbol variety); does not affect
/// [_SignupScreenState._validatePassword]'s actual minimum requirement.
class _PasswordStrengthBar extends StatelessWidget {
  const _PasswordStrengthBar({super.key, required this.strength});

  /// 0.0-1.0.
  final double strength;

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (strength) {
      <= 0.2 => ('Weak', Colors.red.shade400),
      <= 0.6 => ('Medium', Colors.orange.shade400),
      _ => ('Strong', Colors.green.shade600),
    };
    return Row(
      children: [
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: strength,
              minHeight: 6,
              backgroundColor: color.withValues(alpha: 0.15),
              valueColor: AlwaysStoppedAnimation(color),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
