import 'package:flutter/material.dart';
import 'package:solitude/core/theme/app_theme.dart';
import 'package:solitude/core/widgets/game_button.dart';
import '../../../features/game/games/game_factory.dart';

/// Bottom sheet modal for selecting which solitaire game to play.
/// Displays all 10 game variants in a 5x2 grid of cards (5 columns, 2 rows).
class GameSelectorSheet extends StatelessWidget {
  const GameSelectorSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
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
          const SizedBox(height: 20),

          // 5x2 Grid of game cards (5 columns, 2 rows)
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 5,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 0.85, // Taller cards for compact layout
            children: GameType.values.map((gameType) {
              return _GameCard(
                gameType: gameType,
                icon: _getGameIcon(gameType),
                title: gameType.displayName,
                subtitle: _getShortDescription(gameType),
                onTap: () => Navigator.pop(context, gameType),
              );
            }).toList(),
          ),

          const SizedBox(height: 20),

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

  /// Returns an appropriate icon for each game type
  IconData _getGameIcon(GameType gameType) {
    switch (gameType) {
      case GameType.klondike:
        return Icons.style; // Classic card stack
      case GameType.spider:
        return Icons.pest_control; // Spider icon
      case GameType.freecell:
        return Icons.grid_view; // Grid for free cells
      case GameType.pyramid:
        return Icons.change_history; // Triangle/pyramid
      case GameType.triPeaks:
        return Icons.landscape; // Mountains/peaks
      case GameType.golf:
        return Icons.golf_course; // Golf course
      case GameType.yukon:
        return Icons.terrain; // Mountain terrain
      case GameType.fortyThieves:
        return Icons.shield; // Thieves theme
      case GameType.canfield:
        return Icons.casino; // Casino origin
      case GameType.scorpion:
        return Icons.flare; // Scorpion stinger
    }
  }

  /// Returns a brief one-sentence description for each game type
  String _getShortDescription(GameType gameType) {
    switch (gameType) {
      case GameType.klondike:
        return 'Classic Solitaire';
      case GameType.spider:
        return 'Build full suits';
      case GameType.freecell:
        return 'Strategic cells';
      case GameType.pyramid:
        return 'Match to 13';
      case GameType.triPeaks:
        return 'Clear 3 peaks';
      case GameType.golf:
        return 'Score lowest';
      case GameType.yukon:
        return 'Free movement';
      case GameType.fortyThieves:
        return 'Two-deck hard';
      case GameType.canfield:
        return 'Casino style';
      case GameType.scorpion:
        return 'K to A suits';
    }
  }
}

/// Individual compact game card widget for the 5x2 grid
class _GameCard extends StatelessWidget {
  final GameType gameType;
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _GameCard({
    required this.gameType,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppTheme.backgroundColor(context).withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: AppTheme.accentColor(context).withValues(alpha: 0.2),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icon
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppTheme.accentColor(context).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(
                icon,
                color: AppTheme.accentColor(context),
                size: 18,
              ),
            ),
            const SizedBox(height: 6),
            // Title
            Text(
              title,
              style: AppTypography.label(context).copyWith(
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 2),
            // Subtitle
            Text(
              subtitle,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 9,
                height: 1.2,
                color: AppTheme.textColor(context).withValues(alpha: 0.6),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
