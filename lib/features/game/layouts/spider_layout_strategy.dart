import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/pile_render_data.dart';
import '../services/game_controller.dart';
import '../widgets/pile_widget.dart';
import 'layout_strategy.dart';

/// Layout strategy for Spider solitaire.
///
/// Layout structure:
/// - Top row: Stock only (no waste, no visible foundations)
/// - Bottom: 10 tableau columns
///
/// Spider uses 2 decks (104 cards), 10 tableau piles, and completed sequences
/// are automatically removed to foundation piles (which are not displayed).
///
/// Uses [GridLayoutMixin] for standard card sizing and spacing calculations,
/// with column count overridden to 10 for Spider's wider tableau.
class SpiderLayoutStrategy extends LayoutStrategy with GridLayoutMixin {
  const SpiderLayoutStrategy(super.config);

  /// Spider has 10 tableau columns instead of the default 7.
  @override
  int get columnCount => 10;

  @override
  Widget buildLayout(
    BuildContext context,
    GameController controller,
    BoxConstraints constraints,
  ) {
    // Calculate grid metrics from raw constraints
    final metrics = calculateGridMetrics(constraints);

    return buildGridPadding(
      child: Column(
        children: [
          // Top row with stock only
          _buildTopRow(context, controller, metrics),
          SizedBox(height: metrics.rowSpacing),
          // Tableau
          Expanded(
            child: _buildTableau(context, controller, metrics),
          ),
        ],
      ),
    );
  }

  Widget _buildTopRow(
    BuildContext context,
    GameController controller,
    GridLayoutMetrics metrics,
  ) {
    final stockPile = controller.stock;

    return SizedBox(
      height: metrics.cardHeight,
      child: Row(
        children: [
          // Stock pile on the left
          if (config.hasStock && stockPile != null)
            SizedBox(
              width: metrics.cardWidth,
              child: _StockPileSelector(cardWidth: metrics.cardWidth),
            ),
          // Fill rest of row (empty space where completed sequences could be shown)
          Expanded(child: Container()),
        ],
      ),
    );
  }

  Widget _buildTableau(
    BuildContext context,
    GameController controller,
    GridLayoutMetrics metrics,
  ) {
    final tableauCount = controller.tableau.length;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (int i = 0; i < tableauCount; i++) ...[
          SizedBox(
            width: metrics.cardWidth,
            child: _TableauPileSelector(
              pileIndex: i,
              cardWidth: metrics.cardWidth,
              stackOffset: metrics.stackOffset,
            ),
          ),
          if (i < tableauCount - 1) SizedBox(width: metrics.pileSpacing),
        ],
      ],
    );
  }
}

/// Selector widget for StockPileWidget - only rebuilds when stock pile data changes.
class _StockPileSelector extends StatelessWidget {
  final double cardWidth;

  const _StockPileSelector({required this.cardWidth});

  @override
  Widget build(BuildContext context) {
    return Selector<GameController, StockPileRenderData>(
      selector: (_, controller) {
        final pile = controller.stock!;
        return StockPileRenderData(
          pile: pile,
          pileVersion: pile.version,
          isFocused: controller.focusedPile == pile,
          isHintSource: controller.hintSourcePile == pile,
        );
      },
      builder: (context, data, _) {
        final controller = Provider.of<GameController>(context, listen: false);
        return Container(
          key: controller.boardLayout.getKeyForPileId(data.pile.id),
          child: StockPileWidget(
            pile: data.pile,
            cardWidth: cardWidth,
            controller: controller,
            // Spider stock tap deals to all tableau piles
            onTapOverride: () => controller.tapPile(data.pile),
          ),
        );
      },
    );
  }
}

/// Selector widget that only rebuilds a TableauPileWidget when its specific data changes.
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
