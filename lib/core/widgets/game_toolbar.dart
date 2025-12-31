import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:solitude/core/theme/app_theme.dart';
import 'package:solitude/core/widgets/game_button.dart';
import 'package:solitude/core/widgets/move_history_viewer.dart';
import 'package:solitude/features/game/services/game_controller.dart';
import 'package:solitude/features/game/services/timer_state_notifier.dart';
import 'package:solitude/features/settings/services/settings_provider.dart';
import 'package:solitude/features/settings/models/difficulty.dart';
import 'package:solitude/features/home/screens/help_screen.dart';

class GameToolbar extends StatelessWidget {
  final GameController controller;
  final VoidCallback onMenuPressed;
  final VoidCallback onNewGame;
  final VoidCallback? onStatsPressed;

  const GameToolbar({
    super.key,
    required this.controller,
    required this.onMenuPressed,
    required this.onNewGame,
    this.onStatsPressed,
  });

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsProvider>(context);
    final theme = settings.currentTheme;
    final brightness = Theme.of(context).brightness;
    final toolbarColor = brightness == Brightness.dark
        ? theme.toolbarColorDark
        : theme.toolbarColorLight;

    return Container(
      height: 80,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            toolbarColor,
            toolbarColor.withValues(alpha: 0.9),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              // New Game - far left with fat plus icon
              GameIconButton(
                icon: Icons.add_box,
                onPressed: onNewGame,
                tooltip: 'New Game',
                label: 'New',
              ),
              const SizedBox(width: 12),
              _buildUndoRedoButtons(controller),
              const SizedBox(width: 12),
              // Hint button
              GameIconButton(
                icon: Icons.lightbulb_outline,
                onPressed: controller.state == GameState.playing
                    ? () => controller.showHint()
                    : null,
                tooltip: 'Show hint',
                label: 'Hint',
              ),
              const SizedBox(width: 12),
              // Move history button
              _buildButtonWithBadge(
                button: GameIconButton(
                  icon: Icons.history,
                  onPressed: () => _showMoveHistory(context, controller),
                  tooltip: 'View move history',
                  label: 'History',
                ),
                count: controller.moveHistory.length,
              ),
              const SizedBox(width: 12),
              // Autoplay control: only visible when autoplay feature is enabled in settings
              Consumer<SettingsProvider>(
                builder: (context, settings, _) {
                  if (!settings.autoplay) return const SizedBox.shrink();
                  final isRunning = controller.state == GameState.autoplaying;
                  return Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: GameIconButton(
                      icon: isRunning ? Icons.pause : Icons.play_arrow,
                      onPressed: () => controller.toggleAutoplay(),
                      tooltip: isRunning ? 'Stop Autoplay' : 'Start Autoplay',
                      label: isRunning ? 'Pause' : 'Play',
                    ),
                  );
                },
              ),
              const Spacer(),
              _buildGameInfo(context),
              const SizedBox(width: 16),
              // Difficulty indicator
              Consumer<SettingsProvider>(
                builder: (context, settings, _) {
                  return _buildDifficultyIndicator(
                      context, settings.difficulty);
                },
              ),
              const Spacer(),
              if (onStatsPressed != null) ...[
                GameIconButton(
                  icon: Icons.bar_chart,
                  onPressed: onStatsPressed,
                  tooltip: 'Statistics',
                  label: 'Stats',
                ),
                const SizedBox(width: 12),
              ],
              GameIconButton(
                icon: Icons.help_outline,
                onPressed: () {
                  Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const HelpScreen()));
                },
                tooltip: 'How to Play',
                label: 'Help',
              ),
              const SizedBox(width: 12),
              // Settings - far right with gear icon
              GameIconButton(
                icon: Icons.settings,
                onPressed: onMenuPressed,
                tooltip: 'Settings',
                label: 'Settings',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUndoRedoButtons(GameController controller) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Undo button with badge
        _buildButtonWithBadge(
          button: GameIconButton(
            icon: Icons.undo,
            onPressed: controller.canUndo ? controller.undo : null,
            tooltip: 'Undo last move',
            label: 'Undo',
          ),
          count: controller.moveHistory.length,
        ),
        const SizedBox(width: 8),
        // Redo button with badge
        _buildButtonWithBadge(
          button: GameIconButton(
            icon: Icons.redo,
            onPressed: controller.canRedo ? controller.redo : null,
            tooltip: 'Redo last undone move',
            label: 'Redo',
          ),
          count: controller.redoHistory.length,
        ),
      ],
    );
  }

  Widget _buildButtonWithBadge({required Widget button, required int count}) {
    if (count == 0) {
      return button;
    }

    return Stack(
      clipBehavior: Clip.none,
      children: [
        button,
        Positioned(
          right: -4,
          top: -4,
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: const BoxDecoration(
              color: Colors.red,
              shape: BoxShape.circle,
            ),
            constraints: const BoxConstraints(
              minWidth: 18,
              minHeight: 18,
            ),
            child: Center(
              child: Text(
                count > 99 ? '99+' : count.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _showMoveHistory(BuildContext context, GameController controller) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: Theme.of(context).dividerColor,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.history),
                    const SizedBox(width: 12),
                    Text(
                      'Move History',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              // History list
              Expanded(
                child: MoveHistoryViewerWithJump(
                  controller: controller,
                  scrollController: scrollController,
                  onClose: () => Navigator.pop(context),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGameInfo(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Timer - only rebuilds when timer ticks
        Consumer<TimerStateNotifier>(
          builder: (context, timerState, _) {
            return _buildInfoItem(
              context,
              icon: Icons.timer_outlined,
              value: _formatDuration(timerState.elapsed),
            );
          },
        ),
        const SizedBox(width: 20),
        _buildInfoItem(
          context,
          icon: Icons.touch_app_outlined,
          value: controller.moveCount.toString(),
        ),
      ],
    );
  }

  Widget _buildInfoItem(BuildContext context,
      {required IconData icon, required String value}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18, color: AppTheme.mutedTextColor(context)),
        const SizedBox(width: 4),
        Text(value, style: AppTypography.label(context)),
      ],
    );
  }

  Widget _buildDifficultyIndicator(
      BuildContext context, Difficulty difficulty) {
    final brightness = Theme.of(context).brightness;
    Color textColor;
    if (brightness == Brightness.dark) {
      textColor = Colors.white;
    } else {
      textColor = difficulty.color.computeLuminance() < 0.5
          ? Colors.white
          : Colors.black;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: difficulty.color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: difficulty.color.withValues(alpha: 0.4),
          width: 1,
        ),
      ),
      child: Text(
        difficulty.shortName,
        style: TextStyle(
          fontFamily: 'Inter',
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
          color: textColor,
        ),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
}
