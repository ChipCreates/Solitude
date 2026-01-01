import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/card.dart';
import '../models/pile.dart';
import '../models/pile_render_data.dart';
import '../services/game_controller.dart';
import '../games/freecell/freecell_game.dart';
import '../widgets/card_widget.dart';
import '../widgets/pile_widget.dart';
import '../widgets/pile_indicator.dart';
import '../widgets/focused_pile_wrapper.dart';
import 'layout_strategy.dart';

/// Layout strategy for FreeCell solitaire.
///
/// Layout structure:
/// - Top row: 4 FreeCells (left) | Gap | 4 Foundations (right)
/// - Bottom: 8 tableau columns
///
/// Uses [GridLayoutMixin] for standard card sizing and spacing calculations,
/// with column count set to 8 for FreeCell's tableau.
class FreeCellLayoutStrategy extends LayoutStrategy with GridLayoutMixin {
  const FreeCellLayoutStrategy(super.config);

  @override
  int get columnCount => 8;

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
          // Top row with free cells and foundations
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
    // Build 8-column layout: 4 free cells | spacer | 4 foundations
    final columns = <Widget>[];

    // Free cells (columns 0-3)
    for (int i = 0; i < 4; i++) {
      columns.add(SizedBox(
        width: metrics.cardWidth,
        child: _FreeCellPileSelector(
          cellIndex: i,
          cardWidth: metrics.cardWidth,
        ),
      ));
      columns.add(SizedBox(width: metrics.pileSpacing));
    }

    // Spacer between free cells and foundations
    columns.add(const Spacer());

    // Foundations (columns 4-7)
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

/// Selector widget for FreeCellPileWidget - rebuilds when cell data changes.
class _FreeCellPileSelector extends StatelessWidget {
  final int cellIndex;
  final double cardWidth;

  const _FreeCellPileSelector({
    required this.cellIndex,
    required this.cardWidth,
  });

  @override
  Widget build(BuildContext context) {
    return Selector<GameController, CellPileRenderData>(
      selector: (_, controller) {
        final game = controller.game as FreeCellGame;
        final pile = game.freeCellPiles[cellIndex];
        return CellPileRenderData(
          pile: pile,
          pileVersion: pile.version,
          isFocused: controller.focusedPile == pile,
          isValidDestination: controller.isValidDestination(pile),
          isHintDestination: controller.hintDestinationPile == pile,
          selectedCards: controller.selectedCards,
          selectedPile: controller.selectedPile,
          animatingCard: controller.animatingCard,
        );
      },
      builder: (context, data, _) {
        final controller = Provider.of<GameController>(context, listen: false);
        return Container(
          key: controller.boardLayout.getKeyForPileId(data.pile.id),
          child: _FreeCellPileWidget(
            pile: data.pile,
            cardWidth: cardWidth,
            controller: controller,
          ),
        );
      },
    );
  }
}

/// Widget for rendering a single FreeCell (cell) pile.
class _FreeCellPileWidget extends StatelessWidget {
  final Pile pile;
  final double cardWidth;
  final GameController controller;

  const _FreeCellPileWidget({
    required this.pile,
    required this.cardWidth,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final isFocused = controller.focusedPile == pile;
    final isHintDest = controller.hintDestinationPile == pile;
    final cardHeight = cardWidth / CardWidget.aspectRatio;

    if (pile.isEmpty) {
      return SizedBox(
        height: cardHeight,
        child: DragTarget<DragData>(
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
                return EmptyPileIndicator(
                  width: cardWidth,
                  type: PileIndicatorType.cell,
                  isHighlighted: isValidDest || isDropTarget,
                  isHintDestination: isHintDest,
                  isFocused: isFocused,
                  onTap: () => controller.tapPile(pile),
                );
              },
            );
          },
        ),
      );
    }

    // Single card in cell - make it draggable
    final card = pile.topCard!;
    final isAnimating = controller.isCardAnimating(card);

    return FocusedPileWrapper(
      isFocused: isFocused,
      width: cardWidth,
      child: DragTarget<DragData>(
        onWillAcceptWithDetails: (details) =>
            false, // Can't drop on occupied cell
        builder: (context, candidateData, rejectedData) {
          return Draggable<DragData>(
            data: DragData(pile: pile, cards: [card]),
            feedback: Material(
              color: Colors.transparent,
              child: CardWidget(
                card: card,
                width: cardWidth,
                isDragging: true,
              ),
            ),
            childWhenDragging: Opacity(
              opacity: 0.3,
              child: CardWidget(
                card: card,
                width: cardWidth,
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
                      isHintDestination: isHintDest,
                    ),
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Selector widget for FoundationPileWidget - rebuilds when foundation data changes.
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

/// Selector widget for TableauPileWidget - rebuilds when tableau data changes.
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
