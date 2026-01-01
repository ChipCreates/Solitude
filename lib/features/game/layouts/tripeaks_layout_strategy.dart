import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/pile.dart';
import '../models/pile_render_data.dart';
import '../services/game_controller.dart';
import '../games/tripeaks/tripeaks_game.dart';
import '../widgets/card_widget.dart';
import '../widgets/pile_widget.dart';
import '../widgets/pile_indicator.dart';
import '../widgets/focused_pile_wrapper.dart';
import 'layout_strategy.dart';

/// Layout strategy for TriPeaks solitaire using absolute positioning.
///
/// Layout structure:
/// - 3 small pyramids (height 4) with overlapping bottoms
/// - Peak 1 center at 25% width
/// - Peak 2 center at 50% width
/// - Peak 3 center at 75% width
/// - Bottom row: continuous row of 10 cards
/// - Below: Stock | Waste (centered)
///
/// Uses absolute positioning (Stack/Positioned) instead of grid layout.
class TriPeaksLayoutStrategy extends LayoutStrategy {
  const TriPeaksLayoutStrategy(super.config);

  @override
  Widget buildLayout(
    BuildContext context,
    GameController controller,
    BoxConstraints constraints,
  ) {
    final game = controller.game as TriPeaksGame;

    // Calculate card size to fit 10 cards in bottom row
    const horizontalPadding = 8.0;
    final availableWidth = constraints.maxWidth - (horizontalPadding * 2);
    final cardWidth = (availableWidth / 11.0).clamp(35.0, 80.0);
    final cardHeight = cardWidth / CardWidget.aspectRatio;

    // Calculate vertical spacing
    final peakRowHeight = cardHeight * 0.35;
    final peaksHeight =
        3 * peakRowHeight + cardHeight; // 3 peak rows + top card
    final bottomRowY = peaksHeight + 8;
    final stockRowY = bottomRowY + cardHeight + 16;

    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: horizontalPadding, vertical: 8),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Three peaks
          ..._buildPeaks(context, controller, game, cardWidth, cardHeight,
              peakRowHeight, constraints),
          // Bottom row of 10 cards
          ..._buildBottomRow(context, controller, game, cardWidth, cardHeight,
              bottomRowY, constraints),
          // Stock and Waste
          Positioned(
            top: stockRowY,
            left: 0,
            right: 0,
            child: _buildStockWaste(
                context, controller, game, cardWidth, cardHeight),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildPeaks(
    BuildContext context,
    GameController controller,
    TriPeaksGame game,
    double cardWidth,
    double cardHeight,
    double rowHeight,
    BoxConstraints constraints,
  ) {
    final widgets = <Widget>[];
    final availableWidth = constraints.maxWidth - 16;

    // Peak centers at 25%, 50%, 75%
    final peakCenters = [
      availableWidth * 0.25,
      availableWidth * 0.50,
      availableWidth * 0.75,
    ];

    // TriPeaks structure (indices 0-17 for the three peaks):
    // Row 0: indices 0, 1, 2 (one per peak top)
    // Row 1: indices 3-4, 5-6, 7-8 (two per peak)
    // Row 2: indices 9-11, 12-14, 15-17 (overlapping)

    // Row 0: Peak tops (indices 0, 1, 2)
    for (int peak = 0; peak < 3; peak++) {
      final x = peakCenters[peak] - cardWidth / 2;
      widgets.add(
        Positioned(
          left: x,
          top: 0,
          child: _PyramidCardSelector(
            pileIndex: peak,
            cardWidth: cardWidth,
          ),
        ),
      );
    }

    // Row 1: Two cards per peak (indices 3-8)
    for (int peak = 0; peak < 3; peak++) {
      for (int col = 0; col < 2; col++) {
        final pileIndex = 3 + peak * 2 + col;
        final x =
            peakCenters[peak] + (col - 0.5) * cardWidth * 0.55 - cardWidth / 2;
        widgets.add(
          Positioned(
            left: x,
            top: rowHeight,
            child: _PyramidCardSelector(
              pileIndex: pileIndex,
              cardWidth: cardWidth,
            ),
          ),
        );
      }
    }

    // Row 2: Three cards per peak, overlapping (indices 9-17)
    // Peak 0: 9, 10, 11
    // Peak 1: 12, 13, 14
    // Peak 2: 15, 16, 17
    for (int peak = 0; peak < 3; peak++) {
      for (int col = 0; col < 3; col++) {
        final pileIndex = 9 + peak * 3 + col;
        final x =
            peakCenters[peak] + (col - 1) * cardWidth * 0.55 - cardWidth / 2;
        widgets.add(
          Positioned(
            left: x,
            top: rowHeight * 2,
            child: _PyramidCardSelector(
              pileIndex: pileIndex,
              cardWidth: cardWidth,
            ),
          ),
        );
      }
    }

    return widgets;
  }

  List<Widget> _buildBottomRow(
    BuildContext context,
    GameController controller,
    TriPeaksGame game,
    double cardWidth,
    double cardHeight,
    double topY,
    BoxConstraints constraints,
  ) {
    final widgets = <Widget>[];
    final availableWidth = constraints.maxWidth - 16;

    // 10 cards in the bottom row (indices 18-27)
    // Space them evenly
    final spacing = (availableWidth - 10 * cardWidth) / 11;

    for (int i = 0; i < 10; i++) {
      final pileIndex = 18 + i;
      final x = spacing + i * (cardWidth + spacing);
      widgets.add(
        Positioned(
          left: x,
          top: topY,
          child: _PyramidCardSelector(
            pileIndex: pileIndex,
            cardWidth: cardWidth,
          ),
        ),
      );
    }

    return widgets;
  }

  Widget _buildStockWaste(
    BuildContext context,
    GameController controller,
    TriPeaksGame game,
    double cardWidth,
    double cardHeight,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          width: cardWidth,
          height: cardHeight,
          child: _StockPileSelector(cardWidth: cardWidth),
        ),
        const SizedBox(width: 12),
        SizedBox(
          width: cardWidth,
          height: cardHeight,
          child: _WastePileSelector(cardWidth: cardWidth),
        ),
      ],
    );
  }
}

