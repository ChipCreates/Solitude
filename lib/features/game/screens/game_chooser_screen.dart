import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../games/game_factory.dart';
import 'package:solitude/core/theme/app_theme.dart';
import 'package:solitude/features/settings/services/settings_provider.dart';
import 'package:solitude/features/statistics/services/statistics_service.dart';
import '../services/board_layout_service.dart';
import '../services/game_controller.dart';
import '../services/animation_state_notifier.dart';
import '../services/hint_state_notifier.dart';
import '../services/selection_state_notifier.dart';
import '../services/timer_state_notifier.dart';
import '../services/game_state_repository.dart';
import 'package:solitude/core/services/audio_service.dart';
import '../services/game_audio_observer.dart';
import 'game_screen.dart';

/// Initial game chooser screen displayed on app launch.
/// Shows all 10 solitaire variants in a responsive grid of cards.
class GameChooserScreen extends StatefulWidget {
  const GameChooserScreen({super.key});

  @override
  State<GameChooserScreen> createState() => _GameChooserScreenState();
}

class _GameChooserScreenState extends State<GameChooserScreen> {
  @override
  Widget build(BuildContext context) {
    // Determine grid columns based on screen width for responsiveness
    final screenWidth = MediaQuery.of(context).size.width;
    final crossAxisCount = screenWidth > 900 ? 5 : (screenWidth > 600 ? 4 : 2);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppTheme.backgroundColor(context),
              AppTheme.backgroundColor(context).withValues(alpha: 0.8),
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                const SizedBox(height: 32),
                Text(
                  'Choose Your Game',
                  style: AppTypography.heading(context),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Select a solitaire variant to play',
                  style: AppTypography.body(context).copyWith(
                    color: AppTheme.textColor(context).withValues(alpha: 0.7),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                Expanded(
                  child: GridView.builder(
                    physics: const BouncingScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossAxisCount,
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 16,
                      childAspectRatio: 0.72, // Taller cards for image + text
                    ),
                    itemCount: GameType.values.length,
                    itemBuilder: (context, index) {
                      final gameType = GameType.values[index];
                      return _GameCard(
                        gameType: gameType,
                        onSelected: () => _selectGame(context, gameType),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _selectGame(BuildContext context, GameType gameType) {
    // Capture required providers BEFORE navigating to avoid "deactivated widget" errors
    final settings = context.read<SettingsProvider>();
    final statistics = context.read<StatisticsService>();
    final boardLayout = context.read<BoardLayoutService>();
    final audioService = context.read<GameAudioService>();
    final animationState = context.read<AnimationStateNotifier>();
    final hintState = context.read<HintStateNotifier>();
    final selectionState = context.read<SelectionStateNotifier>();
    final timerState = context.read<TimerStateNotifier>();
    final gameStateRepository = context.read<GameStateRepository>();

    // Navigate to game screen
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => ChangeNotifierProvider<GameController>(
          create: (ctx) {
            final controller = GameController(
              settingsProvider: settings,
              statisticsService: statistics,
              animationState: animationState,
              hintState: hintState,
              selectionState: selectionState,
              timerState: timerState,
              boardLayout: boardLayout,
              gameType: gameType,
              gameStateRepository: gameStateRepository,
            );

            // Audio synchronization logic
            final audioObserver = GameAudioObserver(audioService);
            audioObserver.attach(controller);

            // Sync initial settings
            audioService.setEnabled(settings.soundEnabled);
            audioService.setVolume(settings.soundVolume);

            return controller;
          },
          child: GameScreen(gameType: gameType),
        ),
      ),
    );
  }
}

/// Individual game card widget with Title → Image → Description layout
class _GameCard extends StatefulWidget {
  const _GameCard({
    required this.gameType,
    required this.onSelected,
  });

  final GameType gameType;
  final VoidCallback onSelected;

  @override
  State<_GameCard> createState() => _GameCardState();
}

class _GameCardState extends State<_GameCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final accentColor = AppTheme.accentColor(context);

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onSelected,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          decoration: BoxDecoration(
            color: _isHovered
                ? accentColor.withValues(alpha: 0.15)
                : AppTheme.toolbarColor(context).withValues(alpha: 0.95),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _isHovered
                  ? accentColor.withValues(alpha: 0.7)
                  : accentColor.withValues(alpha: 0.3),
              width: _isHovered ? 2.5 : 1.5,
            ),
            boxShadow: _isHovered
                ? [
                    BoxShadow(
                      color: accentColor.withValues(alpha: 0.25),
                      blurRadius: 16,
                      spreadRadius: 2,
                    ),
                  ]
                : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
          ),
          transform: _isHovered
              ? (Matrix4.identity()..setTranslationRaw(0.0, -4.0, 0.0))
              : Matrix4.identity(),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // 1. TITLE at top
                Text(
                  widget.gameType.displayName,
                  style: AppTypography.subheading(context).copyWith(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: _isHovered ? accentColor : null,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),

                // 2. IMAGE in center (with icon fallback) - 16:9 aspect ratio
                AspectRatio(
                  aspectRatio: 16 / 9,
                  child: _GamePreviewImage(
                    gameType: widget.gameType,
                    isHovered: _isHovered,
                  ),
                ),
                const SizedBox(height: 12),

                // 3. DESCRIPTION at bottom - shows full text
                Expanded(
                  child: Text(
                    widget.gameType.description,
                    style: AppTypography.body(context).copyWith(
                      fontSize: 12,
                      height: 1.3,
                      color: AppTheme.textColor(context).withValues(alpha: 0.7),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Game preview image widget with icon fallback
/// Attempts to load image from assets/games/{game_type}.png
/// Falls back to icon if image not found
class _GamePreviewImage extends StatelessWidget {
  final GameType gameType;
  final bool isHovered;

  const _GamePreviewImage({
    required this.gameType,
    required this.isHovered,
  });

  @override
  Widget build(BuildContext context) {
    final accentColor = AppTheme.accentColor(context);

    // Image path follows pattern: assets/games/klondike.png
    final imagePath = 'assets/games/${gameType.name}.png';

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: isHovered
            ? accentColor.withValues(alpha: 0.1)
            : AppTheme.backgroundColor(context).withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: accentColor.withValues(alpha: 0.15),
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(11),
        child: Image.asset(
          imagePath,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            // Fallback to icon when image not found
            return _IconFallback(
              gameType: gameType,
              isHovered: isHovered,
            );
          },
        ),
      ),
    );
  }
}

/// Icon fallback widget when game preview image is not available
class _IconFallback extends StatelessWidget {
  final GameType gameType;
  final bool isHovered;

  const _IconFallback({
    required this.gameType,
    required this.isHovered,
  });

  @override
  Widget build(BuildContext context) {
    final accentColor = AppTheme.accentColor(context);

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: isHovered ? 0.2 : 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _getGameIcon(gameType),
              color:
                  isHovered ? accentColor : accentColor.withValues(alpha: 0.7),
              size: 40,
            ),
          ),
        ],
      ),
    );
  }

  /// Returns an appropriate icon for each game type
  IconData _getGameIcon(GameType gameType) {
    switch (gameType) {
      case GameType.klondike:
        return Icons.style; // Classic card stack
      case GameType.spider:
        return Icons.pest_control; // Spider icon
      case GameType.freecell:
        return Icons.grid_view; // Grid for free cells
      case GameType.pyramid:
        return Icons.change_history; // Triangle/pyramid
      case GameType.triPeaks:
        return Icons.landscape; // Mountains/peaks
      case GameType.golf:
        return Icons.golf_course; // Golf course
      case GameType.yukon:
        return Icons.terrain; // Mountain terrain
      case GameType.fortyThieves:
        return Icons.shield; // Thieves theme
      case GameType.canfield:
        return Icons.casino; // Casino origin
      case GameType.scorpion:
        return Icons.flare; // Scorpion stinger
    }
  }
}
