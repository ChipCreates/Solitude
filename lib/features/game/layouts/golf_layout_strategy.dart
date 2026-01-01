import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/pile_render_data.dart';
import '../services/game_controller.dart';
import '../widgets/card_widget.dart';
import '../widgets/pile_widget.dart';
import '../widgets/pile_indicator.dart';
import 'layout_strategy.dart';

/// Layout strategy for Golf solitaire.
///
/// Layout structure:
/// - Top row: Stock | Waste (center-left aligned)
/// - Bottom: 7 tableau columns
///
/// Golf has no foundations - cards are played to the Waste pile if they
/// are +/- 1 rank of the waste top card. The goal is to clear the tableau.
///
/// Uses [GridLayoutMixin] for standard card sizing and spacing calculations.
class GolfLayoutStrategy extends LayoutStrategy with GridLayoutMixin {
  const GolfLayoutStrategy(super.config);

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
          // Top row with stock and waste
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
    return SizedBox(
      height: metrics.cardHeight,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Stock pile
          SizedBox(
            width: metrics.cardWidth,
            child: _StockPileSelector(cardWidth: metrics.cardWidth),
          ),
          SizedBox(width: metrics.pileSpacing),
          // Waste pile
          SizedBox(
            width: metrics.cardWidth,
            child: _WastePileSelector(cardWidth: metrics.cardWidth),
          ),
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

/// Selector widget for StockPileWidget.
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
            onTapOverride: () => controller.tapPile(data.pile),
          ),
        );
      },
    );
  }
}

/// Selector widget for WastePileWidget.
/// In Golf, the waste is the target pile - cards are played TO the waste.
class _WastePileSelector extends StatelessWidget {
  final double cardWidth;

  const _WastePileSelector({required this.cardWidth});

  @override
  Widget build(BuildContext context) {
    return Selector<GameController, WastePileRenderData>(
      selector: (_, controller) {
        final pile = controller.waste!;
        return WastePileRenderData(
          pile: pile,
          pileVersion: pile.version,
          isFocused: controller.focusedPile == pile,
          isHintSource: controller.hintSourcePile == pile,
          selectedCards: controller.selectedCards,
          selectedPile: controller.selectedPile,
          animatingCard: controller.animatingCard,
        );
      },
      builder: (context, data, _) {
        final controller = Provider.of<GameController>(context, listen: false);
        return Container(
          key: controller.boardLayout.getKeyForPileId(data.pile.id),
          child: _GolfWastePileWidget(
            pile: data.pile,
            cardWidth: cardWidth,
            controller: controller,
          ),
        );
      },
    );
  }
}

/// Custom waste pile widget for Golf - shows as a drop target.
class _GolfWastePileWidget extends StatelessWidget {
  final dynamic pile;
  final double cardWidth;
  final GameController controller;

  const _GolfWastePileWidget({
    required this.pile,
    required this.cardWidth,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final isHintDest = controller.hintDestinationPile == pile;
    final isFocused = controller.focusedPile == pile;

    // Golf waste is a drop target
    return DragTarget<DragData>(
      onWillAcceptWithDetails: (details) {
        return details.data.cards.length == 1 &&
            controller.game.isValidMove(
              details.data.pile,
              pile,
              details.data.cards,
            );
      },
      onAcceptWithDetails: (details) {
        controller.tryMove(details.data.pile, pile, details.data.cards);
      },
      builder: (context, candidateData, rejectedData) {
        final isDropTarget = candidateData.isNotEmpty;

        return ListenableBuilder(
          listenable: controller.selectionState,
          builder: (context, _) {
            final isValidDest = controller.isValidDestination(pile);

            if (pile.isEmpty) {
              return EmptyPileIndicator(
                width: cardWidth,
                type: PileIndicatorType.waste,
                isHighlighted: isValidDest || isDropTarget,
                isHintDestination: isHintDest,
                isFocused: isFocused,
              );
            }

            return CardWidget(
              card: pile.topCard!,
              width: cardWidth,
              isHighlighted: isDropTarget,
              isHintDestination: isHintDest,
              onTap: () => controller.tapPile(pile),
            );
          },
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
