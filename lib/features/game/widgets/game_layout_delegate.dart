import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/card.dart';
import 'package:solitude/features/settings/models/difficulty.dart';
import '../models/pile_render_data.dart';
import '../services/game_controller.dart';
import 'package:solitude/features/settings/services/settings_provider.dart';
import 'pile_widget.dart';

class BoardLayoutData {
  final double cardWidth;
  final double cardHeight;
  final double pileSpacing;
  final double stackOffset;
  final double rowSpacing;
  final double padding;

  const BoardLayoutData({
    required this.cardWidth,
    required this.cardHeight,
    required this.pileSpacing,
    required this.stackOffset,
    required this.rowSpacing,
    required this.padding,
  });
}

abstract class GameLayoutDelegate {
  int get columnCount;
  Widget buildTopRow(
      BuildContext context, GameController controller, BoardLayoutData layout);
}

class KlondikeLayoutDelegate implements GameLayoutDelegate {
  const KlondikeLayoutDelegate();

  @override
  int get columnCount => 7;

  @override
  Widget buildTopRow(
      BuildContext context, GameController controller, BoardLayoutData layout) {
    // Calculate the width of the first 3 tableau piles section
    final first3Width = layout.cardWidth * 3 + layout.pileSpacing * 2;
    final stockPile = controller.stock;
    final wastePile = controller.waste;
    final settings = Provider.of<SettingsProvider>(context, listen: false);
    final isLeftHandMode = settings.leftHandMode;

    // Build stock/waste section
    final stockWasteSection = <Widget>[];
    if (stockPile != null) {
      stockWasteSection.add(SizedBox(
        width: layout.cardWidth,
        child: _StockPileSelector(cardWidth: layout.cardWidth),
      ));
    }
    if (stockPile != null) {
      stockWasteSection.add(SizedBox(width: layout.pileSpacing));
    }
    if (wastePile != null) {
      stockWasteSection.add(SizedBox(
        width: layout.cardWidth,
        child: _WastePileSelector(
          cardWidth: layout.cardWidth,
          spreadCount: settings.difficulty.drawMode.drawCount,
        ),
      ));
    }

    // Build foundations section
    final foundationsSection = <Widget>[];
    for (int i = 0; i < controller.foundations.length; i++) {
      foundationsSection.add(SizedBox(
        width: layout.cardWidth,
        child: _FoundationPileSelector(
          foundationIndex: i,
          cardWidth: layout.cardWidth,
        ),
      ));
      if (i < controller.foundations.length - 1) {
        foundationsSection.add(SizedBox(width: layout.pileSpacing));
      }
    }

    // Build row based on left hand mode
    final rowChildren = <Widget>[];
    if (isLeftHandMode) {
      // Left hand mode: foundations on left, stock/waste on right
      rowChildren.addAll(foundationsSection);
      rowChildren.add(SizedBox(width: layout.pileSpacing));
      // Spacer to fill remaining space in "first 3 piles" section
      rowChildren.add(SizedBox(
          width: first3Width - (layout.cardWidth * 2 + layout.pileSpacing)));
      rowChildren.add(SizedBox(width: layout.pileSpacing));
      rowChildren.addAll(stockWasteSection);
    } else {
      // Normal mode: stock/waste on left, foundations on right
      rowChildren.addAll(stockWasteSection);
      // Spacer to fill remaining space in "first 3 piles" section
      rowChildren.add(SizedBox(
          width: first3Width - (layout.cardWidth * 2 + layout.pileSpacing)));
      rowChildren.add(SizedBox(width: layout.pileSpacing));
      rowChildren.addAll(foundationsSection);
    }

    return SizedBox(
      height: layout.cardHeight,
      child: Row(
        children: rowChildren,
      ),
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
        return Container(
          key: controller.boardLayout.getKeyForPileId(data.pile.id),
          child: FoundationPileWidget(
            pile: data.pile,
            cardWidth: cardWidth,
            suit: Suit.values[foundationIndex % Suit.values.length],
            controller: controller,
          ),
        );
      },
    );
  }
}
