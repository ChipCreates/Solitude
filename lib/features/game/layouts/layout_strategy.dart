import 'package:flutter/material.dart';
import '../games/game_interface.dart';
import '../services/game_controller.dart';
import '../widgets/card_widget.dart';

/// Represents a card's position in a stack-based layout.
/// Used for games like Pyramid, TriPeaks, Golf that require absolute positioning.
class CardPosition {
  /// X coordinate (0.0 = left edge, 1.0 = right edge of board)
  final double x;

  /// Y coordinate (0.0 = top edge, 1.0 = bottom edge of board)
  final double y;

  /// Z-index for overlapping cards (higher = on top)
  final int zIndex;

  /// The pile this card belongs to
  final String pileId;

  /// Index of this card within the pile
  final int cardIndex;

  const CardPosition({
    required this.x,
    required this.y,
    required this.zIndex,
    required this.pileId,
    required this.cardIndex,
  });

  /// Convert normalized coordinates to actual pixel positions
  Offset toOffset(Size boardSize, double cardWidth, double cardHeight) {
    return Offset(
      x * (boardSize.width - cardWidth),
      y * (boardSize.height - cardHeight),
    );
  }
}

/// Abstract base class for layout strategies.
///
/// Layout strategies determine how cards are positioned on the game board.
/// Each game type can specify its own layout strategy to support:
/// - Grid layouts (Klondike, Spider, Freecell)
/// - Stack layouts with absolute positioning (Pyramid, TriPeaks, Golf)
/// - Future custom layouts (spiral, tree, etc.)
///
/// The strategy receives raw [BoxConstraints] and has full control over
/// how to calculate card sizes, spacing, and positioning. This allows
/// non-grid games like Pyramid to use completely different layout logic.
abstract class LayoutStrategy {
  /// The layout configuration from the game
  final LayoutConfig config;

  const LayoutStrategy(this.config);

  /// Build the complete game layout widget.
  ///
  /// This is the main entry point called by GameBoard.
  /// The strategy receives raw constraints and has full autonomy over:
  /// - Card size calculations
  /// - Spacing and positioning
  /// - Widget structure (Column, Row, Stack, etc.)
  ///
  /// [context] - Build context for accessing theme, providers, etc.
  /// [controller] - Game controller for accessing piles and game state
  /// [constraints] - Raw box constraints from the parent layout
  Widget buildLayout(
    BuildContext context,
    GameController controller,
    BoxConstraints constraints,
  );
}

/// Computed layout metrics for grid-based games.
/// Used internally by GridLayoutMixin - not exposed to GameBoard.
class GridLayoutMetrics {
  final double cardWidth;
  final double cardHeight;
  final double pileSpacing;
  final double stackOffset;
  final double rowSpacing;
  final double padding;
  final Size boardSize;

  const GridLayoutMetrics({
    required this.cardWidth,
    required this.cardHeight,
    required this.pileSpacing,
    required this.stackOffset,
    required this.rowSpacing,
    required this.padding,
    required this.boardSize,
  });
}

/// Mixin providing common grid layout calculations.
///
/// Grid-based games (Klondike, Spider, Freecell) can use this mixin
/// to share the standard card sizing and spacing logic.
mixin GridLayoutMixin on LayoutStrategy {
  /// Number of columns in the tableau for card width calculations.
  /// Override for games with different column counts.
  int get columnCount => config.tableauCount;

  /// Standard horizontal padding added to left and right edges.
  double get horizontalPadding => 24.0;

  /// Base padding around the board.
  double get basePadding => 8.0;

  /// Calculate grid layout metrics from raw constraints.
  GridLayoutMetrics calculateGridMetrics(BoxConstraints constraints) {
    const double minCardWidth = 50.0;
    const double maxCardWidth = 150.0;

    // Available width for cards (accounting for extra left/right padding)
    final availableWidth =
        constraints.maxWidth - ((basePadding + horizontalPadding) * 2);

    // Calculate card width based on column count
    final int columns = columnCount;
    final int gaps = columns - 1;

    // availableWidth = columns * cardWidth + gaps * spacing
    // spacing = 0.15 * cardWidth
    // availableWidth = cardWidth * (columns + gaps * 0.15)
    final denominator = columns + (gaps * 0.15);
    final cardWidth =
        (availableWidth / denominator).clamp(minCardWidth, maxCardWidth);
    final pileSpacing = cardWidth * 0.15;

    final cardHeight = cardWidth / CardWidget.aspectRatio;

    // Calculate stack offset based on available vertical space
    final topRowHeight = cardHeight;
    final rowSpacing = constraints.maxHeight * 0.04;
    final availableTableauHeight =
        constraints.maxHeight - topRowHeight - rowSpacing - (basePadding * 2);

    // Aim for ~20 cards visible in a tableau pile
    const maxVisibleCards = 20;
    final stackOffset =
        (availableTableauHeight - cardHeight) / maxVisibleCards;
    final clampedStackOffset =
        stackOffset.clamp(cardHeight * 0.15, cardHeight * 0.28);

    return GridLayoutMetrics(
      cardWidth: cardWidth,
      cardHeight: cardHeight,
      pileSpacing: pileSpacing,
      stackOffset: clampedStackOffset,
      rowSpacing: rowSpacing,
      padding: basePadding,
      boardSize: Size(constraints.maxWidth, constraints.maxHeight),
    );
  }

  /// Build padding widget that wraps content with standard grid padding.
  Widget buildGridPadding({required Widget child}) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        basePadding + horizontalPadding,
        basePadding,
        basePadding + horizontalPadding,
        basePadding,
      ),
      child: child,
    );
  }
}
