import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:solitude/features/game/services/board_layout_service.dart';
import 'package:solitude/features/game/services/game_controller.dart';
import 'package:solitude/features/settings/services/settings_provider.dart';
import 'package:solitude/features/statistics/services/statistics_service.dart';
import 'package:solitude/features/game/services/animation_state_notifier.dart';
import 'package:solitude/features/game/services/hint_state_notifier.dart';
import 'package:solitude/features/game/services/selection_state_notifier.dart';
import 'package:solitude/features/game/services/timer_state_notifier.dart';
import 'package:solitude/core/theme/app_theme.dart';
import 'package:solitude/features/settings/models/theme_preset.dart';
import 'package:solitude/features/game/games/game_factory.dart';

import 'mocks.dart';

/// Test harness for widget tests
///
/// Provides a properly configured widget tree with all necessary providers
/// for testing Solitude widgets in isolation.
class TestHarness {
  /// Build a test widget with all necessary providers
  ///
  /// [child] - The widget to test
  /// [controller] - Optional GameController (uses mock if not provided)
  /// [settings] - Optional SettingsProvider (uses mock if not provided)
  /// [statistics] - Optional StatisticsService (uses mock if not provided)
  /// [animationState] - Optional AnimationStateNotifier
  /// [hintState] - Optional HintStateNotifier
  /// [selectionState] - Optional SelectionStateNotifier
  /// [timerState] - Optional TimerStateNotifier
  /// [themeMode] - Theme mode for the app (defaults to dark)
  static Widget buildTestWidget(
    Widget child, {
    GameController? controller,
    SettingsProvider? settings,
    StatisticsService? statistics,
    AnimationStateNotifier? animationState,
    HintStateNotifier? hintState,
    SelectionStateNotifier? selectionState,
    TimerStateNotifier? timerState,
    ThemeMode themeMode = ThemeMode.dark,
  }) {
    final effectiveSettings = settings ?? MockSettingsProvider();
    final effectiveStats = statistics ?? MockStatisticsService();
    final effectiveAnimationState = animationState ?? AnimationStateNotifier();
    final effectiveHintState = hintState ?? HintStateNotifier();
    final effectiveSelectionState = selectionState ?? SelectionStateNotifier();
    final effectiveTimerState = timerState ?? TimerStateNotifier();

    final effectiveController = controller ??
        GameController(
          settingsProvider: effectiveSettings,
          statisticsService: effectiveStats,
          animationState: effectiveAnimationState,
          hintState: effectiveHintState,
          selectionState: effectiveSelectionState,
          timerState: effectiveTimerState,
          boardLayout: BoardLayoutService(),
          gameType: GameType.klondike,
          audioService: MockGameAudioService(),
        );

    return MaterialApp(
      theme: AppTheme.light(ThemePreset.defaultTheme),
      darkTheme: AppTheme.dark(ThemePreset.defaultTheme),
      themeMode: themeMode,
      home: MultiProvider(
        providers: [
          ChangeNotifierProvider<SettingsProvider>.value(
              value: effectiveSettings),
          ChangeNotifierProvider<StatisticsService>.value(
              value: effectiveStats),
          ChangeNotifierProvider<AnimationStateNotifier>.value(
              value: effectiveAnimationState),
          ChangeNotifierProvider<HintStateNotifier>.value(
              value: effectiveHintState),
          ChangeNotifierProvider<SelectionStateNotifier>.value(
              value: effectiveSelectionState),
          ChangeNotifierProvider<TimerStateNotifier>.value(
              value: effectiveTimerState),
          ChangeNotifierProvider<GameController>.value(
              value: effectiveController),
        ],
        child: Scaffold(body: child),
      ),
    );
  }

  /// Build a minimal test widget without providers
  ///
  /// Useful for testing widgets that don't need the full provider tree.
  static Widget buildMinimalWidget(Widget child,
      {ThemeMode themeMode = ThemeMode.dark}) {
    return MaterialApp(
      theme: AppTheme.light(ThemePreset.defaultTheme),
      darkTheme: AppTheme.dark(ThemePreset.defaultTheme),
      themeMode: themeMode,
      home: Scaffold(body: child),
    );
  }

  /// Create a GameController with mocked dependencies
  ///
  /// Useful when you need to manipulate the controller before building widgets.
  static GameController createMockController({
    MockSettingsProvider? settings,
    MockStatisticsService? statistics,
    AnimationStateNotifier? animationState,
    HintStateNotifier? hintState,
    SelectionStateNotifier? selectionState,
    TimerStateNotifier? timerState,
    BoardLayoutService? boardLayout,
  }) {
    return GameController(
      settingsProvider: settings ?? MockSettingsProvider(),
      statisticsService: statistics ?? MockStatisticsService(),
      animationState: animationState ?? AnimationStateNotifier(),
      hintState: hintState ?? HintStateNotifier(),
      selectionState: selectionState ?? SelectionStateNotifier(),
      timerState: timerState ?? TimerStateNotifier(),
      boardLayout: boardLayout ?? BoardLayoutService(),
      gameType: GameType.klondike,
      audioService: MockGameAudioService(),
    );
  }
}

/// Extension methods for WidgetTester to simplify common test patterns
extension TestHarnessExtensions on WidgetTester {
  /// Pump a widget with the test harness and wait for animations
  Future<void> pumpHarnessedWidget(
    Widget child, {
    GameController? controller,
    SettingsProvider? settings,
    Duration? duration,
  }) async {
    await pumpWidget(
      TestHarness.buildTestWidget(
        child,
        controller: controller,
        settings: settings,
      ),
    );
    if (duration != null) {
      await pump(duration);
    }
  }

  /// Get the GameController from the current widget tree
  GameController getController() {
    final element = this.element(find.byType(MaterialApp));
    return Provider.of<GameController>(element, listen: false);
  }

  /// Get the SettingsProvider from the current widget tree
  SettingsProvider getSettings() {
    final element = this.element(find.byType(MaterialApp));
    return Provider.of<SettingsProvider>(element, listen: false);
  }
}
