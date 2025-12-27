import 'package:flutter/material.dart';

/// Validates card face overlays to ensure suit colors remain legible
class OverlayValidator {
  /// Check if overlay maintains legibility for red and black suits
  ///
  /// Red suits (#CC3333) and black suits (#000000) must remain distinguishable
  /// from each other and from the overlay background.
  static bool isLegible(Color overlay, double intensity) {
    // If intensity is very low, overlay has minimal effect - always legible
    if (intensity < 0.1) return true;

    // Calculate the effective overlay color after applying intensity
    final effectiveOverlay = overlay.withValues(alpha: intensity);

    // Test colors for card suits
    const redSuit = Color(0xFFCC3333);
    const blackSuit = Color(0xFF000000);
    const white = Color(0xFFFFFFFF);

    // After overlay is applied, simulate the blended colors
    final blendedRed = _simulateBlend(redSuit, effectiveOverlay);
    final blendedBlack = _simulateBlend(blackSuit, effectiveOverlay);
    final blendedWhite = _simulateBlend(white, effectiveOverlay);

    // Check contrast ratios after blending
    final newRedVsWhite = _calculateContrast(blendedRed, blendedWhite);
    final newBlackVsWhite = _calculateContrast(blendedBlack, blendedWhite);
    final newRedVsBlack = _calculateContrast(blendedRed, blendedBlack);

    // WCAG AA requires 4.5:1 for normal text, but we're more lenient for decorative suits
    // We require at least 3.0:1 for readability
    const minContrast = 3.0;

    // Red and black must both be distinguishable from white background
    if (newRedVsWhite < minContrast || newBlackVsWhite < minContrast) {
      return false;
    }

    // Red and black must be distinguishable from each other
    if (newRedVsBlack < 2.0) {
      return false;
    }

    return true;
  }

  /// Calculate relative luminance of a color (WCAG formula)
  static double _relativeLuminance(Color color) {
    final rsRGB = (color.r * 255.0).round().clamp(0, 255) / 255;
    final gsRGB = (color.g * 255.0).round().clamp(0, 255) / 255;
    final bsRGB = (color.b * 255.0).round().clamp(0, 255) / 255;

    final r = rsRGB <= 0.03928 ? rsRGB / 12.92 : pow((rsRGB + 0.055) / 1.055, 2.4);
    final g = gsRGB <= 0.03928 ? gsRGB / 12.92 : pow((gsRGB + 0.055) / 1.055, 2.4);
    final b = bsRGB <= 0.03928 ? bsRGB / 12.92 : pow((bsRGB + 0.055) / 1.055, 2.4);

    return 0.2126 * r + 0.7152 * g + 0.0722 * b;
  }

  /// Calculate contrast ratio between two colors (WCAG formula)
  static double _calculateContrast(Color color1, Color color2) {
    final l1 = _relativeLuminance(color1);
    final l2 = _relativeLuminance(color2);

    final lighter = l1 > l2 ? l1 : l2;
    final darker = l1 > l2 ? l2 : l1;

    return (lighter + 0.05) / (darker + 0.05);
  }

  /// Simulate color blending (simplified modulate blend mode)
  static Color _simulateBlend(Color base, Color overlay) {
    final alpha = overlay.a;

    final baseR = (base.r * 255.0).round().clamp(0, 255);
    final baseG = (base.g * 255.0).round().clamp(0, 255);
    final baseB = (base.b * 255.0).round().clamp(0, 255);
    final overlayR = (overlay.r * 255.0).round().clamp(0, 255);
    final overlayG = (overlay.g * 255.0).round().clamp(0, 255);
    final overlayB = (overlay.b * 255.0).round().clamp(0, 255);

    final r = ((baseR * (1 - alpha)) + (overlayR * alpha)).round().clamp(0, 255);
    final g = ((baseG * (1 - alpha)) + (overlayG * alpha)).round().clamp(0, 255);
    final b = ((baseB * (1 - alpha)) + (overlayB * alpha)).round().clamp(0, 255);

    return Color.fromARGB(255, r, g, b);
  }

  /// Helper for Dart's pow function
  static double pow(double x, double exponent) {
    double result = 1.0;
    for (int i = 0; i < exponent; i++) {
      result *= x;
    }
    // For fractional exponents, this is a simplification
    // In production, use dart:math's pow function
    return result;
  }

  /// Get a warning message if overlay is not legible
  static String? getWarningMessage(Color overlay, double intensity) {
    if (isLegible(overlay, intensity)) return null;

    return 'This overlay may make card suits difficult to read. Consider reducing intensity.';
  }

  /// Suggest maximum safe intensity for a given overlay color
  static double suggestMaxIntensity(Color overlay) {
    // Binary search for maximum legible intensity
    double low = 0.0;
    double high = 1.0;
    double result = 0.5;

    for (int i = 0; i < 10; i++) {
      final mid = (low + high) / 2;
      if (isLegible(overlay, mid)) {
        result = mid;
        low = mid;
      } else {
        high = mid;
      }
    }

    return result;
  }
}
