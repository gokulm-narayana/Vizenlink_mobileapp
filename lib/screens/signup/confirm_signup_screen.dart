import 'package:auth_api/auth_api.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../widgets/glass_card.dart';
import '../../widgets/gradient_background.dart';
import '../../widgets/gradient_button.dart';
import '../dashboard/dashboard_screen.dart';
import '../login/login_screen.dart';

/// Arguments for [ConfirmSignupScreen] — carries the password entered on
/// signup (or re-entered on a "not confirmed yet" login attempt) so the
/// screen can sign the user straight in after the confirmation code is
/// accepted, matching [AuthController.signIn]'s "no separate login step"
/// behavior documented in `packages/auth_api/API_REFERENCE.md`.
class ConfirmSignupArgs {
  const ConfirmSignupArgs({required this.email, required this.password});

  final String email;
  final String password;
}

class ConfirmSignupScreen extends StatefulWidget {
  const ConfirmSignupScreen({super.key, required this.args});

  static const routeName = '/confirm-signup';

  final ConfirmSignupArgs args;

  @override
  State<ConfirmSignupScreen> createState() => _ConfirmSignupScreenState();
}

class _ConfirmSignupScreenState extends State<ConfirmSignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();
  String? _errorText;
  bool _isSubmitting = false;
  bool _isResending = false;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  String? _validateCode(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Confirmation code is required';
    }
    if (value.trim().length != 6) return 'Enter the 6-digit code';
    return null;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
      _errorText = null;
    });
    try {
      await AuthController.instance.confirmSignUp(
        widget.args.email,
        _codeController.text.trim(),
      );
      await AuthController.instance.signIn(
        widget.args.email,
        widget.args.password,
      );
      if (!mounted) return;
      context.go(DashboardScreen.routeName);
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

  Future<void> _resendCode() async {
    setState(() => _isResending = true);
    try {
      await AuthController.instance.resendConfirmationCode(widget.args.email);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Confirmation code resent.')),
      );
    } on CognitoAuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.message)));
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
      if (mounted) setState(() => _isResending = false);
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
                      key: const Key('CONFIRM-001'),
                      'Confirm your email',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      key: const Key('CONFIRM-002'),
                      'Enter the code sent to ${widget.args.email}',
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
                            key: const Key('CONFIRM-003'),
                            controller: _codeController,
                            keyboardType: TextInputType.number,
                            maxLength: 6,
                            decoration: const InputDecoration(
                              labelText: 'Confirmation code',
                              prefixIcon: Icon(Icons.pin_outlined),
                              counterText: '',
                            ),
                            validator: _validateCode,
                          ),
                          if (_errorText != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              key: const Key('CONFIRM-004'),
                              _errorText!,
                              style: TextStyle(color: colorScheme.error),
                            ),
                          ],
                          const SizedBox(height: 20),
                          GradientButton(
                            key: const Key('CONFIRM-005'),
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
                                : const Text('Confirm'),
                          ),
                          const SizedBox(height: 12),
                          TextButton(
                            key: const Key('CONFIRM-006'),
                            onPressed: _isResending ? null : _resendCode,
                            child: Text(
                              _isResending ? 'Resending…' : 'Resend code',
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    TextButton(
                      key: const Key('CONFIRM-007'),
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
