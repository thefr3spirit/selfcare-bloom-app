import 'package:flutter/material.dart';

/// Centralized theme and design system for production
/// Professional wellness-focused palette — calming teal + warm neutrals
class AppTheme {
  // ── Brand Colors ──────────────────────────────────────────
  static const Color primary = Color(0xFF0F766E); // Deep teal
  static const Color primaryLight = Color(0xFFCCFBF1); // Very light teal
  static const Color primaryDark = Color(0xFF115E59); // Darker teal
  static const Color accent = Color(0xFFD97706); // Warm amber

  // Legacy aliases (so existing code keeps compiling)
  static const Color primaryBlue = primary;
  static const Color lightBlue = primaryLight;
  static const Color darkBlue = primaryDark;

  // ── Stress Level Colors (refined) ────────────────────────
  static const Color stressLow = Color(0xFF10B981); // Emerald
  static const Color stressMild = Color(0xFF34D399); // Light emerald
  static const Color stressModerate = Color(0xFFF59E0B); // Amber
  static const Color stressHigh = Color(0xFFF97316); // Orange
  static const Color stressSevere = Color(0xFFE11D48); // Rose

  // ── Semantic Colors ──────────────────────────────────────
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFE11D48);
  static const Color info = Color(0xFF0EA5E9);

  // ── Neutral Colors ───────────────────────────────────────
  static const Color textPrimary = Color(0xFF1E293B); // Slate 800
  static const Color textSecondary = Color(0xFF64748B); // Slate 500
  static const Color background = Color(0xFFF8FAFC); // Slate 50
  static const Color cardBackground = Colors.white;
  static const Color divider = Color(0xFFE2E8F0); // Slate 200
  static const Color surfaceLight = Color(0xFFF1F5F9); // Slate 100

  // Spacing System (8px baseline grid)
  static const double spaceXS = 4;
  static const double spaceSM = 8;
  static const double spaceMD = 16;
  static const double spaceLG = 24;
  static const double spaceXL = 32;
  static const double space2XL = 48;

  // Border Radius
  static const double radiusSM = 8;
  static const double radiusMD = 12;
  static const double radiusLG = 16;

  // Typography
  static const TextStyle headingLarge = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.bold,
    color: textPrimary,
    height: 1.2,
  );

  static const TextStyle headingMedium = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: textPrimary,
    height: 1.3,
  );

  static const TextStyle headingSmall = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: textPrimary,
    height: 1.3,
  );

  static const TextStyle bodyLarge = TextStyle(
    fontSize: 16,
    color: textPrimary,
    height: 1.5,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontSize: 14,
    color: textPrimary,
    height: 1.5,
  );

  static const TextStyle bodySmall = TextStyle(
    fontSize: 12,
    color: textSecondary,
    height: 1.4,
  );

  static const TextStyle caption = TextStyle(
    fontSize: 12,
    color: textSecondary,
    height: 1.4,
    fontWeight: FontWeight.w500,
  );

  static const TextStyle buttonText = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.5,
  );

  // ── Dark Mode Colors ───────────────────────────────────────
  static const Color darkBackground = Color(0xFF0F172A); // Slate 900
  static const Color darkSurface = Color(0xFF1E293B); // Slate 800
  static const Color darkCard = Color(0xFF1E293B); // Slate 800
  static const Color darkDivider = Color(0xFF334155); // Slate 700
  static const Color darkTextPrimary = Color(0xFFF1F5F9); // Slate 100
  static const Color darkTextSecondary = Color(0xFF94A3B8); // Slate 400

  // ── Page Transitions ────────────────────────────────────────
  static const PageTransitionsTheme _pageTransitions = PageTransitionsTheme(
    builders: {
      TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
      TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
    },
  );

  // Material Theme Configuration
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      fontFamily: 'Roboto',
      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        brightness: Brightness.light,
        primary: primary,
        secondary: primaryDark,
        tertiary: accent,
        surface: background,
        error: error,
      ),
      scaffoldBackgroundColor: background,
      pageTransitionsTheme: _pageTransitions,
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        backgroundColor: primary,
        foregroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: Colors.white,
          letterSpacing: 0.15,
        ),
      ),
      cardTheme: CardThemeData(
        color: cardBackground,
        elevation: 3,
        shadowColor: Colors.black.withValues(alpha: 0.10),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLG),
        ),
        margin: const EdgeInsets.symmetric(
          horizontal: spaceMD,
          vertical: spaceSM,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 1,
          shadowColor: primary.withValues(alpha: 0.2),
          backgroundColor: primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(
            horizontal: spaceLG,
            vertical: spaceMD,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMD),
          ),
          textStyle: buttonText,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(
            horizontal: spaceLG,
            vertical: spaceMD,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMD),
          ),
          textStyle: buttonText,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primary,
          padding: const EdgeInsets.symmetric(
            horizontal: spaceLG,
            vertical: spaceMD,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMD),
          ),
          side: const BorderSide(color: primary, width: 1.5),
          textStyle: buttonText,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceLight,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: spaceMD,
          vertical: spaceMD,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusSM),
          borderSide: const BorderSide(color: divider),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusSM),
          borderSide: const BorderSide(color: divider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusSM),
          borderSide: const BorderSide(color: primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusSM),
          borderSide: const BorderSide(color: error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusSM),
          borderSide: const BorderSide(color: error, width: 2),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: divider,
        thickness: 1,
        space: 1,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: primaryLight,
        labelStyle: const TextStyle(fontSize: 14, color: primaryDark),
        padding: const EdgeInsets.symmetric(
          horizontal: spaceMD,
          vertical: spaceSM,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusSM),
        ),
        side: BorderSide(color: primary.withValues(alpha: 0.2)),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusSM),
        ),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: primary,
        linearTrackColor: surfaceLight,
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: primary,
        inactiveTrackColor: primary.withValues(alpha: 0.15),
        thumbColor: primary,
        overlayColor: primary.withValues(alpha: 0.1),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return primary;
          return Colors.transparent;
        }),
        checkColor: WidgetStateProperty.all(Colors.white),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
        ),
      ),
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return primary;
          return textSecondary;
        }),
      ),
      navigationBarTheme: NavigationBarThemeData(
        elevation: 2,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.black12,
        indicatorColor: primary.withValues(alpha: 0.12),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: primary, size: 28);
          }
          return const IconThemeData(color: textSecondary, size: 26);
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const TextStyle(
              color: primary,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            );
          }
          return const TextStyle(
            color: textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          );
        }),
        height: 72,
      ),
    );
  }

  // ── Dark Theme ─────────────────────────────────────────────
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      fontFamily: 'Roboto',
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        brightness: Brightness.dark,
        primary: const Color(0xFF2DD4BF), // Teal 400 — brighter for dark bg
        secondary: const Color(0xFF5EEAD4), // Teal 300
        tertiary: const Color(0xFFFBBF24), // Amber 400
        surface: darkSurface,
        error: const Color(0xFFFB7185), // Rose 400
      ),
      scaffoldBackgroundColor: darkBackground,
      pageTransitionsTheme: _pageTransitions,
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        backgroundColor: Colors.transparent,
        foregroundColor: darkTextPrimary,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: darkTextPrimary,
          letterSpacing: 0.15,
        ),
      ),
      cardTheme: CardThemeData(
        color: darkCard,
        elevation: 4,
        shadowColor: Colors.black.withValues(alpha: 0.3),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLG),
        ),
        margin: const EdgeInsets.symmetric(
          horizontal: spaceMD,
          vertical: spaceSM,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 2,
          shadowColor: Colors.black.withValues(alpha: 0.3),
          backgroundColor: const Color(0xFF2DD4BF),
          foregroundColor: darkBackground,
          padding: const EdgeInsets.symmetric(
            horizontal: spaceLG,
            vertical: spaceMD,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMD),
          ),
          textStyle: buttonText,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: const Color(0xFF2DD4BF),
          foregroundColor: darkBackground,
          padding: const EdgeInsets.symmetric(
            horizontal: spaceLG,
            vertical: spaceMD,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMD),
          ),
          textStyle: buttonText,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFF2DD4BF),
          padding: const EdgeInsets.symmetric(
            horizontal: spaceLG,
            vertical: spaceMD,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMD),
          ),
          side: const BorderSide(color: Color(0xFF2DD4BF), width: 1.5),
          textStyle: buttonText,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: darkSurface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: spaceMD,
          vertical: spaceMD,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusSM),
          borderSide: const BorderSide(color: darkDivider),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusSM),
          borderSide: const BorderSide(color: darkDivider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusSM),
          borderSide: const BorderSide(color: Color(0xFF2DD4BF), width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusSM),
          borderSide: const BorderSide(color: Color(0xFFFB7185)),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusSM),
          borderSide: const BorderSide(color: Color(0xFFFB7185), width: 2),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: darkDivider,
        thickness: 1,
        space: 1,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: const Color(0xFF134E4A), // Teal 900
        labelStyle: const TextStyle(fontSize: 14, color: Color(0xFF5EEAD4)),
        padding: const EdgeInsets.symmetric(
          horizontal: spaceMD,
          vertical: spaceSM,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusSM),
        ),
        side: BorderSide(color: const Color(0xFF2DD4BF).withValues(alpha: 0.3)),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusSM),
        ),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: Color(0xFF2DD4BF),
        linearTrackColor: darkSurface,
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: const Color(0xFF2DD4BF),
        inactiveTrackColor: const Color(0xFF2DD4BF).withValues(alpha: 0.2),
        thumbColor: const Color(0xFF2DD4BF),
        overlayColor: const Color(0xFF2DD4BF).withValues(alpha: 0.1),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const Color(0xFF2DD4BF);
          }
          return Colors.transparent;
        }),
        checkColor: WidgetStateProperty.all(darkBackground),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
        ),
      ),
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const Color(0xFF2DD4BF);
          }
          return darkTextSecondary;
        }),
      ),
      navigationBarTheme: NavigationBarThemeData(
        elevation: 2,
        backgroundColor: darkSurface,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.black26,
        indicatorColor: const Color(0xFF2DD4BF).withValues(alpha: 0.15),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: Color(0xFF2DD4BF), size: 28);
          }
          return const IconThemeData(color: darkTextSecondary, size: 26);
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const TextStyle(
              color: Color(0xFF2DD4BF),
              fontSize: 13,
              fontWeight: FontWeight.w600,
            );
          }
          return const TextStyle(
            color: darkTextSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          );
        }),
        height: 72,
      ),
    );
  }

  // Helper: Get stress color by category
  static Color getStressColor(String category) {
    switch (category.toLowerCase()) {
      case 'low':
        return stressLow;
      case 'mild':
        return stressMild;
      case 'moderate':
        return stressModerate;
      case 'high':
        return stressHigh;
      case 'severe':
        return stressSevere;
      default:
        return textSecondary;
    }
  }

  // Helper: Get stress color by score (PSS-10: 0-40)
  static Color getStressColorByScore(int score) {
    if (score <= 13) return stressLow;
    if (score <= 19) return stressMild;
    if (score <= 26) return stressModerate;
    if (score <= 33) return stressHigh;
    return stressSevere;
  }
}
