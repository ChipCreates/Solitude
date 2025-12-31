import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:solitude/core/utils/overlay_validator.dart';

void main() {
  group('OverlayValidator.isLegible()', () {
    test('returns true for very low intensity overlays', () {
      const overlay = Color(0xFF000000);
      expect(OverlayValidator.isLegible(overlay, 0.05), isTrue);
      expect(OverlayValidator.isLegible(overlay, 0.09), isTrue);
    });

    test('returns true for zero intensity', () {
      const overlay = Color(0xFF000000);
      expect(OverlayValidator.isLegible(overlay, 0.0), isTrue);
    });

    test('handles transparent overlays', () {
      const transparent = Color(0x00000000);
      // Transparent overlay at low intensity should be legible
      expect(OverlayValidator.isLegible(transparent, 0.05), isTrue);
    });

    test('validates legible overlay combinations', () {
      // Light overlays at moderate intensity should be legible
      const lightGreen = Color(0xFF90EE90);
      expect(OverlayValidator.isLegible(lightGreen, 0.15), isTrue);
    });

    test('rejects illegible dark overlays at high intensity', () {
      const darkGray = Color(0xFF333333);
      expect(OverlayValidator.isLegible(darkGray, 0.8), isFalse);
    });

    test('handles pure black overlay', () {
      const black = Color(0xFF000000);
      // Low intensity should be fine
      expect(OverlayValidator.isLegible(black, 0.15), isTrue);
      // High intensity will likely fail legibility
      expect(OverlayValidator.isLegible(black, 0.9), isFalse);
    });

    test('handles pure white overlay', () {
      const white = Color(0xFFFFFFFF);
      // White overlay should generally be legible at moderate intensities
      expect(OverlayValidator.isLegible(white, 0.3), isTrue);
    });

    test('handles mid-tone overlays', () {
      const midGray = Color(0xFF808080);
      // Test a range of intensities
      final lowIntensity = OverlayValidator.isLegible(midGray, 0.2);

      // At low intensity should generally be legible
      expect(lowIntensity, isTrue);
    });

    test('returns consistent results for same input', () {
      const overlay = Color(0xFF4A90E2);
      final result1 = OverlayValidator.isLegible(overlay, 0.3);
      final result2 = OverlayValidator.isLegible(overlay, 0.3);

      expect(result1, result2);
    });

    test('handles edge case intensities', () {
      const overlay = Color(0xFF90EE90);

      expect(() => OverlayValidator.isLegible(overlay, 0.0), returnsNormally);
      expect(() => OverlayValidator.isLegible(overlay, 1.0), returnsNormally);
    });
  });

  group('OverlayValidator.getWarningMessage()', () {
    test('returns null for legible overlays', () {
      const overlay = Color(0xFFFFFFFF);
      expect(OverlayValidator.getWarningMessage(overlay, 0.1), isNull);
    });

    test('returns warning message for illegible overlays', () {
      const overlay = Color(0xFF000000);
      final message = OverlayValidator.getWarningMessage(overlay, 0.9);

      expect(message, isNotNull);
      expect(message, contains('overlay'));
      expect(message, contains('intensity'));
    });

    test('returns consistent warning message', () {
      const overlay = Color(0xFF333333);
      final message1 = OverlayValidator.getWarningMessage(overlay, 0.8);
      final message2 = OverlayValidator.getWarningMessage(overlay, 0.8);

      expect(message1, message2);
    });

    test('returns null for very low intensity', () {
      const overlay = Color(0xFF000000);
      expect(OverlayValidator.getWarningMessage(overlay, 0.05), isNull);
    });
  });

  group('OverlayValidator.suggestMaxIntensity()', () {
    test('returns a value between 0.0 and 1.0', () {
      const overlay = Color(0xFF4A90E2);
      final maxIntensity = OverlayValidator.suggestMaxIntensity(overlay);

      expect(maxIntensity, greaterThanOrEqualTo(0.0));
      expect(maxIntensity, lessThanOrEqualTo(1.0));
    });

    test('suggests higher intensity for lighter colors', () {
      const lightColor = Color(0xFFFFFFFF);
      const darkColor = Color(0xFF000000);

      final lightMax = OverlayValidator.suggestMaxIntensity(lightColor);
      final darkMax = OverlayValidator.suggestMaxIntensity(darkColor);

      expect(lightMax, greaterThan(darkMax));
    });

    test('suggested intensity is legible', () {
      const overlay = Color(0xFF4A90E2);
      final maxIntensity = OverlayValidator.suggestMaxIntensity(overlay);

      expect(OverlayValidator.isLegible(overlay, maxIntensity), isTrue);
    });

    test('suggested intensity minus small delta is still legible', () {
      const overlay = Color(0xFF4A90E2);
      final maxIntensity = OverlayValidator.suggestMaxIntensity(overlay);

      // Subtract a small amount to ensure we're well within safe range
      final safeIntensity = maxIntensity - 0.05;
      if (safeIntensity >= 0) {
        expect(OverlayValidator.isLegible(overlay, safeIntensity), isTrue);
      }
    });

    test('returns consistent results for same color', () {
      const overlay = Color(0xFF4A90E2);
      final result1 = OverlayValidator.suggestMaxIntensity(overlay);
      final result2 = OverlayValidator.suggestMaxIntensity(overlay);

      expect(result1, closeTo(result2, 0.01));
    });

    test('handles pure black', () {
      const black = Color(0xFF000000);
      final maxIntensity = OverlayValidator.suggestMaxIntensity(black);

      expect(maxIntensity, greaterThanOrEqualTo(0.0));
      expect(maxIntensity, lessThanOrEqualTo(1.0));
    });

    test('handles pure white', () {
      const white = Color(0xFFFFFFFF);
      final maxIntensity = OverlayValidator.suggestMaxIntensity(white);

      expect(maxIntensity, greaterThanOrEqualTo(0.0));
      expect(maxIntensity, lessThanOrEqualTo(1.0));
    });

    test('handles various color intensities', () {
      const colors = [
        Color(0xFFFF0000), // Red
        Color(0xFF00FF00), // Green
        Color(0xFF0000FF), // Blue
        Color(0xFFFFFF00), // Yellow
        Color(0xFFFF00FF), // Magenta
        Color(0xFF00FFFF), // Cyan
      ];

      for (final color in colors) {
        final maxIntensity = OverlayValidator.suggestMaxIntensity(color);
        expect(maxIntensity, greaterThanOrEqualTo(0.0));
        expect(maxIntensity, lessThanOrEqualTo(1.0));
      }
    });
  });

  group('OverlayValidator color calculations', () {
    test('handles color edge cases without errors', () {
      const colors = [
        Color(0xFF000000), // Black
        Color(0xFFFFFFFF), // White
        Color(0xFF808080), // Mid gray
        Color(0xFFFF0000), // Pure red
        Color(0xFF00FF00), // Pure green
        Color(0xFF0000FF), // Pure blue
      ];

      for (final color in colors) {
        expect(() => OverlayValidator.isLegible(color, 0.5), returnsNormally);
        expect(() => OverlayValidator.getWarningMessage(color, 0.5), returnsNormally);
        expect(() => OverlayValidator.suggestMaxIntensity(color), returnsNormally);
      }
    });

    test('validates actual theme overlay colors', () {
      // Test with actual overlay colors that might be used in themes
      const classicGreen = Color(0xFF2D5016);
      const burgundy = Color(0xFF4A1428);
      const blue = Color(0xFF1A3A52);

      for (final color in [classicGreen, burgundy, blue]) {
        // Should be able to calculate for all theme colors
        expect(() => OverlayValidator.suggestMaxIntensity(color), returnsNormally);

        // Suggested intensity should be legible
        final suggested = OverlayValidator.suggestMaxIntensity(color);
        expect(OverlayValidator.isLegible(color, suggested), isTrue);
      }
    });
  });

  group('OverlayValidator integration scenarios', () {
    test('workflow: check legibility, get warning if needed', () {
      const overlay = Color(0xFF333333);
      const intensity = 0.8;

      final isLegible = OverlayValidator.isLegible(overlay, intensity);
      final warning = OverlayValidator.getWarningMessage(overlay, intensity);

      if (isLegible) {
        expect(warning, isNull);
      } else {
        expect(warning, isNotNull);
      }
    });

    test('workflow: get suggested intensity and verify it works', () {
      const overlay = Color(0xFF4A90E2);

      final suggested = OverlayValidator.suggestMaxIntensity(overlay);
      final isLegibleAtSuggested = OverlayValidator.isLegible(overlay, suggested);
      final warningAtSuggested = OverlayValidator.getWarningMessage(overlay, suggested);

      expect(isLegibleAtSuggested, isTrue);
      expect(warningAtSuggested, isNull);
    });

    test('workflow: reduce intensity until legible', () {
      const overlay = Color(0xFF333333);
      double intensity = 1.0;

      // Keep reducing until legible
      while (!OverlayValidator.isLegible(overlay, intensity) && intensity > 0) {
        intensity -= 0.1;
      }

      if (intensity > 0) {
        expect(OverlayValidator.isLegible(overlay, intensity), isTrue);
      }
    });
  });

  group('OverlayValidator boundary conditions', () {
    test('handles intensity at boundaries', () {
      const overlay = Color(0xFF4A90E2);

      expect(() => OverlayValidator.isLegible(overlay, 0.0), returnsNormally);
      expect(() => OverlayValidator.isLegible(overlay, 1.0), returnsNormally);
    });

    test('handles all-zero color', () {
      const allZero = Color(0x00000000);

      expect(() => OverlayValidator.isLegible(allZero, 0.5), returnsNormally);
      expect(() => OverlayValidator.suggestMaxIntensity(allZero), returnsNormally);
    });

    test('handles all-max color', () {
      const allMax = Color(0xFFFFFFFF);

      expect(() => OverlayValidator.isLegible(allMax, 0.5), returnsNormally);
      expect(() => OverlayValidator.suggestMaxIntensity(allMax), returnsNormally);
    });
  });
}
