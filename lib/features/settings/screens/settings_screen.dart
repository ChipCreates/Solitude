import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart'; // Added for SVG rendering
import 'package:provider/provider.dart';
import '../services/settings_provider.dart';
import 'package:solitude/features/game/services/game_controller.dart';
import 'package:solitude/core/theme/app_theme.dart';
import '../models/difficulty.dart';
import '../models/theme_preset.dart';
// ignore: unused_import
import '../models/hint_mode.dart';
// ignore: unused_import
import '../../game/models/victory_pattern.dart';

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
  const SettingsScreen({super.key});

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
        children: const [
          _AppearanceTab(),
          _CardsTab(),
          _GameplayTab(),
          _SoundTab(),
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
// GAMEPLAY TAB
// ============================================================================

class _GameplayTab extends StatelessWidget {
  const _GameplayTab();

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
                label: 'Difficulty',
                subtitle: settings.difficulty.description,
                child: Builder(builder: (ctx) {
                  final accent = settings.currentTheme.accentColor;
                  return GameToggle<Difficulty>(
                    value: settings.difficulty,
                    options: [
                      GameToggleOption(
                          value: Difficulty.easy, label: 'EASY', color: accent),
                      GameToggleOption(
                          value: Difficulty.medium,
                          label: 'MED',
                          color: accent),
                      GameToggleOption(
                          value: Difficulty.hard, label: 'HARD', color: accent),
                    ],
                    onChanged: (difficulty) {
                      settings.setDifficulty(difficulty);
                      context
                          .read<GameController>()
                          .game
                          .applyDifficulty(difficulty);
                    },
                  );
                }),
              ),
              const SizedBox(height: 20),
              _buildSettingRow(
                context,
                label: 'Scoring Mode',
                subtitle: settings.scoringMode.description,
                child: Builder(builder: (ctx) {
                  final accent = settings.currentTheme.accentColor;
                  return GameToggle<ScoringMode>(
                    value: settings.scoringMode,
                    options: [
                      GameToggleOption(
                          value: ScoringMode.standard,
                          label: 'STD',
                          color: accent),
                      GameToggleOption(
                          value: ScoringMode.vegas,
                          label: 'VEGAS',
                          color: accent),
                    ],
                    onChanged: settings.setScoringMode,
                  );
                }),
              ),
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
              const SizedBox(height: 20),
              _buildSettingRow(
                context,
                label: 'Sound Effects',
                subtitle: 'Play audio feedback',
                child: GameSwitch(
                  value: settings.soundEnabled,
                  onChanged: settings.setSoundEnabled,
                ),
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
                    onChanged: (value) {
                      settings.setSoundVolume(value);
                    },
                  ),
                ),
              ),
              const SizedBox(height: 20),
              _buildSettingRow(
                context,
                label: 'Background Music',
                subtitle: 'Play music during the game',
                child: GameSwitch(
                  value: settings.musicEnabled,
                  onChanged: (value) {
                    settings.setMusicEnabled(value);
                  },
                ),
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
                    onChanged: (value) {
                      settings.setMusicVolume(value);
                    },
                  ),
                ),
              ),
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
}
