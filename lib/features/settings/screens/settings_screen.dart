import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import '../services/settings_provider.dart';
import 'package:solitude/features/game/games/game_factory.dart';
import 'package:solitude/core/theme/app_theme.dart';
import '../models/difficulty.dart';
import '../models/theme_preset.dart';
import '../../game/models/draw_mode.dart';

import '../widgets/game_toggle.dart';
import 'package:solitude/core/widgets/game_button.dart';
import '../widgets/volume_slider.dart';
import '../widgets/theme_preview_cards.dart';
import 'package:solitude/features/game/widgets/card_widget.dart';
import 'package:solitude/core/utils/overlay_validator.dart';
import 'package:solitude/features/home/screens/about_screen.dart';
import 'package:solitude/features/home/screens/help_screen.dart';

/// Full-screen tabbed settings interface
class SettingsScreen extends StatefulWidget {
  /// The currently active game type (passed from game screen)
  final GameType? gameType;

  const SettingsScreen({super.key, this.gameType});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

// ---------------------------------------------------------------------------
// CARDS TAB
// ---------------------------------------------------------------------------
class _CardsTab extends StatelessWidget {
  const _CardsTab();

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, settings, _) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                      width: 40,
                      height: 1,
                      color:
                          AppTheme.accentColor(context).withValues(alpha: 0.3)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text('CARD CUSTOMIZATION',
                        style: AppTypography.subheading(context)),
                  ),
                  Expanded(
                      child: Container(
                          height: 1,
                          color: AppTheme.accentColor(context)
                              .withValues(alpha: 0.3))),
                ],
              ),
              const SizedBox(height: 20),
              _OverlayControls(),
              const SizedBox(height: 28),
              _CardBackCustomization(),
              const SizedBox(height: 24),
              Center(
                  child: ThemePreviewCards(
                      theme: settings.currentTheme, cardWidth: 70)),
            ],
          ),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// SOUND TAB
// ---------------------------------------------------------------------------
class _SoundTab extends StatelessWidget {
  const _SoundTab();

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, settings, _) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              _buildSettingRow(
                context,
                label: 'Sound Effects',
                subtitle: 'Play audio feedback',
                child: GameSwitch(
                    value: settings.soundEnabled,
                    onChanged: settings.setSoundEnabled),
              ),
              const SizedBox(height: 20),
              _buildSettingRow(
                context,
                label: 'Volume',
                subtitle: '${(settings.soundVolume * 100).round()}%',
                child: SizedBox(
                  width: 180,
                  child: VolumeSlider(
                      value: settings.soundVolume,
                      onChanged: (v) => settings.setSoundVolume(v)),
                ),
              ),
              const SizedBox(height: 20),
              _buildSettingRow(
                context,
                label: 'Background Music',
                subtitle: 'Play music during the game',
                child: GameSwitch(
                    value: settings.musicEnabled,
                    onChanged: settings.setMusicEnabled),
              ),
              const SizedBox(height: 20),
              _buildSettingRow(
                context,
                label: 'Music Volume',
                subtitle: '${(settings.musicVolume * 100).round()}%',
                child: SizedBox(
                  width: 180,
                  child: VolumeSlider(
                      value: settings.musicVolume,
                      onChanged: (v) => settings.setMusicVolume(v)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SettingsScreenState extends State<SettingsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsProvider>(context);
    final theme = settings.currentTheme;

    return Scaffold(
      backgroundColor: theme.getTableColor(Theme.of(context).brightness),
      appBar: AppBar(
        backgroundColor: theme.getToolbarColor(Theme.of(context).brightness),
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.close, color: theme.textLight),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Settings',
          style:
              AppTypography.heading(context).copyWith(color: theme.textLight),
        ),
        bottom: TabBar(
          controller: _tabController,
          overlayColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.hovered)) {
              return Theme.of(context).brightness == Brightness.dark
                  ? Colors.white.withValues(alpha: 0.12)
                  : Colors.black.withValues(alpha: 0.06);
            }
            if (states.contains(WidgetState.pressed)) {
              return theme.accentColor.withValues(alpha: 0.14);
            }
            return Colors.transparent;
          }),
          labelColor: theme.accentColor,
          unselectedLabelColor: theme.textLight.withValues(alpha: 0.5),
          indicator: BoxDecoration(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.white.withValues(alpha: 0.12)
                : Colors.black.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(8),
          ),
          indicatorPadding:
              const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          indicatorSize: TabBarIndicatorSize.tab,
          labelStyle: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 14,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
          tabs: const [
            Tab(icon: Icon(Icons.palette_outlined, size: 20), text: 'THEME'),
            Tab(
                icon: Icon(Icons.credit_card_outlined, size: 20),
                text: 'CARDS'),
            Tab(
                icon: Icon(Icons.sports_esports_outlined, size: 20),
                text: 'GAMEPLAY'),
            Tab(icon: Icon(Icons.volume_up_outlined, size: 20), text: 'SOUND'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          const _AppearanceTab(),
          const _CardsTab(),
          _GameplayTab(gameType: widget.gameType),
          const _SoundTab(),
        ],
      ),
    );
  }
}

