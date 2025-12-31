import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:solitude/features/settings/models/theme_preset.dart';

void main() {
  group('ThemePreset Construction', () {
    test('can be constructed with required parameters', () {
      const theme = ThemePreset(
        id: 'test_theme',
        name: 'Test Theme',
        description: 'A test theme',
        tableColorLight: Color(0xFF4A8B3C),
        tableColorDark: Color(0xFF2D5A27),
        toolbarColorLight: Color(0xFF3D7A37),
        toolbarColorDark: Color(0xFF1E4A1A),
        accentColor: Color(0xFFD4AF37),
        accentMuted: Color(0xFFB8963A),
        cardFaceOverlay: Color(0xFFFFFFF8),
      );

      expect(theme.id, 'test_theme');
      expect(theme.name, 'Test Theme');
      expect(theme.description, 'A test theme');
      expect(theme.tableColorLight, const Color(0xFF4A8B3C));
      expect(theme.tableColorDark, const Color(0xFF2D5A27));
      expect(theme.toolbarColorLight, const Color(0xFF3D7A37));
      expect(theme.toolbarColorDark, const Color(0xFF1E4A1A));
      expect(theme.accentColor, const Color(0xFFD4AF37));
      expect(theme.accentMuted, const Color(0xFFB8963A));
      expect(theme.cardFaceOverlay, const Color(0xFFFFFFF8));
    });

    test('uses default values for optional parameters', () {
      const theme = ThemePreset(
        id: 'test',
        name: 'Test',
        description: 'Test',
        tableColorLight: Color(0xFF000000),
        tableColorDark: Color(0xFF000000),
        toolbarColorLight: Color(0xFF000000),
        toolbarColorDark: Color(0xFF000000),
        accentColor: Color(0xFF000000),
        accentMuted: Color(0xFF000000),
        cardFaceOverlay: Color(0xFF000000),
      );

      expect(theme.defaultOverlayIntensity, 0.5);
      expect(theme.overlayBlendMode, BlendMode.modulate);
      expect(theme.textLight, const Color(0xFFFFFFF8));
      expect(theme.textMuted, const Color(0xFFCCCCCC));
      expect(theme.isBuiltIn, isTrue);
    });

    test('can override optional parameters', () {
      const theme = ThemePreset(
        id: 'custom',
        name: 'Custom',
        description: 'Custom',
        tableColorLight: Color(0xFF000000),
        tableColorDark: Color(0xFF000000),
        toolbarColorLight: Color(0xFF000000),
        toolbarColorDark: Color(0xFF000000),
        accentColor: Color(0xFF000000),
        accentMuted: Color(0xFF000000),
        cardFaceOverlay: Color(0xFF000000),
        defaultOverlayIntensity: 0.3,
        overlayBlendMode: BlendMode.multiply,
        textLight: Color(0xFF123456),
        textMuted: Color(0xFF654321),
        isBuiltIn: false,
      );

      expect(theme.defaultOverlayIntensity, 0.3);
      expect(theme.overlayBlendMode, BlendMode.multiply);
      expect(theme.textLight, const Color(0xFF123456));
      expect(theme.textMuted, const Color(0xFF654321));
      expect(theme.isBuiltIn, isFalse);
    });
  });

  group('ThemePreset.getTableColor()', () {
    const theme = ThemePreset(
      id: 'test',
      name: 'Test',
      description: 'Test',
      tableColorLight: Color(0xFFAABBCC),
      tableColorDark: Color(0xFF112233),
      toolbarColorLight: Color(0xFF000000),
      toolbarColorDark: Color(0xFF000000),
      accentColor: Color(0xFF000000),
      accentMuted: Color(0xFF000000),
      cardFaceOverlay: Color(0xFF000000),
    );

    test('returns light color for light brightness', () {
      expect(theme.getTableColor(Brightness.light), const Color(0xFFAABBCC));
    });

    test('returns dark color for dark brightness', () {
      expect(theme.getTableColor(Brightness.dark), const Color(0xFF112233));
    });
  });

  group('ThemePreset.getToolbarColor()', () {
    const theme = ThemePreset(
      id: 'test',
      name: 'Test',
      description: 'Test',
      tableColorLight: Color(0xFF000000),
      tableColorDark: Color(0xFF000000),
      toolbarColorLight: Color(0xFFDDEEFF),
      toolbarColorDark: Color(0xFF445566),
      accentColor: Color(0xFF000000),
      accentMuted: Color(0xFF000000),
      cardFaceOverlay: Color(0xFF000000),
    );

    test('returns light color for light brightness', () {
      expect(theme.getToolbarColor(Brightness.light), const Color(0xFFDDEEFF));
    });

    test('returns dark color for dark brightness', () {
      expect(theme.getToolbarColor(Brightness.dark), const Color(0xFF445566));
    });
  });

  group('ThemePreset.suggestedBackColors()', () {
    const theme = ThemePreset(
      id: 'test',
      name: 'Test',
      description: 'Test',
      tableColorLight: Color(0xFF111111),
      tableColorDark: Color(0xFF222222),
      toolbarColorLight: Color(0xFF333333),
      toolbarColorDark: Color(0xFF444444),
      accentColor: Color(0xFFAAAAAA),
      accentMuted: Color(0xFFBBBBBB),
      cardFaceOverlay: Color(0xFF000000),
    );

    test('returns list of suggested colors', () {
      final colors = theme.suggestedBackColors(Brightness.light);
      expect(colors, isA<List<Color>>());
      expect(colors.length, 4);
    });

    test('includes accent colors first', () {
      final colors = theme.suggestedBackColors(Brightness.light);
      expect(colors[0], theme.accentColor);
      expect(colors[1], theme.accentMuted);
    });

    test('includes toolbar color for given brightness', () {
      final lightColors = theme.suggestedBackColors(Brightness.light);
      expect(lightColors[2], theme.getToolbarColor(Brightness.light));

      final darkColors = theme.suggestedBackColors(Brightness.dark);
      expect(darkColors[2], theme.getToolbarColor(Brightness.dark));
    });

    test('includes tableColorDark as fallback', () {
      final colors = theme.suggestedBackColors(Brightness.light);
      expect(colors[3], theme.tableColorDark);
    });
  });

  group('ThemePreset Equality', () {
    test('themes with same id are equal', () {
      const theme1 = ThemePreset(
        id: 'same_id',
        name: 'Theme 1',
        description: 'First',
        tableColorLight: Color(0xFF000000),
        tableColorDark: Color(0xFF000000),
        toolbarColorLight: Color(0xFF000000),
        toolbarColorDark: Color(0xFF000000),
        accentColor: Color(0xFF000000),
        accentMuted: Color(0xFF000000),
        cardFaceOverlay: Color(0xFF000000),
      );

      const theme2 = ThemePreset(
        id: 'same_id',
        name: 'Theme 2',
        description: 'Second',
        tableColorLight: Color(0xFFFFFFFF),
        tableColorDark: Color(0xFFFFFFFF),
        toolbarColorLight: Color(0xFFFFFFFF),
        toolbarColorDark: Color(0xFFFFFFFF),
        accentColor: Color(0xFFFFFFFF),
        accentMuted: Color(0xFFFFFFFF),
        cardFaceOverlay: Color(0xFFFFFFFF),
      );

      expect(theme1, theme2);
      expect(theme1.hashCode, theme2.hashCode);
    });

    test('themes with different ids are not equal', () {
      const theme1 = ThemePreset(
        id: 'id_1',
        name: 'Same Name',
        description: 'Same Description',
        tableColorLight: Color(0xFF000000),
        tableColorDark: Color(0xFF000000),
        toolbarColorLight: Color(0xFF000000),
        toolbarColorDark: Color(0xFF000000),
        accentColor: Color(0xFF000000),
        accentMuted: Color(0xFF000000),
        cardFaceOverlay: Color(0xFF000000),
      );

      const theme2 = ThemePreset(
        id: 'id_2',
        name: 'Same Name',
        description: 'Same Description',
        tableColorLight: Color(0xFF000000),
        tableColorDark: Color(0xFF000000),
        toolbarColorLight: Color(0xFF000000),
        toolbarColorDark: Color(0xFF000000),
        accentColor: Color(0xFF000000),
        accentMuted: Color(0xFF000000),
        cardFaceOverlay: Color(0xFF000000),
      );

      expect(theme1, isNot(theme2));
      expect(theme1.hashCode, isNot(theme2.hashCode));
    });

    test('theme equals itself', () {
      const theme = ThemePreset.classicGreen;
      expect(theme, theme);
    });
  });

  group('Built-in Themes', () {
    test('classicGreen has correct properties', () {
      expect(ThemePreset.classicGreen.id, 'classic_green');
      expect(ThemePreset.classicGreen.name, 'Classic Felt');
      expect(ThemePreset.classicGreen.description, isNotEmpty);
      expect(ThemePreset.classicGreen.defaultOverlayIntensity, 0.0);
      expect(ThemePreset.classicGreen.isBuiltIn, isTrue);
    });

    test('royalBlue has correct properties', () {
      expect(ThemePreset.royalBlue.id, 'royal_blue');
      expect(ThemePreset.royalBlue.name, 'Royal Blue');
      expect(ThemePreset.royalBlue.defaultOverlayIntensity, 0.0);
    });

    test('burgundyVelvet has correct properties', () {
      expect(ThemePreset.burgundyVelvet.id, 'burgundy_velvet');
      expect(ThemePreset.burgundyVelvet.name, 'Burgundy Velvet');
      expect(ThemePreset.burgundyVelvet.defaultOverlayIntensity, 0.25);
    });

    test('midnightBlack has correct properties', () {
      expect(ThemePreset.midnightBlack.id, 'midnight_black');
      expect(ThemePreset.midnightBlack.name, 'Midnight');
      expect(ThemePreset.midnightBlack.defaultOverlayIntensity, 0.2);
    });

    test('oceanTeal has correct properties', () {
      expect(ThemePreset.oceanTeal.id, 'ocean_teal');
      expect(ThemePreset.oceanTeal.name, 'Ocean Teal');
      expect(ThemePreset.oceanTeal.defaultOverlayIntensity, 0.2);
    });

    test('sunsetAmber has correct properties', () {
      expect(ThemePreset.sunsetAmber.id, 'sunset_amber');
      expect(ThemePreset.sunsetAmber.name, 'Sunset Amber');
      expect(ThemePreset.sunsetAmber.defaultOverlayIntensity, 0.2);
    });

    test('slateGray has correct properties', () {
      expect(ThemePreset.slateGray.id, 'slate_gray');
      expect(ThemePreset.slateGray.name, 'Slate Gray');
      expect(ThemePreset.slateGray.defaultOverlayIntensity, 0.2);
    });

    test('plumRoyale has correct properties', () {
      expect(ThemePreset.plumRoyale.id, 'plum_royale');
      expect(ThemePreset.plumRoyale.name, 'Plum Royale');
      expect(ThemePreset.plumRoyale.defaultOverlayIntensity, 0.2);
    });

    test('all built-in themes have unique ids', () {
      final ids = ThemePreset.builtInThemes.map((t) => t.id).toList();
      final uniqueIds = ids.toSet();
      expect(ids.length, uniqueIds.length);
    });

    test('all built-in themes have unique names', () {
      final names = ThemePreset.builtInThemes.map((t) => t.name).toList();
      final uniqueNames = names.toSet();
      expect(names.length, uniqueNames.length);
    });

    test('all built-in themes are marked as built-in', () {
      for (final theme in ThemePreset.builtInThemes) {
        expect(theme.isBuiltIn, isTrue);
      }
    });

    test('all built-in themes have non-empty descriptions', () {
      for (final theme in ThemePreset.builtInThemes) {
        expect(theme.description, isNotEmpty);
      }
    });

    test('all built-in themes have valid overlay intensities', () {
      for (final theme in ThemePreset.builtInThemes) {
        expect(theme.defaultOverlayIntensity, greaterThanOrEqualTo(0.0));
        expect(theme.defaultOverlayIntensity, lessThanOrEqualTo(1.0));
      }
    });
  });

  group('ThemePreset.builtInThemes', () {
    test('contains 8 themes', () {
      expect(ThemePreset.builtInThemes.length, 8);
    });

    test('contains all expected themes', () {
      expect(ThemePreset.builtInThemes, contains(ThemePreset.classicGreen));
      expect(ThemePreset.builtInThemes, contains(ThemePreset.royalBlue));
      expect(ThemePreset.builtInThemes, contains(ThemePreset.burgundyVelvet));
      expect(ThemePreset.builtInThemes, contains(ThemePreset.midnightBlack));
      expect(ThemePreset.builtInThemes, contains(ThemePreset.oceanTeal));
      expect(ThemePreset.builtInThemes, contains(ThemePreset.sunsetAmber));
      expect(ThemePreset.builtInThemes, contains(ThemePreset.slateGray));
      expect(ThemePreset.builtInThemes, contains(ThemePreset.plumRoyale));
    });

    test('classicGreen is first in list', () {
      expect(ThemePreset.builtInThemes.first, ThemePreset.classicGreen);
    });
  });

  group('ThemePreset.findById()', () {
    test('finds existing theme by id', () {
      final found = ThemePreset.findById('classic_green');
      expect(found, ThemePreset.classicGreen);
    });

    test('finds all built-in themes by their ids', () {
      for (final theme in ThemePreset.builtInThemes) {
        final found = ThemePreset.findById(theme.id);
        expect(found, theme);
      }
    });

    test('returns null for non-existent id', () {
      final found = ThemePreset.findById('non_existent_theme');
      expect(found, isNull);
    });

    test('returns null for empty string', () {
      final found = ThemePreset.findById('');
      expect(found, isNull);
    });

    test('is case-sensitive', () {
      final found = ThemePreset.findById('CLASSIC_GREEN');
      expect(found, isNull);
    });
  });

  group('ThemePreset.defaultTheme', () {
    test('returns classicGreen', () {
      expect(ThemePreset.defaultTheme, ThemePreset.classicGreen);
    });

    test('is included in builtInThemes', () {
      expect(ThemePreset.builtInThemes, contains(ThemePreset.defaultTheme));
    });
  });

  group('Theme Color Validation', () {
    test('all themes have distinct table colors for light and dark', () {
      for (final theme in ThemePreset.builtInThemes) {
        expect(theme.tableColorLight, isNot(theme.tableColorDark));
      }
    });

    test('all themes have distinct toolbar colors for light and dark', () {
      for (final theme in ThemePreset.builtInThemes) {
        expect(theme.toolbarColorLight, isNot(theme.toolbarColorDark));
      }
    });

    test('all themes have accent colors defined', () {
      for (final theme in ThemePreset.builtInThemes) {
        expect(theme.accentColor, isNotNull);
        expect(theme.accentMuted, isNotNull);
      }
    });

    test('all themes have card face overlay defined', () {
      for (final theme in ThemePreset.builtInThemes) {
        expect(theme.cardFaceOverlay, isNotNull);
      }
    });
  });

  group('Theme Integration', () {
    test('can get colors for both brightness modes', () {
      for (final theme in ThemePreset.builtInThemes) {
        expect(theme.getTableColor(Brightness.light), isNotNull);
        expect(theme.getTableColor(Brightness.dark), isNotNull);
        expect(theme.getToolbarColor(Brightness.light), isNotNull);
        expect(theme.getToolbarColor(Brightness.dark), isNotNull);
      }
    });

    test('can get suggested back colors for both brightness modes', () {
      for (final theme in ThemePreset.builtInThemes) {
        final lightColors = theme.suggestedBackColors(Brightness.light);
        final darkColors = theme.suggestedBackColors(Brightness.dark);

        expect(lightColors, isNotEmpty);
        expect(darkColors, isNotEmpty);
      }
    });

    test('suggested back colors differ by brightness for some themes', () {
      // At least check that the method responds to brightness parameter
      const theme = ThemePreset.royalBlue;
      final lightSuggestions = theme.suggestedBackColors(Brightness.light);
      final darkSuggestions = theme.suggestedBackColors(Brightness.dark);

      // The third element should differ (toolbar color)
      expect(lightSuggestions[2], isNot(darkSuggestions[2]));
    });
  });
}
