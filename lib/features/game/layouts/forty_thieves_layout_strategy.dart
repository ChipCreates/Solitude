import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/card.dart';
import '../models/pile_render_data.dart';
import '../services/game_controller.dart';
import '../widgets/pile_widget.dart';
import 'layout_strategy.dart';

/// Layout strategy for Forty Thieves solitaire.
///
/// Layout structure:
/// - Top row: Stock | Waste | Gap | Foundations (8)
/// - Bottom: 10 tableau columns
///
/// Uses [GridLayoutMixin] with minimal padding for tight mobile fit.
/// The 10 columns + 8 foundations make this the most space-intensive layout.
class FortyThievesLayoutStrategy extends LayoutStrategy with GridLayoutMixin {
  const FortyThievesLayoutStrategy(super.config);

  @override
  int get columnCount => 10;

  /// Minimal horizontal padding for tight fit
  @override
  double get horizontalPadding => 8.0;

  /// Reduced base padding
  @override
  double get basePadding => 4.0;

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
          // Top row with stock, waste, and 8 foundations
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
    // For Forty Thieves, we need to fit stock, waste, and 8 foundations
    // Use smaller spacing to fit everything
    final smallSpacing = metrics.pileSpacing * 0.5;

    final columns = <Widget>[];

    // Stock
    columns.add(SizedBox(
      width: metrics.cardWidth,
      child: _StockPileSelector(cardWidth: metrics.cardWidth),
    ));
    columns.add(SizedBox(width: smallSpacing));

    // Waste
    columns.add(SizedBox(
      width: metrics.cardWidth,
      child: _WastePileSelector(
        cardWidth: metrics.cardWidth,
        spreadCount: 1, // Forty Thieves draws 1 card
      ),
    ));

    // Spacer between waste and foundations
    columns.add(const Spacer());

    // 8 Foundations (for 2 decks - 2 per suit)
    for (int i = 0; i < 8; i++) {
      if (i > 0) columns.add(SizedBox(width: smallSpacing));
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
class _WastePileSelector extends StatelessWidget {
  final double cardWidth;
  final int spreadCount;

  const _WastePileSelector({
    required this.cardWidth,
    required this.spreadCount,
  });

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
          child: WastePileWidget(
            pile: data.pile,
            cardWidth: cardWidth,
            spreadCount: spreadCount,
            controller: controller,
          ),
        );
      },
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
