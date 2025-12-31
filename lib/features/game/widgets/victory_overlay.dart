import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/pile.dart';
import 'victory_card_animation.dart';
import 'package:solitude/core/theme/app_theme.dart';
import 'package:solitude/features/settings/services/settings_provider.dart';

/// Victory overlay that combines spectacular card physics animation
/// with celebration UI elements (stats, play again button).
class VictoryOverlay extends StatelessWidget {
  final VoidCallback onNewGame;
  final Duration elapsed;
  final int moves;
  final List<Pile> foundationPiles;
  final VictoryPattern? forcePattern; // For debugging specific patterns

  const VictoryOverlay({
    super.key,
    required this.onNewGame,
    required this.elapsed,
    required this.moves,
    required this.foundationPiles,
    this.forcePattern,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Physics-based card animation background
        VictoryCardAnimation(
          foundationPiles: foundationPiles,
          forcePattern: forcePattern,
        ),

        // Victory celebration overlay
        Center(
          child: Container(
            margin: const EdgeInsets.all(32),
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: () {
                final settings =
                    Provider.of<SettingsProvider>(context, listen: false);
                final theme = settings.currentTheme;
                final isDark = Theme.of(context).brightness == Brightness.dark;
                final tableColor =
                    isDark ? theme.tableColorDark : theme.tableColorLight;
                return tableColor.withValues(alpha: 0.95);
              }(),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.gold.withValues(alpha: 0.5),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.5),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'You Won!',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: AppColors.gold,
                  ),
                ),
                const SizedBox(height: 24),
                _buildStatRow('Time', _formatDuration(elapsed)),
                const SizedBox(height: 8),
                _buildStatRow('Moves', '$moves'),
                const SizedBox(height: 32),
                GestureDetector(
                  onTap: onNewGame,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.gold.withValues(alpha: 0.3),
                          AppColors.gold.withValues(alpha: 0.2),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: AppColors.gold.withValues(alpha: 0.5),
                      ),
                    ),
                    child: const Text(
                      'Play Again',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.cream,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '$label: ',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 18,
            color: AppColors.cream.withValues(alpha: 0.7),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.cream,
          ),
        ),
      ],
    );
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
}
