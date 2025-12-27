import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/card.dart';
import '../models/difficulty.dart';
import '../services/game_controller.dart';
import '../services/settings_provider.dart';
import 'pile_widget.dart';
import 'card_widget.dart';

class GameBoard extends StatefulWidget {
  const GameBoard({super.key});

  @override
  State<GameBoard> createState() => _GameBoardState();
}

class _GameBoardState extends State<GameBoard> {
  // Cache for layout calculation memoization
  BoxConstraints? _lastConstraints;
  _BoardLayout? _cachedLayout;

  @override
  void initState() {
    super.initState();
    // Initialize pile keys after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final controller = Provider.of<GameController>(context, listen: false);
      controller.initializePileKeys();
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final layout = _calculateLayout(constraints);
        return Consumer<GameController>(
          builder: (context, controller, _) {
            return Container(
              decoration: _buildFeltBackground(context),
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  layout.padding + 24,  // Left padding
                  layout.padding,
                  layout.padding + 24,  // Right padding (equal to left)
                  layout.padding,
                ),
                child: Column(
                  children: [
                    // Top row: Stock, Waste, spacer, Foundations
                    _buildTopRow(context, controller, layout),
                    SizedBox(height: layout.rowSpacing),
                    // Tableau
                    Expanded(
                      child: _buildTableau(context, controller, layout),
                    ),
                  ],
                ),
              ),
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
    final darkerColor = isDark ? theme.toolbarColorDark : theme.toolbarColorLight;
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
          darkerColor.withValues(alpha:0.8),
        ],
        stops: const [0.0, 0.5, 1.0],
      ),
    );
  }
  
  Widget _buildTopRow(BuildContext context, GameController controller, _BoardLayout layout) {
    // Calculate the width of the first 3 tableau piles section
    final first3Width = layout.cardWidth * 3 + layout.pileSpacing * 2;
    final stockPile = controller.stock;
    final wastePile = controller.waste;
    final settings = Provider.of<SettingsProvider>(context, listen: false);

    return SizedBox(
      height: layout.cardHeight,
      child: Row(
        children: [
          // Stock (only show if game has stock)
          if (stockPile != null)
            SizedBox(
              width: layout.cardWidth,
              child: Container(
                key: controller.getKeyForPile(stockPile),
                child: StockPileWidget(
                  pile: stockPile,
                  cardWidth: layout.cardWidth,
                  controller: controller,
                ),
              ),
            ),
          if (stockPile != null) SizedBox(width: layout.pileSpacing),
          // Waste (only show if game has waste)
          if (wastePile != null)
            SizedBox(
              width: layout.cardWidth,
              child: Container(
                key: controller.getKeyForPile(wastePile),
                child: WastePileWidget(
                  pile: wastePile,
                  cardWidth: layout.cardWidth,
                  spreadCount: settings.difficulty.drawMode.drawCount,
                  controller: controller,
                ),
              ),
            ),
          // Spacer to fill remaining space in "first 3 piles" section
          SizedBox(width: first3Width - (layout.cardWidth * 2 + layout.pileSpacing)),
          SizedBox(width: layout.pileSpacing),
          // Foundations aligned with last 4 tableau piles
          for (int i = 0; i < controller.foundations.length; i++) ...[
            SizedBox(
              width: layout.cardWidth,
              child: Container(
                key: controller.getKeyForPile(controller.foundations[i]),
                child: FoundationPileWidget(
                  pile: controller.foundations[i],
                  cardWidth: layout.cardWidth,
                  suit: Suit.values[i],
                  controller: controller,
                ),
              ),
            ),
            if (i < controller.foundations.length - 1) SizedBox(width: layout.pileSpacing),
          ],
        ],
      ),
    );
  }

  Widget _buildTableau(BuildContext context, GameController controller, _BoardLayout layout) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // All 7 tableau piles evenly spaced
        for (int i = 0; i < 7; i++) ...[
          SizedBox(
            width: layout.cardWidth,
            child: Container(
              key: controller.getKeyForPile(controller.tableau[i]),
              child: TableauPileWidget(
                pile: controller.tableau[i],
                cardWidth: layout.cardWidth,
                stackOffset: layout.stackOffset,
                controller: controller,
              ),
            ),
          ),
          if (i < 6) SizedBox(width: layout.pileSpacing),
        ],
      ],
    );
  }
  
  _BoardLayout _calculateLayout(BoxConstraints constraints) {
    // Return cached layout if constraints haven't changed
    if (_lastConstraints == constraints && _cachedLayout != null) {
      return _cachedLayout!;
    }

    // Store new constraints
    _lastConstraints = constraints;

    const double minCardWidth = 50.0;
    const double maxCardWidth = 150.0;
    const double padding = 8.0;

    // Available width for cards (accounting for extra left/right padding)
    final availableWidth = constraints.maxWidth - ((padding + 24) * 2);

    // Simple tableau layout: 7 cards + 6 gaps
    // availableWidth = 7 * cardWidth + 6 * spacing
    // spacing = 0.15 * cardWidth (slightly wider gaps for better appearance)
    // availableWidth = 7 * cardWidth + 6 * 0.15 * cardWidth
    // availableWidth = 7 * cardWidth + 0.9 * cardWidth
    // availableWidth = 7.9 * cardWidth

    final cardWidth = (availableWidth / 7.9).clamp(minCardWidth, maxCardWidth);
    final pileSpacing = cardWidth * 0.15;

    final cardHeight = cardWidth / CardWidget.aspectRatio;

    // Calculate stack offset based on available vertical space
    final topRowHeight = cardHeight;
    // Increased from 0.02 to 0.04 for more space between top row and tableau
    final rowSpacing = constraints.maxHeight * 0.04;
    final availableTableauHeight = constraints.maxHeight - topRowHeight - rowSpacing - (padding * 2);

    // Max cards in a tableau pile after dealing: 7 + (remaining deck if all went to one pile)
    // Realistically, aim for ~20 cards visible
    const maxVisibleCards = 20;
    final stackOffset = (availableTableauHeight - cardHeight) / maxVisibleCards;
    final clampedStackOffset = stackOffset.clamp(cardHeight * 0.15, cardHeight * 0.28);

    // Cache the computed layout
    _cachedLayout = _BoardLayout(
      cardWidth: cardWidth,
      cardHeight: cardHeight,
      pileSpacing: pileSpacing,
      stackOffset: clampedStackOffset,
      rowSpacing: rowSpacing,
      padding: padding,
    );

    return _cachedLayout!;
  }
}

class _BoardLayout {
  final double cardWidth;
  final double cardHeight;
  final double pileSpacing;
  final double stackOffset;
  final double rowSpacing;
  final double padding;
  
  const _BoardLayout({
    required this.cardWidth,
    required this.cardHeight,
    required this.pileSpacing,
    required this.stackOffset,
    required this.rowSpacing,
    required this.padding,
  });
}
