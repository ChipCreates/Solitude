import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:solitude/features/settings/models/theme_preset.dart';
import 'package:solitude/features/settings/services/settings_provider.dart';

// Color palette for the app
class AppColors {
  // Felt table colors (green)
  static const feltDarkest = Color(0xFF1E4A1A);
  static const feltDark = Color(0xFF2D5A27);
  static const feltMedium = Color(0xFF3D7A37);
  static const feltLight = Color(0xFF4A8B3C);

  // Accents
  static const gold = Color(0xFFD4AF37);
  static const goldMuted = Color(0xFFB8963A);
  static const cream = Color(0xFFFFFDD0);
  static const white = Color(0xFFFFFFF8);

  // Card colors
  static const cardFace = Color(0xFFFFFFF8);
  static const cardBorder = Color(0xFF333333);
  static const cardShadow = Color(0x40000000);

  // Feedback
  static const validMove = Color(0xFF90EE90);
  static const invalidMove = Color(0xFFFF6B6B);

  // UI elements
  static const textLight = Color(0xFFFFFFF8);
  static const textDark = Color(0xFF1A1A1A);
  static const textMuted = Color(0xFFCCCCCC);

  // Shadows
  static const shadowLight = Color(0x25000000);
  static const shadowMedium = Color(0x40000000);
  static const shadowDark = Color(0x60000000);
}

class AppTheme {
  /// Generate a light theme based on a ThemePreset
  static ThemeData light([ThemePreset? preset]) {
    final theme = preset ?? ThemePreset.defaultTheme;

    return ThemeData(
      useMaterial3: true,
      fontFamily: 'Inter',
      scaffoldBackgroundColor: theme.tableColorLight,
      colorScheme: ColorScheme.light(
        primary: theme.accentColor,
        secondary: theme.accentMuted,
        surface: theme.tableColorLight,
      ),
    );
  }

  /// Generate a dark theme based on a ThemePreset
  static ThemeData dark([ThemePreset? preset]) {
    final theme = preset ?? ThemePreset.defaultTheme;

    return ThemeData(
      useMaterial3: true,
      fontFamily: 'Inter',
      scaffoldBackgroundColor: theme.tableColorDark,
      colorScheme: ColorScheme.dark(
        primary: theme.accentColor,
        secondary: theme.accentMuted,
        surface: theme.tableColorDark,
      ),
    );
  }

  // Context-aware color getters
  static Color backgroundColor(BuildContext context) {
    return Theme.of(context).scaffoldBackgroundColor;
  }

  static Color toolbarColor(BuildContext context) {
    try {
      final settings = Provider.of<SettingsProvider>(context, listen: false);
      return settings.currentTheme
          .getToolbarColor(Theme.of(context).brightness);
    } catch (_) {
      return Theme.of(context).colorScheme.primary;
    }
  }

  static Color textColor(BuildContext context) {
    return AppColors.textLight;
  }

  static Color mutedTextColor(BuildContext context) {
    return AppColors.textMuted;
  }

  static Color buttonColor(BuildContext context) {
    final accent = Theme.of(context).colorScheme.secondary;
    return Theme.of(context).brightness == Brightness.dark
        ? accent.withValues(alpha: 0.18)
        : accent.withValues(alpha: 0.12);
  }

  static Color buttonBorderColor(BuildContext context) {
    return Theme.of(context).colorScheme.secondary.withValues(alpha: 0.35);
  }

  static Color accentColor(BuildContext context) {
    return Theme.of(context).colorScheme.secondary;
  }

  static Color emptyPileColor(BuildContext context) {
    return AppColors.cream.withValues(alpha: 0.2);
  }

  static Color highlightColor(BuildContext context) {
    return AppColors.validMove.withValues(alpha: 0.5);
  }

  static Color cardFaceColor(BuildContext context) {
    return AppColors.cardFace;
  }

  static Color cardBackColor(BuildContext context) {
    try {
      final settings = Provider.of<SettingsProvider>(context, listen: false);
      if (settings.cardBackColored) {
        final hex = settings.cardBackColor.replaceFirst('#', 'FF');
        final color = Color(int.parse(hex, radix: 16));
        return color;
      }
      final theme = settings.currentTheme;
      return theme.suggestedBackColors(Theme.of(context).brightness).first;
    } catch (_) {
      return AppColors.feltMedium;
    }
  }

  static Color cardBorderColor(BuildContext context) {
    return AppColors.cardBorder;
  }
}

class AppTypography {
  static const String fontFamily = 'Inter';

  static TextStyle heading(BuildContext context) => TextStyle(
        fontFamily: fontFamily,
        fontSize: 22,
        fontWeight: FontWeight.w600,
        color: AppTheme.textColor(context),
        letterSpacing: 0.5,
      );

  static TextStyle subheading(BuildContext context) => TextStyle(
        fontFamily: fontFamily,
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: AppTheme.textColor(context),
      );

  static TextStyle label(BuildContext context) => TextStyle(
        fontFamily: fontFamily,
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: AppTheme.textColor(context),
      );

  static TextStyle body(BuildContext context) => TextStyle(
        fontFamily: fontFamily,
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: AppTheme.textColor(context),
      );

  static TextStyle caption(BuildContext context) => TextStyle(
        fontFamily: fontFamily,
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: AppTheme.mutedTextColor(context),
      );

  static TextStyle button(BuildContext context) => TextStyle(
        fontFamily: fontFamily,
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: AppTheme.textColor(context),
        letterSpacing: 0.5,
      );

  static TextStyle stat(BuildContext context) => caption(context);

  static TextStyle statValue(BuildContext context) => body(context);
}
