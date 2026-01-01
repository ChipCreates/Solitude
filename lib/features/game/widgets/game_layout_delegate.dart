import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/card.dart';
import 'package:solitude/features/settings/models/difficulty.dart';
import '../models/pile_render_data.dart';
import '../services/game_controller.dart';
import 'package:solitude/features/settings/services/settings_provider.dart';
import 'pile_widget.dart';
import '../games/game_interface.dart';

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

/// Klondike layout delegate - handles 7-column layout with stock, waste, and foundations
class KlondikeLayoutDelegate implements GameLayoutDelegate {
  final LayoutConfig config;

  const KlondikeLayoutDelegate(this.config);

  @override
  int get columnCount => config.tableauCount;

  @override
  Widget buildTopRow(
      BuildContext context, GameController controller, BoardLayoutData layout) {
    final stockPile = controller.stock;
    final wastePile = controller.waste;
    final settings = Provider.of<SettingsProvider>(context, listen: false);
    final isLeftHandMode = settings.leftHandMode;

    // Strict 7-column alignment for Klondike
    final columns = <Widget>[];

    if (isLeftHandMode) {
      // Left hand mode: F0 | F1 | F2 | F3 | Empty | Stock | Waste
      // Foundations in columns 0-3
      for (int i = 0; i < 4; i++) {
        if (i < controller.foundations.length) {
          columns.add(SizedBox(
            width: layout.cardWidth,
            child: _FoundationPileSelector(
              foundationIndex: i,
              cardWidth: layout.cardWidth,
            ),
          ));
        } else {
          columns.add(SizedBox(width: layout.cardWidth));
        }
        columns.add(SizedBox(width: layout.pileSpacing));
      }
      // Empty column 4
      columns.add(SizedBox(width: layout.cardWidth));
      columns.add(SizedBox(width: layout.pileSpacing));
      // Stock in column 5
      if (config.hasStock && stockPile != null) {
        columns.add(SizedBox(
          width: layout.cardWidth,
          child: _StockPileSelector(cardWidth: layout.cardWidth),
        ));
      } else {
        columns.add(SizedBox(width: layout.cardWidth));
      }
      columns.add(SizedBox(width: layout.pileSpacing));
      // Waste in column 6
      if (config.hasWaste && wastePile != null) {
        columns.add(SizedBox(
          width: layout.cardWidth,
          child: _WastePileSelector(
            cardWidth: layout.cardWidth,
            spreadCount: settings.difficulty.drawMode.drawCount,
          ),
        ));
      } else {
        columns.add(SizedBox(width: layout.cardWidth));
      }
    } else {
      // Normal mode: Stock | Waste | Empty | F0 | F1 | F2 | F3
      // Stock in column 0
      if (config.hasStock && stockPile != null) {
        columns.add(SizedBox(
          width: layout.cardWidth,
          child: _StockPileSelector(cardWidth: layout.cardWidth),
        ));
      } else {
        columns.add(SizedBox(width: layout.cardWidth));
      }
      columns.add(SizedBox(width: layout.pileSpacing));
      // Waste in column 1
      if (config.hasWaste && wastePile != null) {
        columns.add(SizedBox(
          width: layout.cardWidth,
          child: _WastePileSelector(
            cardWidth: layout.cardWidth,
            spreadCount: settings.difficulty.drawMode.drawCount,
          ),
        ));
      } else {
        columns.add(SizedBox(width: layout.cardWidth));
      }
      columns.add(SizedBox(width: layout.pileSpacing));
      // Empty column 2
      columns.add(SizedBox(width: layout.cardWidth));
      columns.add(SizedBox(width: layout.pileSpacing));
      // Foundations in columns 3-6
      for (int i = 0; i < 4; i++) {
        if (i < controller.foundations.length) {
          columns.add(SizedBox(
            width: layout.cardWidth,
            child: _FoundationPileSelector(
              foundationIndex: i,
              cardWidth: layout.cardWidth,
            ),
          ));
        } else {
          columns.add(SizedBox(width: layout.cardWidth));
        }
        if (i < 3) columns.add(SizedBox(width: layout.pileSpacing));
      }
    }

    return SizedBox(
      height: layout.cardHeight,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: columns,
      ),
    );
  }
}

/// Spider layout delegate - handles 10-column layout with only stock (no waste or visible foundations)
class SpiderLayoutDelegate implements GameLayoutDelegate {
  final LayoutConfig config;

  const SpiderLayoutDelegate(this.config);

  @override
  int get columnCount => config.tableauCount;

  @override
  Widget buildTopRow(
      BuildContext context, GameController controller, BoardLayoutData layout) {
    // Spider has stock on the left, rest of row filled with expanded container
    final stockPile = controller.stock;

    return SizedBox(
      height: layout.cardHeight,
      child: Row(
        children: [
          // Stock pile in column 0
          if (config.hasStock && stockPile != null)
            SizedBox(
              width: layout.cardWidth,
              child: _StockPileSelector(cardWidth: layout.cardWidth),
            ),
          // Fill rest of row
          Expanded(child: Container()),
        ],
      ),
    );
  }
}

/// Factory method to create the appropriate layout delegate for a game type
GameLayoutDelegate createLayoutDelegate(GameController controller) {
  final config = controller.game.layoutConfig;

  // Check if it's a Klondike game (7 columns, 4 foundations, has waste)
  if (config.tableauCount == 7 &&
      config.foundationCount == 4 &&
      config.hasWaste) {
    return KlondikeLayoutDelegate(config);
  }

  // Check if it's a Spider game (10 columns, 8 foundations, no waste)
  if (config.tableauCount == 10 &&
      config.foundationCount == 8 &&
      !config.hasWaste) {
    return SpiderLayoutDelegate(config);
  }

  // Fallback - could be extended for other games
  return KlondikeLayoutDelegate(config);
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
