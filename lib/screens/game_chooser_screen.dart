import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../games/game_factory.dart';
import '../theme/app_theme.dart';
import '../services/settings_provider.dart';
import '../services/statistics_service.dart';
import '../services/board_layout_service.dart';
import '../services/game_controller.dart';
import '../services/animation_state_notifier.dart';
import '../services/hint_state_notifier.dart';
import '../services/selection_state_notifier.dart';
import '../services/timer_state_notifier.dart';
import '../services/audio_service.dart';
import '../services/game_audio_observer.dart';
import 'game_screen.dart';

class GameChooserScreen extends StatelessWidget {
  const GameChooserScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppTheme.backgroundColor(context),
              AppTheme.backgroundColor(context).withValues(alpha:0.8),
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                const SizedBox(height: 40),
                Text(
                  'Choose Your Game',
                  style: AppTypography.heading(context),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Select a solitaire variant to play',
                  style: AppTypography.body(context).copyWith(
                    color: AppTheme.textColor(context).withValues(alpha:0.7),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 48),
                Expanded(
                  child: ListView(
                    children: [
                      _GameOption(
                        gameType: GameType.klondike,
                        onSelected: () => _selectGame(context, GameType.klondike),
                      ),
                      const SizedBox(height: 16),
                      _GameOption(
                        gameType: GameType.spider,
                        onSelected: () => _selectGame(context, GameType.spider),
                        disabled: true,
                      ),
                    ],
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
    if (gameType == GameType.spider) return; // Spider is disabled for now

    // Build the game screen with its own provider
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => _buildGameScreen(gameType),
      ),
    );
  }

  Widget _buildGameScreen(GameType gameType) {
    return Consumer4<SettingsProvider, StatisticsService, BoardLayoutService, GameAudioService>(
      builder: (context, settings, statistics, boardLayout, audioService, _) {
        final controller = GameController(
          settingsProvider: settings,
          statisticsService: statistics,
          animationState: context.read<AnimationStateNotifier>(),
          hintState: context.read<HintStateNotifier>(),
          selectionState: context.read<SelectionStateNotifier>(),
          timerState: context.read<TimerStateNotifier>(),
          boardLayout: boardLayout,
          gameType: gameType,
        );

        // Audio synchronization logic
        final audioObserver = GameAudioObserver(audioService);
        audioObserver.attach(controller);

        // Sync initial settings and listen for changes
        void syncAudio() {
          audioService.setEnabled(settings.soundEnabled);
          audioService.setVolume(settings.soundVolume);
        }

        syncAudio();
        settings.addListener(syncAudio);

        return ChangeNotifierProvider<GameController>.value(
          value: controller,
          child: GameScreen(gameType: gameType),
        );
      },
    );
  }
}

class _GameOption extends StatelessWidget {
  const _GameOption({
    required this.gameType,
    required this.onSelected,
    this.disabled = false,
  });

  final GameType gameType;
  final VoidCallback onSelected;
  final bool disabled;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: disabled ? 0.5 : 1.0,
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.toolbarColor(context).withValues(alpha:0.95),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppTheme.accentColor(context).withValues(alpha:disabled ? 0.3 : 0.5),
            width: 2,
          ),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: disabled ? null : onSelected,
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          gameType.displayName,
                          style: AppTypography.subheading(context),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          gameType.description,
                          style: AppTypography.body(context).copyWith(
                            color: AppTheme.textColor(context).withValues(alpha:0.7),
                          ),
                        ),
                        if (disabled) ...[
                          const SizedBox(height: 8),
                          Text(
                            'Coming Soon',
                            style: AppTypography.caption(context).copyWith(
                              color: AppTheme.accentColor(context),
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Icon(
                    disabled ? Icons.lock : Icons.play_arrow,
                    color: AppTheme.accentColor(context),
                    size: 32,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}