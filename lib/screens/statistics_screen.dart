import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/statistics_service.dart';
import '../theme/app_theme.dart';

/// Bottom sheet version of statistics (new default)
class StatisticsBottomSheet extends StatelessWidget {
  const StatisticsBottomSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<StatisticsService>(
      builder: (context, statsService, _) {
        final stats = statsService.statistics;
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: Column(
            children: [
              // Header with drag handle
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: Theme.of(context).dividerColor,
                    ),
                  ),
                ),
                child: Column(
                  children: [
                    // Drag handle
                    Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    Row(
                      children: [
                        const Icon(Icons.bar_chart),
                        const SizedBox(width: 12),
                        Text(
                          'Statistics',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _statRow(context, 'Games Played', stats.gamesPlayed.toString()),
                      _statRow(context, 'Games Won', stats.gamesWon.toString()),
                      _statRow(context, 'Games Lost', stats.gamesLost.toString()),
                      _statRow(context, 'Win %', '${stats.winPercentage.toStringAsFixed(1)}%'),
                      _statRow(context, 'Current Streak', stats.currentStreak.toString()),
                      _statRow(context, 'Best Streak', stats.bestStreak.toString()),
                      const SizedBox(height: 20),
                      Text('Best Time: ${stats.bestTime != null ? "${stats.bestTime!.inMinutes}m" : "--"}', style: AppTypography.body(context)),
                      const SizedBox(height: 8),
                      Text('Fewest Moves: ${stats.fewestMoves ?? "--"}', style: AppTypography.body(context)),
                      const SizedBox(height: 32),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          ElevatedButton(
                            onPressed: () => statsService.resetStatistics(),
                            child: const Text('Reset'),
                          ),
                          ElevatedButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Close'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _statRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTypography.label(context)),
          Text(value, style: AppTypography.statValue(context)),
        ],
      ),
    );
  }
}

/// Full screen version of statistics (kept for compatibility)
class StatisticsScreen extends StatelessWidget {
  const StatisticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<StatisticsService>(
      builder: (context, statsService, _) {
        final stats = statsService.statistics;
        return Scaffold(
          appBar: AppBar(
            title: const Text('Statistics'),
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            elevation: 0,
            iconTheme: IconThemeData(color: AppTheme.textColor(context)),
            foregroundColor: AppTheme.textColor(context),
          ),
          body: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _statRow(context, 'Games Played', stats.gamesPlayed.toString()),
                _statRow(context, 'Games Won', stats.gamesWon.toString()),
                _statRow(context, 'Games Lost', stats.gamesLost.toString()),
                _statRow(context, 'Win %', '${stats.winPercentage.toStringAsFixed(1)}%'),
                _statRow(context, 'Current Streak', stats.currentStreak.toString()),
                _statRow(context, 'Best Streak', stats.bestStreak.toString()),
                const SizedBox(height: 20),
                Text('Best Time: ${stats.bestTime != null ? "${stats.bestTime!.inMinutes}m" : "--"}', style: AppTypography.body(context)),
                const SizedBox(height: 8),
                Text('Fewest Moves: ${stats.fewestMoves ?? "--"}', style: AppTypography.body(context)),
                const Spacer(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    ElevatedButton(
                      onPressed: () => statsService.resetStatistics(),
                      child: const Text('Reset'),
                    ),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Close'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _statRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTypography.label(context)),
          Text(value, style: AppTypography.statValue(context)),
        ],
      ),
    );
  }
}
