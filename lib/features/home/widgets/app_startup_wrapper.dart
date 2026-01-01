import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:solitude/features/settings/services/settings_provider.dart';
import 'package:solitude/features/statistics/services/statistics_service.dart';
import 'package:solitude/features/game/services/board_layout_service.dart';
import 'package:solitude/features/game/services/game_controller.dart';
import 'package:solitude/features/game/services/animation_state_notifier.dart';
import 'package:solitude/features/game/services/hint_state_notifier.dart';
import 'package:solitude/features/game/services/selection_state_notifier.dart';
import 'package:solitude/features/game/services/timer_state_notifier.dart';
import 'package:solitude/features/game/services/game_state_repository.dart';
import 'package:solitude/core/services/audio_service.dart';
import 'package:solitude/features/game/services/game_audio_observer.dart';
import 'package:solitude/features/achievements/services/achievement_service.dart';
import 'package:solitude/features/achievements/services/achievement_observer.dart';
import 'package:solitude/features/game/screens/game_chooser_screen.dart';
import 'package:solitude/features/game/screens/game_screen.dart';
import '../screens/loading_splash_screen.dart';
import 'package:solitude/features/game/games/game_factory.dart';
import 'package:solitude/features/game/games/game_interface.dart';

class AppStartupWrapper extends StatefulWidget {
  const AppStartupWrapper({super.key});

  @override
  State<AppStartupWrapper> createState() => _AppStartupWrapperState();
}

class _AppStartupWrapperState extends State<AppStartupWrapper> {
  bool _isLoading = true;
  bool _hasSavedGame = false;
  SavedGameState? _savedGameState;
  GameType? _savedGameType;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    // Check for saved game state
    final gameStateRepository = context.read<GameStateRepository>();

    try {
      _hasSavedGame = await gameStateRepository.hasSavedGame();
      if (_hasSavedGame) {
        _savedGameType = await gameStateRepository.getSavedGameType();
        _savedGameState = await gameStateRepository.loadGame();
      }
    } catch (e) {
      debugPrint('Failed to check for saved game: $e');
      _hasSavedGame = false;
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const LoadingSplashScreen();
    }

    // Decision logic
    if (_hasSavedGame && _savedGameType != null && _savedGameState != null) {
      // Navigate to GameScreen with restored game
      return _buildGameProviderWithSavedState(_savedGameType!, _savedGameState!);
    } else {
      // Navigate to GameChooserScreen
      return const GameChooserScreen();
    }
  }

  Widget _buildGameProviderWithSavedState(GameType gameType, SavedGameState savedState) {
    final settings = context.read<SettingsProvider>();
    final statistics = context.read<StatisticsService>();
    final boardLayout = context.read<BoardLayoutService>();
    final audioService = context.read<GameAudioService>();
    final achievementService = context.read<AchievementService>();
    final gameStateRepository = context.read<GameStateRepository>();

    return ChangeNotifierProvider<GameController>(
      create: (ctx) {
        // Restore game from saved state
        final restoredGame = gameStateRepository.restoreGame(savedState);

        final controller = GameController(
          settingsProvider: settings,
          statisticsService: statistics,
          animationState: context.read<AnimationStateNotifier>(),
          hintState: context.read<HintStateNotifier>(),
          selectionState: context.read<SelectionStateNotifier>(),
          timerState: context.read<TimerStateNotifier>(),
          boardLayout: boardLayout,
          gameType: gameType,
          gameStateRepository: gameStateRepository,
          restoredGame: restoredGame,
          restoredElapsedTime: savedState.elapsedTime,
        );

        // Audio synchronization logic
        final audioObserver = GameAudioObserver(audioService);
        audioObserver.attach(controller);

        // Achievement observer
        final achievementObserver = AchievementObserver(achievementService);
        achievementObserver.startObserving(controller.gameEvents);

        // Sync initial settings
        audioService.setEnabled(settings.soundEnabled);
        audioService.setVolume(settings.soundVolume);

        return controller;
      },
      child: GameScreen(gameType: gameType),
    );
  }
}
