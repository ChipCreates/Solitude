import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:solitude/theme/app_theme.dart';
import 'package:solitude/models/theme_preset.dart';

void main() {
  group('AppColors', () {
    test('has defined felt colors', () {
      expect(AppColors.feltDarkest, const Color(0xFF1E4A1A));
      expect(AppColors.feltDark, const Color(0xFF2D5A27));
      expect(AppColors.feltMedium, const Color(0xFF3D7A37));
      expect(AppColors.feltLight, const Color(0xFF4A8B3C));
    });

    test('has defined accent colors', () {
      expect(AppColors.gold, const Color(0xFFD4AF37));
      expect(AppColors.goldMuted, const Color(0xFFB8963A));
      expect(AppColors.cream, const Color(0xFFFFFDD0));
      expect(AppColors.white, const Color(0xFFFFFFF8));
    });

    test('has defined card colors', () {
      expect(AppColors.cardFace, const Color(0xFFFFFFF8));
      expect(AppColors.cardBorder, const Color(0xFF333333));
      expect(AppColors.cardShadow, const Color(0x40000000));
    });

    test('has defined feedback colors', () {
      expect(AppColors.validMove, const Color(0xFF90EE90));
      expect(AppColors.invalidMove, const Color(0xFFFF6B6B));
    });

    test('has defined text colors', () {
      expect(AppColors.textLight, const Color(0xFFFFFFF8));
      expect(AppColors.textDark, const Color(0xFF1A1A1A));
      expect(AppColors.textMuted, const Color(0xFFCCCCCC));
    });

    test('has defined shadow colors', () {
      expect(AppColors.shadowLight, const Color(0x25000000));
      expect(AppColors.shadowMedium, const Color(0x40000000));
      expect(AppColors.shadowDark, const Color(0x60000000));
    });

    test('felt colors are shades of green', () {
      // All felt colors should have more green than red or blue
      expect(AppColors.feltDarkest.g, greaterThan(AppColors.feltDarkest.r));
      expect(AppColors.feltDark.g, greaterThan(AppColors.feltDark.r));
      expect(AppColors.feltMedium.g, greaterThan(AppColors.feltMedium.r));
      expect(AppColors.feltLight.g, greaterThan(AppColors.feltLight.r));
    });

    test('shadow colors have transparency', () {
      expect(AppColors.shadowLight.a, lessThan(1.0));
      expect(AppColors.shadowMedium.a, lessThan(1.0));
      expect(AppColors.shadowDark.a, lessThan(1.0));
    });

    test('cardShadow has transparency', () {
      expect(AppColors.cardShadow.a, lessThan(1.0));
    });
  });

  group('AppTheme.light()', () {
    test('creates a light theme with default preset', () {
      final theme = AppTheme.light();

      expect(theme, isNotNull);
      expect(theme.brightness, Brightness.light);
      expect(theme.useMaterial3, isTrue);
    });

    test('uses Inter font family', () {
      final theme = AppTheme.light();
      expect(theme.textTheme.bodyLarge?.fontFamily, 'Inter');
    });

    test('uses default theme when no preset provided', () {
      final theme = AppTheme.light();
      expect(theme.scaffoldBackgroundColor, ThemePreset.defaultTheme.tableColorLight);
    });

    test('uses provided preset for colors', () {
      final theme = AppTheme.light(ThemePreset.royalBlue);

      expect(theme.scaffoldBackgroundColor, ThemePreset.royalBlue.tableColorLight);
      expect(theme.colorScheme.primary, ThemePreset.royalBlue.accentColor);
      expect(theme.colorScheme.secondary, ThemePreset.royalBlue.accentMuted);
      expect(theme.colorScheme.surface, ThemePreset.royalBlue.tableColorLight);
    });

    test('creates theme for each built-in preset', () {
      for (final preset in ThemePreset.builtInThemes) {
        final theme = AppTheme.light(preset);
        expect(theme, isNotNull);
        expect(theme.scaffoldBackgroundColor, preset.tableColorLight);
      }
    });

    test('has light brightness', () {
      final theme = AppTheme.light();
      expect(theme.brightness, Brightness.light);
    });

    test('has Material 3 enabled', () {
      final theme = AppTheme.light();
      expect(theme.useMaterial3, isTrue);
    });
  });

  group('AppTheme.dark()', () {
    test('creates a dark theme with default preset', () {
      final theme = AppTheme.dark();

      expect(theme, isNotNull);
      expect(theme.brightness, Brightness.dark);
      expect(theme.useMaterial3, isTrue);
    });

    test('uses Inter font family', () {
      final theme = AppTheme.dark();
      expect(theme.textTheme.bodyLarge?.fontFamily, 'Inter');
    });

    test('uses default theme when no preset provided', () {
      final theme = AppTheme.dark();
      expect(theme.scaffoldBackgroundColor, ThemePreset.defaultTheme.tableColorDark);
    });

    test('uses provided preset for colors', () {
      final theme = AppTheme.dark(ThemePreset.midnightBlack);

      expect(theme.scaffoldBackgroundColor, ThemePreset.midnightBlack.tableColorDark);
      expect(theme.colorScheme.primary, ThemePreset.midnightBlack.accentColor);
      expect(theme.colorScheme.secondary, ThemePreset.midnightBlack.accentMuted);
      expect(theme.colorScheme.surface, ThemePreset.midnightBlack.tableColorDark);
    });

    test('creates theme for each built-in preset', () {
      for (final preset in ThemePreset.builtInThemes) {
        final theme = AppTheme.dark(preset);
        expect(theme, isNotNull);
        expect(theme.scaffoldBackgroundColor, preset.tableColorDark);
      }
    });

    test('has dark brightness', () {
      final theme = AppTheme.dark();
      expect(theme.brightness, Brightness.dark);
    });

    test('has Material 3 enabled', () {
      final theme = AppTheme.dark();
      expect(theme.useMaterial3, isTrue);
    });
  });

  group('AppTheme Light vs Dark', () {
    test('light and dark themes have different background colors', () {
      final lightTheme = AppTheme.light();
      final darkTheme = AppTheme.dark();

      expect(lightTheme.scaffoldBackgroundColor, isNot(darkTheme.scaffoldBackgroundColor));
    });

    test('light and dark themes use same preset colors for accents', () {
      const preset = ThemePreset.royalBlue;
      final lightTheme = AppTheme.light(preset);
      final darkTheme = AppTheme.dark(preset);

      expect(lightTheme.colorScheme.primary, darkTheme.colorScheme.primary);
      expect(lightTheme.colorScheme.secondary, darkTheme.colorScheme.secondary);
    });

    test('light and dark themes use different surface colors', () {
      const preset = ThemePreset.burgundyVelvet;
      final lightTheme = AppTheme.light(preset);
      final darkTheme = AppTheme.dark(preset);

      expect(lightTheme.colorScheme.surface, preset.tableColorLight);
      expect(darkTheme.colorScheme.surface, preset.tableColorDark);
      expect(lightTheme.colorScheme.surface, isNot(darkTheme.colorScheme.surface));
    });

    test('both themes have Material 3 enabled', () {
      final lightTheme = AppTheme.light();
      final darkTheme = AppTheme.dark();

      expect(lightTheme.useMaterial3, isTrue);
      expect(darkTheme.useMaterial3, isTrue);
    });

    test('both themes use Inter font', () {
      final lightTheme = AppTheme.light();
      final darkTheme = AppTheme.dark();

      expect(lightTheme.textTheme.bodyLarge?.fontFamily, 'Inter');
      expect(darkTheme.textTheme.bodyLarge?.fontFamily, 'Inter');
    });
  });

  group('AppTypography', () {
    test('has Inter font family constant', () {
      expect(AppTypography.fontFamily, 'Inter');
    });

    // Note: Typography methods require BuildContext, so they need widget tests
    // These tests just verify the structure exists
    test('has all typography methods', () {
      expect(AppTypography.heading, isNotNull);
      expect(AppTypography.subheading, isNotNull);
      expect(AppTypography.label, isNotNull);
      expect(AppTypography.body, isNotNull);
      expect(AppTypography.caption, isNotNull);
      expect(AppTypography.button, isNotNull);
      expect(AppTypography.stat, isNotNull);
      expect(AppTypography.statValue, isNotNull);
    });
  });

  group('Theme Consistency', () {
    test('all presets produce valid light themes', () {
      for (final preset in ThemePreset.builtInThemes) {
        final theme = AppTheme.light(preset);
        expect(theme.useMaterial3, isTrue);
        expect(theme.textTheme.bodyLarge?.fontFamily, 'Inter');
        expect(theme.brightness, Brightness.light);
        expect(theme.scaffoldBackgroundColor, isNotNull);
      }
    });

    test('all presets produce valid dark themes', () {
      for (final preset in ThemePreset.builtInThemes) {
        final theme = AppTheme.dark(preset);
        expect(theme.useMaterial3, isTrue);
        expect(theme.textTheme.bodyLarge?.fontFamily, 'Inter');
        expect(theme.brightness, Brightness.dark);
        expect(theme.scaffoldBackgroundColor, isNotNull);
      }
    });

    test('themes can be created multiple times consistently', () {
      final theme1 = AppTheme.light(ThemePreset.classicGreen);
      final theme2 = AppTheme.light(ThemePreset.classicGreen);

      expect(theme1.scaffoldBackgroundColor, theme2.scaffoldBackgroundColor);
      expect(theme1.colorScheme.primary, theme2.colorScheme.primary);
      expect(theme1.textTheme.bodyLarge?.fontFamily, theme2.textTheme.bodyLarge?.fontFamily);
    });
  });
}
