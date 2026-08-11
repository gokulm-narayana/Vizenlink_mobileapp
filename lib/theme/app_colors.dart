import 'package:flutter/material.dart';

/// Named palette tokens. Everything else in the theme derives from these —
/// change a look by editing here, not by hardcoding colors in screens.
class AppColors {
  AppColors._();

  // Brand
  static const Color indigo = Color(0xFF5B6EF5);
  static const Color cyan = Color(0xFF22D3EE);

  // Semantic status (independent of the brand accent)
  static const Color online = Color(0xFF34D399);
  static const Color offline = Color(0xFFFB7185);
  static const Color attention = Color(0xFFF59E0B);

  // Dark theme grounds
  static const Color darkBase = Color(0xFF0B1120);
  static const Color darkMid = Color(0xFF141B33);
  static const Color darkGlass = Color(0xFF1B2340);

  // Light theme grounds
  static const Color lightBase = Color(0xFFF4F6FB);
  static const Color lightMid = Color(0xFFE7ECFB);
  static const Color lightGlass = Color(0xFFFFFFFF);

  /// The app's single "primary action" gradient — indigo → cyan. Used
  /// everywhere something communicates "this is the main thing to tap":
  /// the selected tab indicator, primary buttons, and the Add Camera FAB.
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [indigo, cyan],
  );
}
