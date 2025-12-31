import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../services/game_controller.dart';
import '../services/animation_state_notifier.dart';
import '../services/timer_state_notifier.dart';
import 'package:solitude/features/settings/services/settings_provider.dart';
import 'package:solitude/core/theme/app_theme.dart';
import 'package:solitude/core/widgets/game_button.dart';
import 'package:solitude/core/widgets/game_toolbar.dart';
import '../widgets/game_board.dart';
import '../widgets/victory_overlay.dart';
import '../widgets/animated_card_overlay.dart';
import '../widgets/victory_card_animation.dart';
import '../models/victory_pattern.dart' as settings_victory;
import '../widgets/auto_finish_fab.dart';
import 'package:solitude/features/settings/screens/settings_screen.dart';
import 'package:solitude/features/statistics/screens/statistics_screen.dart';
import 'package:solitude/features/home/widgets/game_selector_sheet.dart';
import '../games/game_factory.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({super.key, required this.gameType});

  final GameType gameType;

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    // Request focus when the screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    // Only handle key down events
    if (event is! KeyDownEvent) return KeyEventResult.ignored;

    final controller = context.read<GameController>();
    final settings = context.read<SettingsProvider>();

    // Handle Tab navigation
    if (event.logicalKey == LogicalKeyboardKey.tab) {
      if (HardwareKeyboard.instance.isShiftPressed) {
        controller.cycleFocusBackward();
      } else {
        controller.cycleFocusForward();
      }
      return KeyEventResult.handled;
    }

    // Handle Enter/Space to activate focused pile
    if (event.logicalKey == LogicalKeyboardKey.enter ||
        event.logicalKey == LogicalKeyboardKey.space) {
      controller.activateFocusedPile();
      return KeyEventResult.handled;
    }

    // Handle keyboard shortcuts
    if (event.logicalKey == LogicalKeyboardKey.keyU ||
        (event.logicalKey == LogicalKeyboardKey.keyZ &&
            HardwareKeyboard.instance.isControlPressed)) {
      // Undo
      if (controller.canUndo) {
        controller.undo();
        return KeyEventResult.handled;
      }
    } else if (event.logicalKey == LogicalKeyboardKey.keyN) {
      // New Game
      _confirmNewGame(context, controller);
      return KeyEventResult.handled;
    } else if (event.logicalKey == LogicalKeyboardKey.keyH) {
      // Show Hint
      controller.showHint();
      return KeyEventResult.handled;
    } else if (event.logicalKey == LogicalKeyboardKey.keyA) {
      // Toggle Autoplay (only if enabled in settings)
      if (settings.autoplay) {
        controller.toggleAutoplay();
        return KeyEventResult.handled;
      }
    } else if (event.logicalKey == LogicalKeyboardKey.escape) {
      // Toggle Settings
      _showSettings(context);
      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      focusNode: _focusNode,
      onKeyEvent: _handleKeyEvent,
      child: Scaffold(
        body: Stack(
          children: [
            // Main game - toolbar rebuilds only on move count changes, board uses granular selectors
            Column(
              children: [
                Selector<GameController, int>(
                  selector: (_, controller) => controller.moveCount,
                  builder: (context, moveCount, _) {
                    final controller = context.read<GameController>();
                    return GameToolbar(
                      controller: controller,
                      onMenuPressed: () => _showSettings(context),
                      onNewGame: () => _confirmNewGame(context, controller),
                      onStatsPressed: () => _showStatistics(context),
                    );
                  },
                ),
                const Expanded(
                  child: GameBoard(),
                ),
              ],
            ),

            // Card animation overlay - only rebuilds when animation state changes
            Consumer<AnimationStateNotifier>(
              builder: (context, animationState, _) {
                return AnimatedCardOverlay(
                  animationData: animationState.cardAnimationData,
                  onComplete: () {
                    final controller = context.read<GameController>();
                    controller.clearCardAnimation();
                  },
                );
              },
            ),

            // Win overlay - only rebuilds when game state changes
            Consumer<GameController>(
              builder: (context, controller, _) {
                if (!controller.isWon) return const SizedBox.shrink();

                return Consumer<TimerStateNotifier>(
                  builder: (context, timerState, _) {
                    return VictoryOverlay(
                      onNewGame: () => controller.newGame(),
                      elapsed: timerState.elapsed,
                      moves: controller.moveCount,
                      foundationPiles: controller.foundations,
                      forcePattern: (() {
                        final settingsVictoryPattern =
                            Provider.of<SettingsProvider>(context,
                                    listen: false)
                                .victoryPattern;
                        if (settingsVictoryPattern ==
                            settings_victory.VictoryPattern.random) {
                          return null;
                        }
                        // Map to widget VictoryPattern (skip random, so index -1)
                        const widgetPatterns = VictoryPattern
                            .values; // from victory_card_animation.dart
                        final mappedIndex = settingsVictoryPattern.index - 1;
                        return mappedIndex >= 0 &&
                                mappedIndex < widgetPatterns.length
                            ? widgetPatterns[mappedIndex]
                            : null;
                      })(),
                    );
                  },
                );
              },
            ),

            // Lost overlay - only rebuilds when game state changes
            Consumer<GameController>(
              builder: (context, controller, _) {
                if (controller.state != GameState.lost) {
                  return const SizedBox.shrink();
                }

                return Center(
                  child: Dialog(
                    backgroundColor: Colors.transparent,
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: AppTheme.toolbarColor(context)
                            .withValues(alpha: 0.98),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                            color: AppTheme.accentColor(context)
                                .withValues(alpha: 0.3)),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('No more moves — You lost',
                              style: AppTypography.subheading(context)),
                          const SizedBox(height: 12),
                          Text('There are no legal moves left.',
                              style: AppTypography.body(context).copyWith(
                                  color: AppTheme.textColor(context)
                                      .withValues(alpha: 0.7))),
                          const SizedBox(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              GameButton(
                                  label: 'Dismiss',
                                  onPressed: () => controller.clearLoss()),
                              GameButton(
                                  label: 'New Game',
                                  isPrimary: true,
                                  onPressed: () => controller.newGame()),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),

            // Auto Finish FAB - positioned bottom-right
            const Positioned(
              bottom: 16,
              right: 16,
              child: AutoFinishFab(),
            ),
          ],
        ),
      ),
    );
  }

  void _showSettings(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const SettingsScreen()),
    );
  }

  void _showStatistics(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => const StatisticsBottomSheet(),
      ),
    );
  }

  void _confirmNewGame(BuildContext context, GameController controller) {
    if (controller.moveCount == 0 || controller.isWon) {
      // Show game selector for fresh game
      _showGameSelector(context, controller);
      return;
    }

    showDialog(
      context: context,
      builder: (context) => _NewGameDialog(
        onConfirm: () {
          Navigator.pop(context);
          // Show game selector after confirmation
          _showGameSelector(context, controller);
        },
        onCancel: () => Navigator.pop(context),
      ),
    );
  }

  void _showGameSelector(BuildContext context, GameController controller) {
    showModalBottomSheet<GameType>(
      context: context,
      isScrollControlled: true,
      builder: (context) => const GameSelectorSheet(),
    ).then((selectedGameType) {
      if (selectedGameType != null) {
        controller.startNewGame(selectedGameType);
      }
    });
  }
}

class _NewGameDialog extends StatelessWidget {
  final VoidCallback onConfirm;
  final VoidCallback onCancel;

  const _NewGameDialog({
    required this.onConfirm,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppTheme.toolbarColor(context).withValues(alpha: 0.98),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppTheme.accentColor(context).withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Start New Game?',
              style: AppTypography.subheading(context),
            ),
            const SizedBox(height: 12),
            Text(
              'Your current game will be lost.',
              style: AppTypography.body(context).copyWith(
                color: AppTheme.textColor(context).withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                GameButton(
                  label: 'Cancel',
                  onPressed: onCancel,
                ),
                GameButton(
                  label: 'New Game',
                  onPressed: onConfirm,
                  isPrimary: true,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
