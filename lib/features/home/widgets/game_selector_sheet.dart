import 'package:flutter/material.dart';
import 'package:solitude/core/theme/app_theme.dart';
import 'package:solitude/core/widgets/game_button.dart';
import '../../../features/game/games/game_factory.dart';

/// Bottom sheet modal for selecting which solitaire game to play
class GameSelectorSheet extends StatelessWidget {
  const GameSelectorSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.toolbarColor(context).withValues(alpha: 0.98),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        border: Border.all(
          color: AppTheme.accentColor(context).withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Row(
            children: [
              Container(
                width: 24,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.accentColor(context).withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 16),
              Text(
                'Choose Game',
                style: AppTypography.subheading(context),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Game Options
          _buildGameOption(
            context,
            gameType: GameType.klondike,
            icon: Icons.grid_on,
            title: 'Klondike',
            subtitle: 'Classic Solitaire with 7 tableau piles',
          ),
          const SizedBox(height: 16),
          _buildGameOption(
            context,
            gameType: GameType.spider,
            icon: Icons.bug_report,
            title: 'Spider',
            subtitle: 'Advanced solitaire with 10 tableau piles',
          ),

          const SizedBox(height: 32),

          // Cancel button
          GameButton(
            label: 'Cancel',
            onPressed: () => Navigator.pop(context),
            width: double.infinity,
          ),
        ],
      ),
    );
  }

  Widget _buildGameOption(
    BuildContext context, {
    required GameType gameType,
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return GestureDetector(
      onTap: () => Navigator.pop(context, gameType),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppTheme.backgroundColor(context).withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppTheme.accentColor(context).withValues(alpha: 0.2),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppTheme.accentColor(context).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: AppTheme.accentColor(context),
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTypography.label(context),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      color: AppTheme.textColor(context).withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: AppTheme.accentColor(context).withValues(alpha: 0.5),
            ),
          ],
        ),
      ),
    );
  }
}