Widget _buildSettingRow(
  BuildContext context, {
  required String label,
  String? subtitle,
  required Widget child,
}) {
  return Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    crossAxisAlignment:
        subtitle != null ? CrossAxisAlignment.start : CrossAxisAlignment.center,
    children: [
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: AppTypography.label(context)),
            if (subtitle != null) ...[
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  color: AppColors.cream.withValues(alpha: 0.5),
                ),
              ),
            ],
          ],
        ),
      ),
      child,
    ],
  );
}

// ============================================================================
// APPEARANCE TAB
// ============================================================================

class _AppearanceTab extends StatelessWidget {
  const _AppearanceTab();

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, settings, _) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _ThemeSelector(),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }
}

class _ThemeSelector extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, settings, _) {
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            childAspectRatio: 0.714, // Playing card aspect ratio (2.5:3.5)
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: ThemePreset.builtInThemes.length,
          itemBuilder: (context, index) {
            final theme = ThemePreset.builtInThemes[index];
            final isSelected = settings.currentThemeId == theme.id;

            return GestureDetector(
              onTap: () => settings.setCurrentTheme(theme.id),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  color: theme
                      .getTableColor(Brightness.dark)
                      .withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isSelected
                        ? theme.accentColor.withValues(alpha: 0.8)
                        : AppColors.cream.withValues(alpha: 0.15),
                    width: isSelected ? 2.5 : 1,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: theme.accentColor.withValues(alpha: 0.4),
                            blurRadius: 12,
                            spreadRadius: 1,
                          ),
                        ]
                      : null,
                ),
                child: Stack(
                  children: [
                    // Theme preview gradient
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(7),
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              theme
                                  .getTableColor(Brightness.light)
                                  .withValues(alpha: 0.5),
                              theme
                                  .getTableColor(Brightness.dark)
                                  .withValues(alpha: 0.7),
                            ],
                          ),
                        ),
                      ),
                    ),
                    // Theme name at bottom
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.3),
                          borderRadius: const BorderRadius.only(
                            bottomLeft: Radius.circular(7),
                            bottomRight: Radius.circular(7),
                          ),
                        ),
                        child: Text(
                          theme.name,
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.cream,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                    // Checkmark for selected
                    if (isSelected)
                      Positioned(
                        top: 6,
                        right: 6,
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: theme.accentColor,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.check,
                            size: 14,
                            color: Colors.white,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _OverlayControls extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, settings, _) {
        final theme = settings.currentTheme;
        final intensity = settings.getOverlayIntensity(theme.id);
        final warning = OverlayValidator.getWarningMessage(
            theme.cardFaceOverlay, intensity);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Intensity slider
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Tint Intensity',
                    style: AppTypography.label(context),
                  ),
                ),
                Text(
                  '${(intensity * 100).round()}%',
                  style: AppTypography.body(context).copyWith(
                    color: AppColors.gold,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SliderTheme(
              data: SliderThemeData(
                activeTrackColor: AppColors.gold,
                inactiveTrackColor: AppColors.cream.withValues(alpha: 0.2),
                thumbColor: AppColors.gold,
                overlayColor: AppColors.gold.withValues(alpha: 0.2),
                trackHeight: 4,
              ),
              child: Slider(
                value: intensity,
                min: 0.0,
                max: 1.0,
                divisions: 20,
                onChanged: (value) {
                  settings.setOverlayIntensity(theme.id, value);
                },
              ),
            ),
            if (warning != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.invalidMove.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppColors.invalidMove.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.warning_amber_rounded,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        warning,
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 12,
                          color: AppColors.cream.withValues(alpha: 0.9),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

class _CardBackCustomization extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, settings, _) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Large card back previews
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildCardBackOption(
                    context,
                    settings,
                    elementId: 'back',
                    label: 'Diamonds',
                    isSelected: settings.cardBackVariant == 'back',
                    onTap: () => settings.setCardBackVariant('back'),
                  ),
                  const SizedBox(width: 16),
                  _buildCardBackOption(
                    context,
                    settings,
                    elementId: 'alternate-back',
                    label: 'Crosshatch',
                    isSelected: settings.cardBackVariant == 'alternate',
                    onTap: () => settings.setCardBackVariant('alternate'),
                  ),
                  const SizedBox(width: 16),
                  _buildCardBackOption(
                    context,
                    settings,
                    elementId: 'dots',
                    label: 'Dots',
                    isSelected: settings.cardBackVariant == 'dots',
                    onTap: () => settings.setCardBackVariant('dots'),
                  ),
                  const SizedBox(width: 16),
                  _buildCardBackOption(
                    context,
                    settings,
                    elementId: 'waves',
                    label: 'Waves',
                    isSelected: settings.cardBackVariant == 'waves',
                    onTap: () => settings.setCardBackVariant('waves'),
                  ),
                  const SizedBox(width: 16),
                  _buildCardBackOption(
                    context,
                    settings,
                    elementId: 'double',
                    label: 'Double',
                    isSelected: settings.cardBackVariant == 'double',
                    onTap: () => settings.setCardBackVariant('double'),
                  ),
                  const SizedBox(width: 16),
                  _buildCardBackOption(
                    context,
                    settings,
                    elementId: 'spade',
                    label: 'Spade',
                    isSelected: settings.cardBackVariant == 'spade',
                    onTap: () => settings.setCardBackVariant('spade'),
                  ),
                  const SizedBox(width: 16),
                  _buildCardBackOption(
                    context,
                    settings,
                    elementId: 'art_deco',
                    label: 'Art Deco',
                    isSelected: settings.cardBackVariant == 'art_deco',
                    onTap: () => settings.setCardBackVariant('art_deco'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            // Colored back toggle
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Custom Color', style: AppTypography.label(context)),
                GameSwitch(
                  value: settings.cardBackColored,
                  onChanged: settings.setCardBackColored,
                ),
              ],
            ),
            // Color picker (shown when colored back is enabled)
            if (settings.cardBackColored) ...[
              const SizedBox(height: 20),
              _buildColorPicker(context, settings),
            ],
          ],
        );
      },
    );
  }

  Widget _buildCardBackOption(
    BuildContext context,
    SettingsProvider settings, {
    required String elementId,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final String? colorOverride =
        settings.cardBackColored ? settings.cardBackColor : null;

    final Color primaryColor = colorOverride != null
        ? Color(int.parse(colorOverride.replaceFirst('#', ''), radix: 16) |
            0xFF000000)
        : Colors.blue;

    final CustomPainter painter;
    if (elementId == 'art_deco') {
      painter = ArtDecoCardBackPainter(primaryColor: primaryColor);
    } else {
      painter = CardBackPainter(
        primaryColor: primaryColor,
        pattern: elementId == 'back'
            ? 'diamond'
            : (elementId == 'alternate-back' ? 'crosshatch' : elementId),
      );
    }

    // Preview dimensions
    const double width = 80;
    const double height = 116;

    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.feltMedium.withValues(alpha: 0.4)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected
                    ? AppColors.gold.withValues(alpha: 0.6)
                    : AppColors.cream.withValues(alpha: 0.1),
                width: isSelected ? 2 : 1,
              ),
            ),
            child: SizedBox(
              width: width,
              height: height,
              child: ClipRRect(
                borderRadius:
                    BorderRadius.circular(4), // Match card corner radius approx
                child: Stack(
                  children: [
                    // Layer 1: The Painted Background
                    CustomPaint(
                      size: const Size(width, height),
                      painter: painter,
                    ),

                    // Layer 2: The SVG Overlays
                    if (elementId == 'spade')
                      Center(
                        child: Transform.translate(
                          // ignore: prefer_const_constructors
                          offset: const Offset(0, -width * 0.70 * 0.05),
                          child: SvgPicture.asset(
                            'assets/cards/spade.svg',
                            width: width * 0.70,
                            height: width * 0.70,
                            colorFilter: ColorFilter.mode(
                                primaryColor.withValues(alpha: 0.5),
                                BlendMode.srcATop),
                          ),
                        ),
                      ),

                    if (elementId == 'double')
                      Stack(
                        children: [
                          // Top Spade
                          Positioned(
                            left: (width - (width * 0.45)) / 2,
                            top: (height * 0.30) - ((width * 0.45) / 2),
                            child: SvgPicture.asset(
                              'assets/cards/spade.svg',
                              width: width * 0.45,
                              height: width * 0.45,
                              colorFilter: ColorFilter.mode(
                                  primaryColor.withValues(alpha: 0.5),
                                  BlendMode.srcATop),
                            ),
                          ),
                          // Bottom Spade
                          Positioned(
                            left: (width - (width * 0.45)) / 2,
                            top: (height * 0.70) - ((width * 0.45) / 2),
                            child: Transform.rotate(
                              angle: math.pi,
                              child: SvgPicture.asset(
                                'assets/cards/spade.svg',
                                width: width * 0.45,
                                height: width * 0.45,
                                colorFilter: ColorFilter.mode(
                                    primaryColor.withValues(alpha: 0.5),
                                    BlendMode.srcATop),
                              ),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 13,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              color: isSelected
                  ? AppColors.cream
                  : AppColors.cream.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildColorPicker(BuildContext context, SettingsProvider settings) {
    // Curated set of card back colors with good variety and visual appeal
    final cardBackColors = [
      // Classic casino colors
      [const Color(0xFF1A1A1A), 'Classic Black'], // Deep black
      [const Color(0xFF2D4A3E), 'Forest Green'], // Rich forest green
      [const Color(0xFF8B4513), 'Burgundy'], // Deep burgundy
      [const Color(0xFF4169E1), 'Royal Blue'], // Royal blue
      [const Color(0xFFDAA520), 'Gold'], // Antique gold

      // Modern vibrant colors
      [const Color(0xFFDC143C), 'Crimson'], // Vibrant red
      [const Color(0xFF32CD32), 'Lime Green'], // Bright green
      [const Color(0xFFFF6347), 'Coral'], // Warm coral
      [const Color(0xFF9370DB), 'Purple'], // Medium purple
      [const Color(0xFFFFA500), 'Orange'], // Bright orange

      // Elegant muted tones
      [const Color(0xFF696969), 'Charcoal'], // Warm charcoal
      [const Color(0xFF8B7355), 'Taupe'], // Warm taupe
      [const Color(0xFF708090), 'Slate'], // Cool slate
      [const Color(0xFFCD853F), 'Peru'], // Warm brown
      [const Color(0xFF4682B4), 'Steel Blue'], // Steel blue

      // Theme-aware colors (keep some theme integration)
      [settings.currentTheme.accentColor, 'Theme Accent'],
      [settings.currentTheme.accentMuted, 'Theme Muted'],
    ];

    final colors = cardBackColors.map((colorData) {
      final color = colorData[0] as Color;
      final name = colorData[1] as String;
      final hex =
          '#${(color.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0')}';
      return [hex, name];
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Text(
            'Back Color',
            style: AppTypography.label(context).copyWith(
              color: AppColors.cream.withValues(alpha: 0.7),
            ),
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: colors.map((colorData) {
            final hex = colorData[0];
            final name = colorData[1];
            final isSelected = settings.cardBackColor == hex;
            final color = _hexToColor(hex);

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: GestureDetector(
                onTap: () => settings.setCardBackColor(hex),
                child: Tooltip(
                  message: name,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected
                            ? AppColors.gold
                            : AppColors.cream.withValues(alpha: 0.2),
                        width: isSelected ? 3 : 1,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: color.withValues(alpha: 0.4),
                                blurRadius: 8,
                                spreadRadius: 1,
                              ),
                            ]
                          : null,
                    ),
                    child: isSelected
                        ? Icon(
                            Icons.check,
                            color: _isLightColor(color)
                                ? Colors.black
                                : Colors.white,
                            size: 20,
                          )
                        : null,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Color _hexToColor(String hex) {
    hex = hex.replaceFirst('#', '');
    if (hex.length == 3) {
      hex = hex.split('').map((c) => '$c$c').join();
    }
    return Color(int.parse('FF$hex', radix: 16));
  }

  bool _isLightColor(Color color) {
    final luminance = color.computeLuminance();
    return luminance > 0.5;
  }
}

// ============================================================================
// GAMEPLAY TAB - Context-Aware Settings Based on Active Game Type
// ============================================================================

class _GameplayTab extends StatelessWidget {
  final GameType? gameType;

  const _GameplayTab({this.gameType});

  // ---------------------------------------------------------------------------
  // VISIBILITY MATRIX - Determines which settings show for each game type
  // ---------------------------------------------------------------------------

  /// Check if Draw Mode setting should be shown for the current game type
  /// Draw Mode (1 vs 3): ONLY for Klondike and Canfield
  static bool _showDrawMode(GameType? gameType) {
    if (gameType == null) return false;
    return gameType == GameType.klondike || gameType == GameType.canfield;
  }

  /// Check if Scoring Mode setting should be shown for the current game type
  /// Scoring Mode (Vegas): ONLY for Klondike and Canfield
  static bool _showScoringMode(GameType? gameType) {
    if (gameType == null) return false;
    return gameType == GameType.klondike || gameType == GameType.canfield;
  }

  /// Check if this is a Spider game (for suit count difficulty options)
  /// Spider gets special "Suits" difficulty selector
  static bool _isSpiderGame(GameType? gameType) {
    return gameType == GameType.spider;
  }

  /// Check if Difficulty selector should be shown
  /// Currently only Spider has a meaningful difficulty selector (suit count)
  static bool _showDifficulty(GameType? gameType) {
    if (gameType == null) return false;
    return gameType == GameType.spider;
  }

  /// Check if Auto-Complete setting should be shown
  /// Hide for elimination games: Pyramid, TriPeaks, Golf
  /// (they don't use foundations in the standard way)
  static bool _showAutoComplete(GameType? gameType) {
    if (gameType == null) return true; // Show by default if no game context
    switch (gameType) {
      case GameType.pyramid:
      case GameType.triPeaks:
      case GameType.golf:
        return false;
      default:
        return true;
    }
  }

  /// Get Spider-specific difficulty description (Suits: 1/2/4)
  static String _getSpiderDifficultyDescription(Difficulty difficulty) {
    switch (difficulty) {
      case Difficulty.easy:
        return '1 Suit - Easiest to win';
      case Difficulty.medium:
        return '2 Suits - Moderate challenge';
      case Difficulty.hard:
        return '4 Suits - Full difficulty';
    }
  }

  /// Get scoring description for a specific game type
  static String _getScoringDescription(GameType? gameType) {
    if (gameType == null) return 'Track your progress';
    switch (gameType) {
      case GameType.klondike:
      case GameType.canfield:
        return 'Standard or Vegas-style scoring';
      case GameType.spider:
        return 'Start: 500 • -1/move • +100/suit completed';
      case GameType.triPeaks:
        return 'Streak bonus: +1 per consecutive card';
      case GameType.golf:
        return '+1 per card cleared from tableau';
      case GameType.pyramid:
        return '+2 per pair matched, bonus for clearing';
      case GameType.freecell:
        return '+10 per card to foundation';
      case GameType.yukon:
      case GameType.fortyThieves:
      case GameType.scorpion:
        return '+5 per card to foundation';
    }
  }

  // ---------------------------------------------------------------------------
  // SNACKBAR FEEDBACK - For gameplay-impacting setting changes
  // ---------------------------------------------------------------------------

  /// Shows a SnackBar warning that changes will apply to the next game
  void _showSettingsChangedSnackBar(BuildContext context) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Changes will apply to the next game.'),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppTheme.toolbarColor(context),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // BUILD METHOD - Main entry point
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    // Use the gameType passed as a parameter from the parent widget
    final activeGameType = gameType;

    return Consumer<SettingsProvider>(
      builder: (context, settings, _) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              // Game-specific settings (visibility based on active game)
              ..._buildGameplaySettings(context, settings, activeGameType),

              // Global settings section (always visible)
              _buildGlobalSettingsSection(context, settings),

              // Navigation buttons
              const SizedBox(height: 40),
              GameButton(
                label: 'How to Play',
                width: double.infinity,
                onPressed: () {
                  Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const HelpScreen()));
                },
              ),
              const SizedBox(height: 12),
              GameButton(
                label: 'About Solitude',
                width: double.infinity,
                onPressed: () {
                  Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const AboutScreen()));
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // HELPER: Build game-specific settings based on active game type
  // ---------------------------------------------------------------------------

  List<Widget> _buildGameplaySettings(
    BuildContext context,
    SettingsProvider settings,
    GameType? activeGameType,
  ) {
    final List<Widget> widgets = [];

    // Determine which rule settings are applicable
    final showDrawMode = _showDrawMode(activeGameType);
    final showScoringMode = _showScoringMode(activeGameType);
    final showDifficulty = _showDifficulty(activeGameType);
    final showAutoComplete = _showAutoComplete(activeGameType);
    final isSpider = _isSpiderGame(activeGameType);

    // ---------------------------------------------------------------------------
    // GAME CONTEXT HEADER - Show current game name
    // ---------------------------------------------------------------------------
    if (activeGameType != null) {
      widgets.addAll([
        _buildGameContextCard(context, activeGameType, settings),
        const SizedBox(height: 24),
      ]);
    }

    // ---------------------------------------------------------------------------
    // SCORING INFO SECTION - Per-game scoring rules (always shown)
    // ---------------------------------------------------------------------------
    widgets.addAll([
      _buildSectionHeader(context, 'SCORING'),
      const SizedBox(height: 20),
      _buildScoringInfoCard(context, activeGameType, settings),
      const SizedBox(height: 20),
    ]);

    // Scoring Mode dropdown - Only for Klondike and Canfield (Vegas mode)
    if (showScoringMode) {
      widgets.addAll([
        _buildSettingRow(
          context,
          label: 'Scoring Mode',
          subtitle: settings.scoringMode.description,
          child: _buildScoringDropdown(context, settings),
        ),
        const SizedBox(height: 20),
      ]);

      // Vegas cumulative toggle (only show when Vegas mode is selected)
      if (settings.scoringMode == ScoringMode.vegasCumulative) {
        widgets.addAll([
          _buildSettingRow(
            context,
            label: 'Current Bankroll',
            subtitle: 'Carries across games',
            child: Text(
              '\$${settings.vegasBankroll}',
              style: AppTypography.heading(context).copyWith(
                color: settings.vegasBankroll >= 0
                    ? Colors.green
                    : AppColors.invalidMove,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: GameButton(
              label: 'Reset Bankroll',
              width: 140,
              onPressed: () {
                settings.resetVegasBankroll();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Vegas bankroll reset to \$0'),
                    duration: const Duration(seconds: 2),
                    behavior: SnackBarBehavior.floating,
                    backgroundColor: AppTheme.toolbarColor(context),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 20),
        ]);
      }
    }

    widgets.add(const SizedBox(height: 8));

    // ---------------------------------------------------------------------------
    // RULE SETTINGS SECTION - Draw Mode
    // ---------------------------------------------------------------------------
    if (showDrawMode) {
      widgets.addAll([
        _buildSectionHeader(context, 'DRAW RULES'),
        const SizedBox(height: 20),
        _buildSettingRow(
          context,
          label: 'Draw Mode',
          subtitle: settings.drawMode == DrawMode.one
              ? 'Draw 1 card - Easier'
              : 'Draw 3 cards - Classic',
          child: GameToggle<DrawMode>(
            value: settings.drawMode,
            options: [
              GameToggleOption(
                  value: DrawMode.one,
                  label: '1',
                  color: settings.currentTheme.accentColor),
              GameToggleOption(
                  value: DrawMode.three,
                  label: '3',
                  color: settings.currentTheme.accentColor),
            ],
            onChanged: (mode) {
              settings.setDrawMode(mode);
              _showSettingsChangedSnackBar(context);
            },
          ),
        ),
        const SizedBox(height: 28),
      ]);
    }

    // ---------------------------------------------------------------------------
    // DIFFICULTY SECTION - Spider-specific suit count selector
    // ---------------------------------------------------------------------------
    if (showDifficulty) {
      widgets.addAll([
        _buildSectionHeader(context, 'DIFFICULTY'),
        const SizedBox(height: 20),
      ]);

      if (isSpider) {
        // Spider-specific suit count toggle (1/2/4 suits)
        widgets.addAll([
          _buildSettingRow(
            context,
            label: 'Suits',
            subtitle: _getSpiderDifficultyDescription(settings.difficulty),
            child: _buildSpiderSuitToggle(context, settings),
          ),
          const SizedBox(height: 20),
        ]);
      }

      widgets.add(const SizedBox(height: 8));
    }

    // ---------------------------------------------------------------------------
    // GAMEPLAY OPTIONS SECTION - Auto-Complete (if applicable)
    // ---------------------------------------------------------------------------
    if (showAutoComplete) {
      widgets.addAll([
        _buildSectionHeader(context, 'GAMEPLAY'),
        const SizedBox(height: 20),
        _buildSettingRow(
          context,
          label: 'Auto-Complete',
          subtitle: 'Finish game when all cards are revealed',
          child: GameSwitch(
            value: settings.autoComplete,
            onChanged: settings.setAutoComplete,
          ),
        ),
        const SizedBox(height: 20),
        _buildSettingRow(
          context,
          label: 'Autoplay',
          subtitle: 'Let the game play itself',
          child: GameSwitch(
            value: settings.autoplay,
            onChanged: settings.setAutoplay,
          ),
        ),
        const SizedBox(height: 28),
      ]);
    }

    return widgets;
  }

  // ---------------------------------------------------------------------------
  // HELPER: Build game context card showing current game
  // ---------------------------------------------------------------------------

  Widget _buildGameContextCard(
    BuildContext context,
    GameType gameType,
    SettingsProvider settings,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: settings.currentTheme.accentColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: settings.currentTheme.accentColor.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.sports_esports,
            color: settings.currentTheme.accentColor,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Currently Playing',
                  style: AppTypography.body(context).copyWith(
                    color: AppColors.cream.withValues(alpha: 0.6),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _getGameDisplayName(gameType),
                  style: AppTypography.heading(context).copyWith(
                    color: settings.currentTheme.accentColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // HELPER: Build scoring info card with per-game scoring rules
  // ---------------------------------------------------------------------------

  Widget _buildScoringInfoCard(
    BuildContext context,
    GameType? gameType,
    SettingsProvider settings,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.feltDark.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.cream.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.scoreboard_outlined,
                color: AppColors.gold,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                gameType != null
                    ? '${_getGameDisplayName(gameType)} Scoring'
                    : 'Scoring System',
                style: AppTypography.label(context).copyWith(
                  color: AppColors.gold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            _getScoringDescription(gameType),
            style: AppTypography.body(context).copyWith(
              color: AppColors.cream.withValues(alpha: 0.8),
            ),
          ),
          const SizedBox(height: 12),
          ..._buildScoringDetails(context, gameType, settings),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // HELPER: Build per-game scoring detail bullets
  // ---------------------------------------------------------------------------

  List<Widget> _buildScoringDetails(
    BuildContext context,
    GameType? gameType,
    SettingsProvider settings,
  ) {
    final List<String> details = _getScoringDetailsList(gameType, settings);

    return details.map((detail) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '•  ',
              style: TextStyle(
                color: AppColors.cream.withValues(alpha: 0.6),
                fontSize: 12,
              ),
            ),
            Expanded(
              child: Text(
                detail,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  color: AppColors.cream.withValues(alpha: 0.6),
                ),
              ),
            ),
          ],
        ),
      );
    }).toList();
  }

  /// Get detailed scoring breakdown per game type
  List<String> _getScoringDetailsList(
      GameType? gameType, SettingsProvider settings) {
    if (gameType == null) {
      return ['Select a game to see scoring rules'];
    }

    switch (gameType) {
      case GameType.klondike:
      case GameType.canfield:
        if (settings.scoringMode == ScoringMode.vegas ||
            settings.scoringMode == ScoringMode.vegasCumulative) {
          return [
            'Pay \$52 to start each game',
            'Earn \$5 for each card moved to foundation',
            'Break even at 11 cards (11 × \$5 = \$55)',
            'Maximum payout: \$260 (52 × \$5)',
          ];
        }
        return [
          '+10 points per card to foundation',
          '+5 points for tableau face-up flip',
          '+5 points for waste to tableau move',
          '-15 points for foundation to tableau move',
          '-100 points per deck recycle (after first)',
        ];
      case GameType.spider:
        return [
          'Start with 500 points',
          '-1 point per move',
          '+100 points per completed suit (K→A)',
          'Win bonus: remaining points',
        ];
      case GameType.triPeaks:
        return [
          'Base: +1 point per card cleared',
          'Streak bonus: +1, +2, +3... for consecutive clears',
          'Peak bonus: +15 points per peak top cleared',
          'Perfect game bonus: +100 for clearing all cards',
        ];
      case GameType.golf:
        return [
          '+1 point per card cleared from tableau',
          'Goal: clear as many cards as possible',
          'Lower remaining cards = better score',
          'Perfect score: 35 points (all cards cleared)',
        ];
      case GameType.pyramid:
        return [
          '+2 points per matched pair',
          '+5 points for pairing with stock card',
          'Pyramid clear bonus: +50 points',
          'Perfect game: 104 points (all pairs + bonus)',
        ];
      case GameType.freecell:
        return [
          '+10 points per card to foundation',
          'Win bonus: +100 points',
          'Time bonus available for quick wins',
        ];
      case GameType.yukon:
      case GameType.fortyThieves:
      case GameType.scorpion:
        return [
          '+5 points per card to foundation',
          'Win bonus: +100 points',
          'Efficiency bonus for fewer moves',
        ];
    }
  }

  /// Get display name for a game type
  String _getGameDisplayName(GameType gameType) {
    switch (gameType) {
      case GameType.klondike:
        return 'Klondike';
      case GameType.spider:
        return 'Spider';
      case GameType.freecell:
        return 'FreeCell';
      case GameType.pyramid:
        return 'Pyramid';
      case GameType.triPeaks:
        return 'TriPeaks';
      case GameType.golf:
        return 'Golf';
      case GameType.yukon:
        return 'Yukon';
      case GameType.fortyThieves:
        return 'Forty Thieves';
      case GameType.canfield:
        return 'Canfield';
      case GameType.scorpion:
        return 'Scorpion';
    }
  }

  // ---------------------------------------------------------------------------
  // HELPER: Build global settings section (always visible)
  // ---------------------------------------------------------------------------

  Widget _buildGlobalSettingsSection(
    BuildContext context,
    SettingsProvider settings,
  ) {
    return Column(
      children: [
        _buildSectionHeader(context, 'ACCESSIBILITY'),
        const SizedBox(height: 20),
        _buildSettingRow(
          context,
          label: 'Left Hand Mode',
          subtitle: 'Swap foundations and stock positions',
          child: GameSwitch(
            value: settings.leftHandMode,
            onChanged: settings.setLeftHandMode,
          ),
        ),
        const SizedBox(height: 20),
        _buildSettingRow(
          context,
          label: 'Show Timer',
          subtitle: 'Display elapsed game time',
          child: GameSwitch(
            value: settings.showTimer,
            onChanged: settings.setShowTimer,
          ),
        ),
        const SizedBox(height: 28),
        _buildSectionHeader(context, 'APPEARANCE'),
        const SizedBox(height: 20),
        _buildSettingRow(
          context,
          label: 'Light/Dark Mode',
          child: GameToggle<ThemeMode>(
            value: settings.themeMode,
            options: const [
              GameToggleOption(value: ThemeMode.light, label: 'LIGHT'),
              GameToggleOption(value: ThemeMode.dark, label: 'DARK'),
            ],
            onChanged: settings.setThemeMode,
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // HELPER: Build section header
  // ---------------------------------------------------------------------------

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 1,
          color: AppTheme.accentColor(context).withValues(alpha: 0.3),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(title, style: AppTypography.subheading(context)),
        ),
        Expanded(
          child: Container(
            height: 1,
            color: AppTheme.accentColor(context).withValues(alpha: 0.3),
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // HELPER: Build Spider-specific suit count toggle
  // ---------------------------------------------------------------------------

  Widget _buildSpiderSuitToggle(
    BuildContext context,
    SettingsProvider settings,
  ) {
    final accent = settings.currentTheme.accentColor;

    return GameToggle<Difficulty>(
      value: settings.difficulty,
      options: [
        GameToggleOption(
            value: Difficulty.easy, label: '1 Suit', color: accent),
        GameToggleOption(
            value: Difficulty.medium, label: '2 Suits', color: accent),
        GameToggleOption(
            value: Difficulty.hard, label: '4 Suits', color: accent),
      ],
      onChanged: (difficulty) {
        settings.setDifficulty(difficulty);
        // Difficulty will be applied when a new game starts
        _showSettingsChangedSnackBar(context);
      },
    );
  }

  // ---------------------------------------------------------------------------
  // HELPER: Build scoring mode dropdown
  // ---------------------------------------------------------------------------

  Widget _buildScoringDropdown(
      BuildContext context, SettingsProvider settings) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.buttonColor(context),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppTheme.buttonBorderColor(context),
          width: 1,
        ),
      ),
      child: DropdownButton<ScoringMode>(
        value: settings.scoringMode,
        onChanged: (ScoringMode? newValue) {
          if (newValue != null) {
            settings.setScoringMode(newValue);
            _showSettingsChangedSnackBar(context);
          }
        },
        items: ScoringMode.values
            .map<DropdownMenuItem<ScoringMode>>((ScoringMode value) {
          return DropdownMenuItem<ScoringMode>(
            value: value,
            child: Text(
              value.displayName,
              style: AppTypography.body(context),
            ),
          );
        }).toList(),
        underline: const SizedBox.shrink(),
        icon: Icon(
          Icons.arrow_drop_down,
          color: AppTheme.accentColor(context),
        ),
        dropdownColor: AppTheme.toolbarColor(context),
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }
}
