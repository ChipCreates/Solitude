import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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
import '../achievements/services/achievement_service.dart';
import '../achievements/services/achievement_observer.dart';
import '../screens/game_chooser_screen.dart';
import '../screens/game_screen.dart';
import '../screens/loading_splash_screen.dart';
import '../games/game_factory.dart';

class AppStartupWrapper extends StatefulWidget {
  const AppStartupWrapper({super.key});

  @override
  State<AppStartupWrapper> createState() => _AppStartupWrapperState();
}

class _AppStartupWrapperState extends State<AppStartupWrapper> {
  bool _isLoading = true;
  bool? _hasSavedGame;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    // Simulate loading assets/settings (in real app this would be actual loading)
    await Future.delayed(const Duration(seconds: 2));

    // Mock saved game check - in real implementation, check SettingsProvider or saved game state
    _hasSavedGame = false; // Mock: no saved game

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
    if (_hasSavedGame == true) {
      // Navigate to GameScreen with saved game type (mocking klondike for now)
      return _buildGameProvider(GameType.klondike);
    } else {
      // Navigate to GameChooserScreen
      return const GameChooserScreen();
    }
  }

  Widget _buildGameProvider(GameType gameType) {
    final settings = context.read<SettingsProvider>();
    final statistics = context.read<StatisticsService>();
    final boardLayout = context.read<BoardLayoutService>();
    final audioService = context.read<GameAudioService>();
    final achievementService = context.read<AchievementService>();

    return ChangeNotifierProvider<GameController>(
      create: (ctx) {
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
