import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/card.dart';
import '../models/pile.dart';
import '../models/pile_render_data.dart';
import '../services/game_controller.dart';
import '../games/canfield/canfield_game.dart';
import '../widgets/card_widget.dart';
import '../widgets/pile_widget.dart';
import '../widgets/pile_indicator.dart';
import '../widgets/focused_pile_wrapper.dart';
import 'layout_strategy.dart';

/// Layout strategy for Canfield solitaire.
///
/// Layout structure:
/// - Top row: Stock | Waste | Reserve | Gap | Foundations (4)
/// - Bottom: 4 tableau columns
///
/// Uses [GridLayoutMixin] for standard card sizing and spacing calculations,
/// with column count set to 7 for proper spacing (reserve + gap + 4 tableau).
class CanfieldLayoutStrategy extends LayoutStrategy with GridLayoutMixin {
  const CanfieldLayoutStrategy(super.config);

  @override
  int get columnCount =>
      7; // Stock | Waste | Reserve + gap space + 4 foundations

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
          // Top row with stock, waste, reserve, and foundations
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
    // Build layout: Stock | Waste | gap | Reserve | gap | F0 F1 F2 F3
    final columns = <Widget>[];

    // Stock
    columns.add(SizedBox(
      width: metrics.cardWidth,
      child: _StockPileSelector(cardWidth: metrics.cardWidth),
    ));
    columns.add(SizedBox(width: metrics.pileSpacing));

    // Waste
    columns.add(SizedBox(
      width: metrics.cardWidth,
      child: _WastePileSelector(
        cardWidth: metrics.cardWidth,
        spreadCount: 3, // Canfield draws 3 cards
      ),
    ));
    columns.add(SizedBox(width: metrics.pileSpacing));

    // Reserve pile
    columns.add(SizedBox(
      width: metrics.cardWidth,
      child: _ReservePileSelector(cardWidth: metrics.cardWidth),
    ));

    // Spacer between reserve and foundations
    columns.add(const Spacer());

    // Foundations (4)
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

    // Center the 4 tableau columns
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
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

/// Selector widget for Reserve pile (Canfield-specific).
class _ReservePileSelector extends StatelessWidget {
  final double cardWidth;

  const _ReservePileSelector({required this.cardWidth});

  @override
  Widget build(BuildContext context) {
    return Selector<GameController, ReservePileRenderData>(
      selector: (_, controller) {
        final game = controller.game as CanfieldGame;
        final pile = game.reservePile;
        return ReservePileRenderData(
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
          child: _ReservePileWidget(
            pile: data.pile,
            cardWidth: cardWidth,
            controller: controller,
          ),
        );
      },
    );
  }
}

/// Widget for rendering the Reserve pile in Canfield.
/// Shows the top card and count of remaining cards.
class _ReservePileWidget extends StatelessWidget {
  final Pile pile;
  final double cardWidth;
  final GameController controller;

  const _ReservePileWidget({
    required this.pile,
    required this.cardWidth,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final isFocused = controller.focusedPile == pile;
    final isHintSource = controller.hintSourcePile == pile;
    final cardHeight = cardWidth / CardWidget.aspectRatio;

    if (pile.isEmpty) {
      return SizedBox(
        height: cardHeight,
        child: EmptyPileIndicator(
          width: cardWidth,
          type: PileIndicatorType.reserve,
          isFocused: isFocused,
          isHintSource: isHintSource,
        ),
      );
    }

    // Show top card with count overlay
    final card = pile.topCard!;
    final isAnimating = controller.isCardAnimating(card);

    return FocusedPileWrapper(
      isFocused: isFocused,
      width: cardWidth,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Show stack depth
          if (pile.length > 2)
            Positioned(
              left: 2,
              top: 2,
              child: CardWidget(
                card: pile.cards[0],
                width: cardWidth - 4,
              ),
            ),
          if (pile.length > 1)
            Positioned(
              left: 1,
              top: 1,
              child: CardWidget(
                card: pile.cards[0],
                width: cardWidth - 2,
              ),
            ),
          // Top card is draggable
          Draggable<DragData>(
            data: DragData(pile: pile, cards: [card]),
            feedback: Material(
              color: Colors.transparent,
              child: CardWidget(
                card: card,
                width: cardWidth,
                isDragging: true,
              ),
            ),
            childWhenDragging: pile.length > 1
                ? CardWidget(
                    card: pile.cards[pile.length - 2],
                    width: cardWidth,
                  )
                : SizedBox(
                    width: cardWidth,
                    height: cardHeight,
                    child: EmptyPileIndicator(
                      width: cardWidth,
                      type: PileIndicatorType.reserve,
                    ),
                  ),
            onDragStarted: () => controller.selectCard(pile, card),
            child: GestureDetector(
              onTap: () => controller.tapCard(pile, card),
              onDoubleTap: () =>
                  controller.doubleTapCardAnimated(pile, card, cardWidth, 0),
              child: ListenableBuilder(
                listenable: controller.selectionState,
                builder: (context, _) {
                  final isSelected =
                      controller.selectionState.isCardSelected(card);
                  return Opacity(
                    opacity: isAnimating ? 0.0 : 1.0,
                    child: CardWidget(
                      card: card,
                      width: cardWidth,
                      isSelected: isSelected,
                      isHintSource: isHintSource,
                    ),
                  );
                },
              ),
            ),
          ),
          // Count badge
          if (pile.length > 1)
            Positioned(
              right: 2,
              top: 2,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '${pile.length}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
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
