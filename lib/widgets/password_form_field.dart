import 'package:flutter/material.dart';

/// A `TextFormField` for password/secret entry with a consistent show/hide
/// (eye) toggle, so every screen doesn't reimplement its own obscure-text
/// state. Drop-in replacement for a bare `TextFormField(obscureText: true)`.
class PasswordFormField extends StatefulWidget {
  const PasswordFormField({
    super.key,
    this.controller,
    required this.labelText,
    this.validator,
    this.textInputAction,
    this.onFieldSubmitted,
    this.matchIndicator,
  });

  final TextEditingController? controller;
  final String labelText;
  final String? Function(String?)? validator;
  final TextInputAction? textInputAction;
  final void Function(String)? onFieldSubmitted;

  /// Optional small icon shown to the left of the show/hide toggle — e.g.
  /// Signup's confirm-password field uses this for a live checkmark once it
  /// matches the password field, without needing its own reimplementation
  /// of this widget's show/hide suffix.
  final Widget? matchIndicator;

  @override
  State<PasswordFormField> createState() => _PasswordFormFieldState();
}

class _PasswordFormFieldState extends State<PasswordFormField> {
  bool _obscure = true;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.controller,
      obscureText: _obscure,
      textInputAction: widget.textInputAction,
      onFieldSubmitted: widget.onFieldSubmitted,
      decoration: InputDecoration(
        labelText: widget.labelText,
        prefixIcon: const Icon(Icons.lock_outline),
        suffixIcon: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.matchIndicator != null) widget.matchIndicator!,
            IconButton(
              icon: Icon(
                _obscure
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
              ),
              onPressed: () => setState(() => _obscure = !_obscure),
            ),
          ],
        ),
      ),
      validator: widget.validator,
    );
  }
}
