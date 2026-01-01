import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/card.dart';
import '../models/pile_render_data.dart';
import '../services/game_controller.dart';
import 'package:solitude/features/settings/models/difficulty.dart';
import 'package:solitude/features/settings/services/settings_provider.dart';
import '../widgets/pile_widget.dart';
import 'layout_strategy.dart';

/// Layout strategy for Klondike solitaire.
///
/// Layout structure:
/// - Top row: Stock | Waste | Gap | Foundations (or reversed for left-hand mode)
/// - Bottom: 7 tableau columns
///
/// Uses [GridLayoutMixin] for standard card sizing and spacing calculations.
class KlondikeLayoutStrategy extends LayoutStrategy with GridLayoutMixin {
  const KlondikeLayoutStrategy(super.config);

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
          // Top row with stock, waste, and foundations
          Consumer<SettingsProvider>(
            builder: (context, settings, _) {
              return _buildTopRow(context, controller, metrics, settings);
            },
          ),
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
    SettingsProvider settings,
  ) {
    final stockPile = controller.stock;
    final wastePile = controller.waste;
    final isLeftHandMode = settings.leftHandMode;

    // Strict 7-column alignment for Klondike
    final columns = <Widget>[];

    if (isLeftHandMode) {
      // Left hand mode: F0 | F1 | F2 | F3 | Empty | Stock | Waste
      // Foundations in columns 0-3
      for (int i = 0; i < 4; i++) {
        if (i < controller.foundations.length) {
          columns.add(SizedBox(
            width: metrics.cardWidth,
            child: _FoundationPileSelector(
              foundationIndex: i,
              cardWidth: metrics.cardWidth,
            ),
          ));
        } else {
          columns.add(SizedBox(width: metrics.cardWidth));
        }
        columns.add(SizedBox(width: metrics.pileSpacing));
      }
      // Empty column 4
      columns.add(SizedBox(width: metrics.cardWidth));
      columns.add(SizedBox(width: metrics.pileSpacing));
      // Stock in column 5
      if (config.hasStock && stockPile != null) {
        columns.add(SizedBox(
          width: metrics.cardWidth,
          child: _StockPileSelector(cardWidth: metrics.cardWidth),
        ));
      } else {
        columns.add(SizedBox(width: metrics.cardWidth));
      }
      columns.add(SizedBox(width: metrics.pileSpacing));
      // Waste in column 6
      if (config.hasWaste && wastePile != null) {
        columns.add(SizedBox(
          width: metrics.cardWidth,
          child: _WastePileSelector(
            cardWidth: metrics.cardWidth,
            spreadCount: settings.difficulty.drawMode.drawCount,
          ),
        ));
      } else {
        columns.add(SizedBox(width: metrics.cardWidth));
      }
    } else {
      // Normal mode: Stock | Waste | Empty | F0 | F1 | F2 | F3
      // Stock in column 0
      if (config.hasStock && stockPile != null) {
        columns.add(SizedBox(
          width: metrics.cardWidth,
          child: _StockPileSelector(cardWidth: metrics.cardWidth),
        ));
      } else {
        columns.add(SizedBox(width: metrics.cardWidth));
      }
      columns.add(SizedBox(width: metrics.pileSpacing));
      // Waste in column 1
      if (config.hasWaste && wastePile != null) {
        columns.add(SizedBox(
          width: metrics.cardWidth,
          child: _WastePileSelector(
            cardWidth: metrics.cardWidth,
            spreadCount: settings.difficulty.drawMode.drawCount,
          ),
        ));
      } else {
        columns.add(SizedBox(width: metrics.cardWidth));
      }
      columns.add(SizedBox(width: metrics.pileSpacing));
      // Empty column 2
      columns.add(SizedBox(width: metrics.cardWidth));
      columns.add(SizedBox(width: metrics.pileSpacing));
      // Foundations in columns 3-6
      for (int i = 0; i < 4; i++) {
        if (i < controller.foundations.length) {
          columns.add(SizedBox(
            width: metrics.cardWidth,
            child: _FoundationPileSelector(
              foundationIndex: i,
              cardWidth: metrics.cardWidth,
            ),
          ));
        } else {
          columns.add(SizedBox(width: metrics.cardWidth));
        }
        if (i < 3) columns.add(SizedBox(width: metrics.pileSpacing));
      }
    }

    return SizedBox(
      height: metrics.cardHeight,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
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
            onTapOverride: () => controller.animateStockDraw(cardWidth),
          ),
        );
      },
    );
  }
}

/// Selector widget for WastePileWidget - only rebuilds when waste pile data changes.
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

/// Selector widget for FoundationPileWidget - only rebuilds when foundation pile data changes.
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
        // Use game-agnostic getFoundationSuit instead of hardcoded mapping
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
