import 'package:flutter/material.dart';

import 'app_colors.dart';

class AppTheme {
  AppTheme._();

  static const _headingFont = 'Manrope';
  static const _bodyFont = 'Inter';

  static ThemeData light() {
    final scheme =
        ColorScheme.fromSeed(
          seedColor: AppColors.indigo,
          brightness: Brightness.light,
          secondary: AppColors.cyan,
        ).copyWith(
          surface: AppColors.lightBase,
          surfaceContainerHighest: AppColors.lightGlass,
        );
    return _themeFrom(scheme);
  }

  static ThemeData dark() {
    final scheme =
        ColorScheme.fromSeed(
          seedColor: AppColors.indigo,
          brightness: Brightness.dark,
          secondary: AppColors.cyan,
        ).copyWith(
          surface: AppColors.darkBase,
          surfaceContainerHighest: AppColors.darkGlass,
        );
    return _themeFrom(scheme);
  }

  static ThemeData _themeFrom(ColorScheme scheme) {
    final baseTextTheme = ThemeData(brightness: scheme.brightness).textTheme;
    final textTheme = baseTextTheme
        .apply(
          fontFamily: _bodyFont,
          bodyColor: scheme.onSurface,
          displayColor: scheme.onSurface,
        )
        .copyWith(
          headlineSmall: TextStyle(
            fontFamily: _headingFont,
            fontWeight: FontWeight.w800,
            fontSize: 26,
            color: scheme.onSurface,
          ),
          headlineMedium: TextStyle(
            fontFamily: _headingFont,
            fontWeight: FontWeight.w800,
            fontSize: 30,
            color: scheme.onSurface,
          ),
          titleLarge: TextStyle(
            fontFamily: _headingFont,
            fontWeight: FontWeight.w700,
            fontSize: 20,
            color: scheme.onSurface,
          ),
          titleMedium: TextStyle(
            fontFamily: _headingFont,
            fontWeight: FontWeight.w700,
            color: scheme.onSurface,
          ),
          bodyMedium: TextStyle(
            fontFamily: _bodyFont,
            height: 1.4,
            color: scheme.onSurface,
          ),
        );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: Colors.transparent,
      fontFamily: _bodyFont,
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: scheme.onSurface,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontFamily: _headingFont,
          fontWeight: FontWeight.w800,
          fontSize: 22,
          color: scheme.onSurface,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.brightness == Brightness.dark
            ? Colors.white.withValues(alpha: 0.06)
            : Colors.white.withValues(alpha: 0.6),
        // No visible stroke in the default/enabled state — `OutlineInputBorder`
        // still needs to be the border type (for its rounded fill shape and
        // the floating-label notch geometry), but an actually-drawn line
        // here sits on top of this app's frosted-glass dialog backgrounds
        // (BackdropFilter blur, not a flat color), making the floating
        // label's notch look like it's awkwardly cutting through the box's
        // top edge instead of cleanly separating from it. The focused state
        // below keeps a real stroke — useful feedback with only one field
        // ever focused at a time, unlike the enabled state which every field
        // sits in most of the time.
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: scheme.primary, width: 1.6),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: scheme.primary,
          foregroundColor: Colors.white,
          disabledBackgroundColor: scheme.onSurface.withValues(alpha: 0.12),
          disabledForegroundColor: scheme.onSurface.withValues(alpha: 0.38),
          minimumSize: const Size.fromHeight(52),
          elevation: 0,
          shadowColor: scheme.primary.withValues(alpha: 0.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(
            fontFamily: _headingFont,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: scheme.onSurface,
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          side: BorderSide(
            color: scheme.brightness == Brightness.dark
                ? Colors.white.withValues(alpha: 0.16)
                : Colors.black.withValues(alpha: 0.1),
          ),
          textStyle: const TextStyle(
            fontFamily: _headingFont,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      tabBarTheme: TabBarThemeData(
        indicator: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: scheme.primary.withValues(alpha: 0.14),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        labelColor: scheme.primary,
        unselectedLabelColor: scheme.onSurfaceVariant,
        labelStyle: const TextStyle(
          fontFamily: _headingFont,
          fontWeight: FontWeight.w700,
        ),
        dividerColor: Colors.transparent,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: scheme.brightness == Brightness.dark
            ? Colors.white.withValues(alpha: 0.06)
            : Colors.white.withValues(alpha: 0.7),
        elevation: 0,
        indicatorColor: scheme.primary,
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => TextStyle(
            fontFamily: _headingFont,
            fontSize: 12,
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w700
                : FontWeight.w500,
            color: states.contains(WidgetState.selected)
                ? scheme.primary
                : scheme.onSurfaceVariant,
          ),
        ),
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            color: states.contains(WidgetState.selected)
                ? Colors.white
                : scheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}
