import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/card.dart';
import '../models/pile_render_data.dart';
import '../services/game_controller.dart';
import '../widgets/pile_widget.dart';
import 'layout_strategy.dart';

/// Layout strategy for Yukon solitaire.
///
/// Layout structure:
/// - Top row: Gap | Foundations (4, right-aligned)
/// - Bottom: 7 tableau columns
///
/// Yukon has no stock or waste - all 52 cards are dealt to the tableau.
/// Uses [GridLayoutMixin] for standard card sizing and spacing calculations.
class YukonLayoutStrategy extends LayoutStrategy with GridLayoutMixin {
  const YukonLayoutStrategy(super.config);

  @override
  int get columnCount => 7;

  @override
  Widget buildLayout(
    BuildContext context,
    GameController controller,
    BoxConstraints constraints,
  ) {
    final metrics = calculateGridMetrics(constraints);

    return buildGridPadding(
      child: Column(
        children: [
          // Top row with foundations only (right-aligned)
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
    // Foundations right-aligned
    final columns = <Widget>[];

    // Spacer to push foundations right
    columns.add(const Spacer());

    // 4 Foundations
    for (int i = 0; i < 4; i++) {
      if (i > 0) columns.add(SizedBox(width: metrics.pileSpacing));
      columns.add(SizedBox(
        width: metrics.cardWidth,
        child: _FoundationPileSelector(
          foundationIndex: i,
          cardWidth: metrics.cardWidth,
        ),
      ));
    }

    return SizedBox(
      height: metrics.cardHeight,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: columns,
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

/// Selector widget for FoundationPileWidget.
class _FoundationPileSelector extends StatelessWidget {
  final int foundationIndex;
  final double cardWidth;

  const _FoundationPileSelector({
    required this.foundationIndex,
    required this.cardWidth,
  });

  @override
  Widget build(BuildContext context) {
    return Selector<GameController, FoundationPileRenderData>(
      selector: (_, controller) {
        final pile = controller.foundations[foundationIndex];
        return FoundationPileRenderData(
          pile: pile,
          pileVersion: pile.version,
          isValidDestination: controller.isValidDestination(pile),
          isHintDestination: controller.hintDestinationPile == pile,
        );
      },
      builder: (context, data, _) {
        final controller = Provider.of<GameController>(context, listen: false);
        final suit = controller.game.getFoundationSuit(foundationIndex);
        return Container(
          key: controller.boardLayout.getKeyForPileId(data.pile.id),
          child: FoundationPileWidget(
            pile: data.pile,
            cardWidth: cardWidth,
            suit: suit ?? Suit.values[foundationIndex % Suit.values.length],
            controller: controller,
          ),
        );
      },
    );
  }
}

/// Selector widget for TableauPileWidget.
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
