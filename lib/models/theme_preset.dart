import 'package:flutter/material.dart';

/// Represents a complete visual theme for the game including colors, card overlays, and visual style
class ThemePreset {
  final String id;
  final String name;
  final String description;

  // Table colors
  final Color tableColorLight;
  final Color tableColorDark;
  final Color toolbarColorLight;
  final Color toolbarColorDark;

  // Accent colors
  final Color accentColor;
  final Color accentMuted;

  // Card appearance
  final Color cardFaceOverlay;
  final double defaultOverlayIntensity;
  final BlendMode overlayBlendMode;

  // UI colors
  final Color textLight;
  final Color textMuted;

  final bool isBuiltIn;

  const ThemePreset({
    required this.id,
    required this.name,
    required this.description,
    required this.tableColorLight,
    required this.tableColorDark,
    required this.toolbarColorLight,
    required this.toolbarColorDark,
    required this.accentColor,
    required this.accentMuted,
    required this.cardFaceOverlay,
    this.defaultOverlayIntensity = 0.5,
    this.overlayBlendMode = BlendMode.modulate,
    this.textLight = const Color(0xFFFFFFF8),
    this.textMuted = const Color(0xFFCCCCCC),
    this.isBuiltIn = true,
  });

  // Get color based on brightness
  Color getTableColor(Brightness brightness) {
    return brightness == Brightness.dark ? tableColorDark : tableColorLight;
  }

  Color getToolbarColor(Brightness brightness) {
    return brightness == Brightness.dark ? toolbarColorDark : toolbarColorLight;
  }

  // ============================================================================
  // BUILT-IN THEME PRESETS
  // ============================================================================

  /// Classic green felt casino table
  static const classicGreen = ThemePreset(
    id: 'classic_green',
    name: 'Classic Felt',
    description: 'Traditional casino green table',
    tableColorLight: Color(0xFF4A8B3C),
    tableColorDark: Color(0xFF2D5A27),
    toolbarColorLight: Color(0xFF3D7A37),
    toolbarColorDark: Color(0xFF1E4A1A),
    accentColor: Color(0xFFD4AF37), // Gold
    accentMuted: Color(0xFFB8963A),
    cardFaceOverlay: Color(0xFFFFFFF8), // Off-white
    defaultOverlayIntensity: 0.0, // No tint for classic
  );

  /// Royal blue with silver accents
  static const royalBlue = ThemePreset(
    id: 'royal_blue',
    name: 'Royal Blue',
    description: 'Navy sophistication with silver',
    tableColorLight: Color(0xFF4169B3),
    tableColorDark: Color(0xFF1B3A6B),
    toolbarColorLight: Color(0xFF2E4A8B),
    toolbarColorDark: Color(0xFF0F2749),
    accentColor: Color(0xFFC0C0C0), // Silver
    accentMuted: Color(0xFF8C8C8C),
    cardFaceOverlay: Color(0xFFFFFFFF), // Pure white
    defaultOverlayIntensity: 0.0,
  );

  /// Burgundy velvet with sage green accents
  static const burgundyVelvet = ThemePreset(
    id: 'burgundy_velvet',
    name: 'Burgundy Velvet',
    description: 'Rich burgundy with sage green',
    tableColorLight: Color(0xFF8B2B3B), // Deep burgundy/maroon
    tableColorDark: Color(0xFF4A1820), // Dark wine
    toolbarColorLight: Color(0xFF6B2230), // Medium burgundy
    toolbarColorDark: Color(0xFF2A0F15), // Very dark burgundy
    accentColor: Color(0xFF7B8B6F), // Olive/sage green
    accentMuted: Color(0xFF5C6B52), // Muted sage
    cardFaceOverlay: Color(0xFFF5F0E8), // Warm cream
    defaultOverlayIntensity: 0.25,
  );

  /// Midnight black with platinum accents
  static const midnightBlack = ThemePreset(
    id: 'midnight_black',
    name: 'Midnight',
    description: 'Sleek dark with platinum highlights',
    tableColorLight: Color(0xFF3A3A3A),
    tableColorDark: Color(0xFF1A1A1A),
    toolbarColorLight: Color(0xFF2A2A2A),
    toolbarColorDark: Color(0xFF0A0A0A),
    accentColor: Color(0xFFE5E4E2), // Platinum
    accentMuted: Color(0xFFAAAAAA),
    cardFaceOverlay: Color(0xFFF8F8F8), // Soft gray
    defaultOverlayIntensity: 0.2,
  );

