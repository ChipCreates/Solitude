import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../layouts/layouts.dart';
import '../services/game_controller.dart';
import 'package:solitude/features/settings/services/settings_provider.dart';

/// The main game board widget that renders the playing surface.
///
/// This widget is game-agnostic - it delegates ALL layout decisions to
/// the appropriate [LayoutStrategy] based on the current game type.
///
/// Architecture (Option B - Raw Constraints):
/// - GameBoard handles only the felt background decoration
/// - Each strategy receives raw [BoxConstraints] and has full autonomy over:
///   - Card size calculations
///   - Spacing and positioning
///   - Widget structure (Column, Row, Stack, etc.)
/// - Grid strategies use [GridLayoutMixin] for common calculations
/// - Non-grid strategies (Pyramid, TriPeaks) calculate their own metrics
///
/// This design allows:
/// - Pyramid to calculate only what Pyramid needs
/// - Spider to use 10 columns without special-casing in GameBoard
/// - Future games to implement completely custom layouts
class GameBoard extends StatefulWidget {
  const GameBoard({super.key});

  @override
  State<GameBoard> createState() => _GameBoardState();
}

class _GameBoardState extends State<GameBoard> {
  // Cache the layout strategy to avoid recreating on every build
  LayoutStrategy? _cachedStrategy;
  Object? _lastGameType;

  /// Get the appropriate layout strategy for the current game.
  /// Caches the strategy and only recreates when game type changes.
  LayoutStrategy _getLayoutStrategy(GameController controller) {
    final currentGameType = controller.game.gameType;
    if (_cachedStrategy == null || _lastGameType != currentGameType) {
      _cachedStrategy = LayoutStrategyFactory.create(controller);
      _lastGameType = currentGameType;
    }
    return _cachedStrategy!;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<GameController>(
      builder: (context, controller, _) {
        return LayoutBuilder(
          builder: (context, constraints) {
            final strategy = _getLayoutStrategy(controller);

            return Container(
              decoration: _buildFeltBackground(context),
              // Strategy owns ALL layout decisions - just pass raw constraints
              child: strategy.buildLayout(context, controller, constraints),
            );
          },
        );
      },
    );
  }

  BoxDecoration _buildFeltBackground(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final settings = Provider.of<SettingsProvider>(context);
    final theme = settings.currentTheme;

    // Get theme-specific colors
    final baseColor = theme.getTableColor(Theme.of(context).brightness);
    final darkerColor =
        isDark ? theme.toolbarColorDark : theme.toolbarColorLight;
    final highlightColor = isDark
        ? baseColor.withValues(alpha: 0.3)
        : baseColor.withValues(alpha: 0.5);

    return BoxDecoration(
      // Base color
      color: baseColor,
      // Radial gradient for depth - lighter in center, darker at edges
      gradient: RadialGradient(
        center: const Alignment(0, -0.3), // Slightly above center
        radius: 1.2,
        colors: [
          highlightColor,
          baseColor,
          darkerColor.withValues(alpha: 0.8),
        ],
        stops: const [0.0, 0.5, 1.0],
      ),
    );
  }
}
