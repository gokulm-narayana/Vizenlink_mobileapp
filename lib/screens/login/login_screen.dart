import 'package:auth_api/auth_api.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app_state/theme_controller.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/gradient_background.dart';
import '../../widgets/gradient_button.dart';
import '../../widgets/password_form_field.dart';
import '../../widgets/theme_toggle_button.dart';
import '../dashboard/dashboard_screen.dart';
import '../signup/confirm_signup_screen.dart';
import '../signup/signup_screen.dart';
import 'forgot_password_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, required this.themeController});

  static const routeName = '/login';

  final ThemeController themeController;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _identifierTabController;
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _identifierTabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final expiredMessage = AuthController.instance.sessionExpiredMessage;
      if (expiredMessage != null && mounted) {
        AuthController.instance.sessionExpiredMessage = null;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(expiredMessage)));
      }
    });
  }

  @override
  void dispose() {
    _identifierTabController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) return 'Email is required';
    final emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    if (!emailPattern.hasMatch(value.trim())) return 'Enter a valid email';
    return null;
  }

  String? _validatePhone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Phone number is required';
    }
    final phonePattern = RegExp(r'^\+?[0-9]{7,15}$');
    if (!phonePattern.hasMatch(value.trim())) {
      return 'Enter a valid phone number';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) return 'Password is required';
    if (value.length < 6) return 'Password must be at least 6 characters';
    return null;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_identifierTabController.index != 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Phone sign-in is not available yet — use email.'),
        ),
      );
      return;
    }

    final email = _emailController.text.trim();
    final password = _passwordController.text;

    setState(() => _isSubmitting = true);
    try {
      await AuthController.instance.signIn(email, password);
      if (!mounted) return;
      context.go(DashboardScreen.routeName);
    } on CognitoAuthException catch (e) {
      if (!mounted) return;
      if (e.code == 'UserNotConfirmedException') {
        context.push(
          ConfirmSignupScreen.routeName,
          extra: ConfirmSignupArgs(email: email, password: password),
        );
        return;
      }
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
    ).showSnackBar(const SnackBar(content: Text('Sign in with Google (stub)')));
  }

  void _goToSignup() {
    context.go(SignupScreen.routeName);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        actions: [
          ThemeToggleButton(
            controller: widget.themeController,
            designId: 'LOGIN-010',
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
                      key: const Key('LOGIN-001'),
                      'Welcome back',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Sign in to view your cameras',
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
                          ClipRRect(
                            borderRadius: BorderRadius.circular(14),
                            child: TabBar(
                              key: const Key('LOGIN-002'),
                              controller: _identifierTabController,
                              tabs: const [
                                Tab(text: 'Email'),
                                Tab(text: 'Phone'),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            height: 72,
                            child: TabBarView(
                              controller: _identifierTabController,
                              children: [
                                TextFormField(
                                  key: const Key('LOGIN-003'),
                                  controller: _emailController,
                                  keyboardType: TextInputType.emailAddress,
                                  decoration: const InputDecoration(
                                    labelText: 'Email',
                                    prefixIcon: Icon(Icons.mail_outline),
                                  ),
                                  validator: (value) =>
                                      _identifierTabController.index == 0
                                      ? _validateEmail(value)
                                      : null,
                                ),
                                TextFormField(
                                  key: const Key('LOGIN-004'),
                                  controller: _phoneController,
                                  keyboardType: TextInputType.phone,
                                  decoration: const InputDecoration(
                                    labelText: 'Phone number',
                                    prefixIcon: Icon(Icons.phone_outlined),
                                  ),
                                  validator: (value) =>
                                      _identifierTabController.index == 1
                                      ? _validatePhone(value)
                                      : null,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 4),
                          PasswordFormField(
                            key: const Key('LOGIN-005'),
                            controller: _passwordController,
                            labelText: 'Password',
                            validator: _validatePassword,
                          ),
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              key: const Key('LOGIN-011'),
                              onPressed: () =>
                                  context.push(ForgotPasswordScreen.routeName),
                              child: const Text('Forgot password?'),
                            ),
                          ),
                          const SizedBox(height: 8),
                          GradientButton(
                            key: const Key('LOGIN-006'),
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
                                : const Text('Log in'),
                          ),
                          const SizedBox(height: 20),
                          Row(
                            key: const Key('LOGIN-007'),
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
                            key: const Key('LOGIN-008'),
                            onPressed: _submitWithGoogle,
                            icon: const Icon(Icons.g_mobiledata, size: 28),
                            label: const Text('Continue with Google'),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    TextButton(
                      key: const Key('LOGIN-009'),
                      onPressed: _goToSignup,
                      child: const Text("Don't have an account? Sign up"),
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
