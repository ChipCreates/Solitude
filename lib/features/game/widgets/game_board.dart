import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/pile_render_data.dart';
import '../services/game_controller.dart';
import 'package:solitude/features/settings/services/settings_provider.dart';
import 'pile_widget.dart';
import 'card_widget.dart';
import 'game_layout_delegate.dart';

class GameBoard extends StatefulWidget {
  const GameBoard({super.key});

  @override
  State<GameBoard> createState() => _GameBoardState();
}

class _GameBoardState extends State<GameBoard> {
  // Cache for layout calculation memoization
  BoxConstraints? _lastConstraints;
  BoardLayoutData? _cachedLayout;

  // Get the appropriate layout delegate for the current game
  GameLayoutDelegate _getLayoutDelegate(GameController controller) {
    return createLayoutDelegate(controller);
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<GameController>(
      builder: (context, controller, _) {
        return LayoutBuilder(
          builder: (context, constraints) {
            final layout = _calculateLayout(constraints, controller);
            return Container(
              decoration: _buildFeltBackground(context),
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  layout.padding + 24, // Left padding
                  layout.padding,
                  layout.padding + 24, // Right padding (equal to left)
                  layout.padding,
                ),
                child: Column(
                  children: [
                    // Top row: Delegated to strategy (listen to settings changes for leftHandMode)
                    Consumer<SettingsProvider>(
                      builder: (context, settings, _) {
                        return _getLayoutDelegate(controller)
                            .buildTopRow(context, controller, layout);
                      },
                    ),
                    SizedBox(height: layout.rowSpacing),
                    // Tableau - uses Selectors for granular rebuilds
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
    debugPrint('Building felt background with theme: ${theme.name}');

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

  Widget _buildTableau(
      BuildContext context, GameController controller, BoardLayoutData layout) {
    // Only build as many piles as the controller has, up to column count
    // This allows the layout to adapt if the game state doesn't match the delegate's expectation
    // (though in a correct implementation they should match)
    final tableauCount = controller.tableau.length;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Tableau piles - each wrapped in Selector for granular rebuilds
        for (int i = 0; i < tableauCount; i++) ...[
          SizedBox(
            width: layout.cardWidth,
            child: _TableauPileSelector(
              pileIndex: i,
              cardWidth: layout.cardWidth,
              stackOffset: layout.stackOffset,
            ),
          ),
          if (i < tableauCount - 1) SizedBox(width: layout.pileSpacing),
        ],
      ],
    );
  }

  BoardLayoutData _calculateLayout(
      BoxConstraints constraints, GameController controller) {
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

    // Dynamic column count from delegate
    final int columns = _getLayoutDelegate(controller).columnCount;
    final int gaps = columns - 1;

    // availableWidth = columns * cardWidth + gaps * spacing
    // spacing = 0.15 * cardWidth
    // availableWidth = columns * cardWidth + gaps * 0.15 * cardWidth
    // availableWidth = cardWidth * (columns + gaps * 0.15)

    final denominator = columns + (gaps * 0.15);
    final cardWidth =
        (availableWidth / denominator).clamp(minCardWidth, maxCardWidth);
    final pileSpacing = cardWidth * 0.15;

    final cardHeight = cardWidth / CardWidget.aspectRatio;

    // Calculate stack offset based on available vertical space
    final topRowHeight = cardHeight;
    // Increased from 0.02 to 0.04 for more space between top row and tableau
    final rowSpacing = constraints.maxHeight * 0.04;
    final availableTableauHeight =
        constraints.maxHeight - topRowHeight - rowSpacing - (padding * 2);

    // Max cards in a tableau pile after dealing: 7 + (remaining deck if all went to one pile)
    // Realistically, aim for ~20 cards visible
    const maxVisibleCards = 20;
    final stackOffset = (availableTableauHeight - cardHeight) / maxVisibleCards;
    final clampedStackOffset =
        stackOffset.clamp(cardHeight * 0.15, cardHeight * 0.28);

    // Cache the computed layout
    _cachedLayout = BoardLayoutData(
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

/// Selector widget that only rebuilds a TableauPileWidget when its specific data changes.
/// This prevents the entire board from rebuilding when unrelated state changes.
class _TableauPileSelector extends StatelessWidget {
  final int pileIndex;
  final double cardWidth;
  final double stackOffset;

  const _TableauPileSelector({
    required this.pileIndex,
    required this.cardWidth,
    required this.stackOffset,
  });

  @override
  Widget build(BuildContext context) {
    return Selector<GameController, TableauPileRenderData>(
      selector: (_, controller) {
        final pile = controller.tableau[pileIndex];
        return TableauPileRenderData(
          pile: pile,
          pileVersion: pile.version,
          isHintDestination: controller.hintDestinationPile == pile,
          isHintSource: controller.hintSourcePile == pile,
          isFocused: controller.focusedPile == pile,
          selectedCards: controller.selectedCards,
          selectedPile: controller.selectedPile,
          hintCards: controller.hintCards,
          animatingCard: controller.animatingCard,
        );
      },
      builder: (context, data, _) {
        final controller = Provider.of<GameController>(context, listen: false);
        return Container(
          key: controller.boardLayout.getKeyForPileId(data.pile.id),
          child: TableauPileWidget(
            pile: data.pile,
            cardWidth: cardWidth,
            stackOffset: stackOffset,
            controller: controller,
          ),
        );
      },
    );
  }
}
