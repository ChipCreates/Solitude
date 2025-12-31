import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:hive_flutter/hive_flutter.dart';

// Core imports
import 'core/theme/app_theme.dart';
import 'core/services/svg_preload_service.dart';
import 'core/services/audio_service.dart';
import 'core/services/desktop_window_service.dart';

// Feature imports - Settings
import 'features/settings/services/settings_provider.dart';

// Feature imports - Statistics
import 'features/statistics/services/statistics_service.dart';

// Feature imports - Game
import 'features/game/services/board_layout_service.dart';
import 'features/game/services/animation_state_notifier.dart';
import 'features/game/services/hint_state_notifier.dart';
import 'features/game/services/selection_state_notifier.dart';
import 'features/game/services/timer_state_notifier.dart';

// Feature imports - Achievements
import 'features/achievements/services/achievement_service.dart';
import 'features/achievements/models/achievement.dart';
import 'features/achievements/models/achievement_category_adapter.dart';

// Feature imports - Home
import 'features/home/screens/loading_splash_screen.dart';
import 'features/home/widgets/app_startup_wrapper.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Configure desktop window (minimum size, aspect ratio) before showing UI
  await DesktopWindowService.initialize();

  // Show splash screen immediately while we preload assets
  runApp(const LoadingSplashScreen());

  // Preload assets and initialize app asynchronously
  _initializeApp();
}

Future<void> _initializeApp() async {
  // Start timing to ensure minimum splash screen duration
  final startTime = DateTime.now();
  const minSplashDuration = Duration(seconds: 5);

  // Lock orientation to allow both portrait and landscape
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  // Preload SVG card assets to eliminate startup jank
  // This prevents the expensive SVG parsing from happening during first render
  await SvgPreloadService.preloadCardSvg();

  // Initialize Hive for local lightweight storage
  await Hive.initFlutter();
  Hive.registerAdapter(AchievementAdapter());
  Hive.registerAdapter(AchievementCategoryAdapter());
  await Hive.openBox('statistics');

  // Initialize achievement service
  final achievementService = AchievementService();
  await achievementService.initialize();

  // Initialize services
  final settingsProvider = SettingsProvider();
  await settingsProvider.loadSettings();

  final statisticsService = StatisticsService();
  await statisticsService.loadStatistics();

  final boardLayoutService = BoardLayoutService();

  // Initialize audio service with graceful degradation
  final audioService = GameAudioService();
  try {
    await audioService.initialize();
    audioService.setEnabled(settingsProvider.soundEnabled);
    audioService.setVolume(settingsProvider.soundVolume);
    audioService.setMusicEnabled(settingsProvider.musicEnabled);
    audioService.setMusicVolume(settingsProvider.musicVolume);
  } catch (e) {
    // Audio initialization failed - disable audio features gracefully
    // The game will continue to function without sound
    debugPrint('Audio initialization failed: $e');
    audioService.setEnabled(false);
    audioService.setMusicEnabled(false);
  }

  // Ensure splash screen displays for minimum duration
  final elapsed = DateTime.now().difference(startTime);
  if (elapsed < minSplashDuration) {
    await Future.delayed(minSplashDuration - elapsed);
  }

  // Start background music after splash screen (ignore errors)
  try {
    await audioService.startBackgroundMusic();
  } catch (e) {
    debugPrint('Failed to start background music: $e');
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: settingsProvider),
        ChangeNotifierProvider.value(value: statisticsService),
        ChangeNotifierProvider(create: (_) => AnimationStateNotifier()),
        ChangeNotifierProvider(create: (_) => HintStateNotifier()),
        ChangeNotifierProvider(create: (_) => SelectionStateNotifier()),
        ChangeNotifierProvider(create: (_) => TimerStateNotifier()),
        Provider.value(value: boardLayoutService),
        Provider.value(value: audioService),
        Provider.value(value: achievementService),
      ],
      child: const SolitudeApp(),
    ),
  );
}

class SolitudeApp extends StatelessWidget {
  const SolitudeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, settings, _) {
        final themePreset = settings.currentTheme;

        return MaterialApp(
          title: 'Solitude',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light(themePreset),
          darkTheme: AppTheme.dark(themePreset),
          themeMode: settings.themeMode,
          home: const AppStartupWrapper(),
        );
      },
    );
  }
}