/// Selector for individual peak/pyramid card positions.
class _PyramidCardSelector extends StatelessWidget {
  final int pileIndex;
  final double cardWidth;

  const _PyramidCardSelector({
    required this.pileIndex,
    required this.cardWidth,
  });

  @override
  Widget build(BuildContext context) {
    return Selector<GameController, PyramidPileRenderData>(
      selector: (_, controller) {
        final game = controller.game as TriPeaksGame;
        final pile = game.peakPiles[pileIndex];
        return PyramidPileRenderData(
          pile: pile,
          pileVersion: pile.version,
          isFocused: controller.focusedPile == pile,
          isUncovered: game.isCardUncovered(pileIndex),
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
          child: _TriPeaksCardWidget(
            pile: data.pile,
            pileIndex: pileIndex,
            cardWidth: cardWidth,
            isUncovered: data.isUncovered,
            controller: controller,
          ),
        );
      },
    );
  }
}

/// Widget for a single TriPeaks card/position.
class _TriPeaksCardWidget extends StatelessWidget {
  final Pile pile;
  final int pileIndex;
  final double cardWidth;
  final bool isUncovered;
  final GameController controller;

  const _TriPeaksCardWidget({
    required this.pile,
    required this.pileIndex,
    required this.cardWidth,
    required this.isUncovered,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final cardHeight = cardWidth / CardWidget.aspectRatio;
    final isFocused = controller.focusedPile == pile;
    final isHintSource = controller.hintSourcePile == pile;

    if (pile.isEmpty) {
      // Empty slot
      return SizedBox(
        width: cardWidth,
        height: cardHeight,
        child: EmptyPileIndicator(
          width: cardWidth,
          type: PileIndicatorType.pyramid,
          isFocused: isFocused,
        ),
      );
    }

    final card = pile.topCard!;
    final isAnimating = controller.isCardAnimating(card);

    // Face-down cards are not interactive
    if (!card.faceUp) {
      return CardWidget(
        card: card,
        width: cardWidth,
      );
    }

    // Only uncovered cards are interactive
    if (!isUncovered) {
      return CardWidget(
        card: card,
        width: cardWidth,
      );
    }

    // Uncovered card is draggable and tappable
    return FocusedPileWrapper(
      isFocused: isFocused,
      width: cardWidth,
      child: Draggable<DragData>(
        data: DragData(pile: pile, cards: [card]),
        feedback: Material(
          color: Colors.transparent,
          child: CardWidget(
            card: card,
            width: cardWidth,
            isDragging: true,
          ),
        ),
        childWhenDragging: SizedBox(
          width: cardWidth,
          height: cardHeight,
          child: EmptyPileIndicator(
            width: cardWidth,
            type: PileIndicatorType.pyramid,
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
              final isSelected = controller.selectionState.isCardSelected(card);
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
    );
  }
}

/// Selector for stock pile.
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

/// Selector for waste pile - in TriPeaks this is the target pile.
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
        final cardHeight = cardWidth / CardWidget.aspectRatio;

        // In TriPeaks, waste is a drop target
        return DragTarget<DragData>(
          onWillAcceptWithDetails: (details) {
            return details.data.cards.length == 1 &&
                controller.game.isValidMove(
                  details.data.pile,
                  data.pile,
                  details.data.cards,
                );
          },
          onAcceptWithDetails: (details) {
            controller.tryMove(
                details.data.pile, data.pile, details.data.cards);
          },
          builder: (context, candidateData, rejectedData) {
            final isDropTarget = candidateData.isNotEmpty;

            return ListenableBuilder(
              listenable: controller.selectionState,
              builder: (context, _) {
                final isValidDest = controller.isValidDestination(data.pile);
                final isHintDest = controller.hintDestinationPile == data.pile;

                if (data.pile.isEmpty) {
                  return SizedBox(
                    width: cardWidth,
                    height: cardHeight,
                    child: EmptyPileIndicator(
                      width: cardWidth,
                      type: PileIndicatorType.waste,
                      isHighlighted: isValidDest || isDropTarget,
                      isHintDestination: isHintDest,
                    ),
                  );
                }

                return CardWidget(
                  card: data.pile.topCard!,
                  width: cardWidth,
                  isHighlighted: isDropTarget || isValidDest,
                  isHintDestination: isHintDest,
                  onTap: () => controller.tapPile(data.pile),
                );
              },
            );
          },
        );
      },
    );
  }
}