  /// Ocean teal - modern and calming
  static const oceanTeal = ThemePreset(
    id: 'ocean_teal',
    name: 'Ocean Teal',
    description: 'Modern calming sophistication',
    tableColorLight: Color(0xFF3A7F7D), // Light teal
    tableColorDark: Color(0xFF2C5F5D), // Deep teal-green
    toolbarColorLight: Color(0xFF2C6F6D), // Medium teal
    toolbarColorDark: Color(0xFF1C4F4D), // Dark teal
    accentColor: Color(0xFFFF8C6B), // Coral
    accentMuted: Color(0xFFD4AF37), // Warm gold
    cardFaceOverlay: Color(0xFFE8F4F4), // Light teal tint
    defaultOverlayIntensity: 0.2,
  );

  /// Sunset amber - warm and inviting
  static const sunsetAmber = ThemePreset(
    id: 'sunset_amber',
    name: 'Sunset Amber',
    description: 'Warm rustic sunset tones',
    tableColorLight: Color(0xFF9E673E), // Warm amber
    tableColorDark: Color(0xFF3D2415), // Deep burnt sienna
    toolbarColorLight: Color(0xFF7D5030), // Rusty orange
    toolbarColorDark: Color(0xFF5C3A22), // Rich terracotta
    accentColor: Color(0xFFFFB84D), // Bright gold-orange
    accentMuted: Color(0xFFD4943D), // Muted amber
    cardFaceOverlay: Color(0xFFFFF5E8), // Warm peachy tint
    defaultOverlayIntensity: 0.2,
  );

  /// Slate gray - modern and professional
  static const slateGray = ThemePreset(
    id: 'slate_gray',
    name: 'Slate Gray',
    description: 'Modern professional high contrast',
    tableColorLight: Color(0xFF5A6A7A), // Light slate
    tableColorDark: Color(0xFF4A5568), // Cool medium gray
    toolbarColorLight: Color(0xFF4F5D6D), // Medium slate
    toolbarColorDark: Color(0xFF3A4758), // Dark slate
    accentColor: Color(0xFF00D9FF), // Electric blue
    accentMuted: Color(0xFF0099CC), // Muted blue
    cardFaceOverlay: Color(0xFFF0F4F8), // Cool light tint
    defaultOverlayIntensity: 0.2,
  );

  /// Plum royale - elegant and regal
  static const plumRoyale = ThemePreset(
    id: 'plum_royale',
    name: 'Plum Royale',
    description: 'Elegant regal unique',
    tableColorLight: Color(0xFF5A3555), // Light plum
    tableColorDark: Color(0xFF4A2545), // Deep purple-plum
    toolbarColorLight: Color(0xFF4F2F4A), // Medium plum
    toolbarColorDark: Color(0xFF3A1F35), // Dark plum
    accentColor: Color(0xFFFFD700), // Gold
    accentMuted: Color(0xFFC0C0C0), // Silver
    cardFaceOverlay: Color(0xFFF5F0F8), // Light purple tint
    defaultOverlayIntensity: 0.2,
  );

  // ============================================================================
  // THEME REGISTRY
  // ============================================================================

  static final List<ThemePreset> builtInThemes = [
    classicGreen,
    royalBlue,
    burgundyVelvet,
    midnightBlack,
    oceanTeal,
    sunsetAmber,
    slateGray,
    plumRoyale,
  ];

  static ThemePreset? findById(String id) {
    try {
      return builtInThemes.firstWhere((theme) => theme.id == id);
    } catch (_) {
      return null;
    }
  }

  static ThemePreset get defaultTheme => classicGreen;

  /// Suggested card back colors for this theme (ordered by preference).
  List<Color> suggestedBackColors(Brightness brightness) {
    // Prefer the accent, then a muted accent, then a toolbar color appropriate for brightness
    final toolbar = getToolbarColor(brightness);
    return [accentColor, accentMuted, toolbar, tableColorDark];
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ThemePreset && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
