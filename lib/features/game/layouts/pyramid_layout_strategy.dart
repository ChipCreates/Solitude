import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/pile.dart';
import '../models/pile_render_data.dart';
import '../services/game_controller.dart';
import '../games/pyramid/pyramid_game.dart';
import '../widgets/card_widget.dart';
import '../widgets/pile_widget.dart';
import '../widgets/pile_indicator.dart';
import '../widgets/focused_pile_wrapper.dart';
import 'layout_strategy.dart';

/// Layout strategy for Pyramid solitaire using absolute positioning.
///
/// Layout structure:
/// - Pyramid: 28 cards in 7 rows forming a triangle
/// - Bottom: Stock | Waste (left), Discard (right)
///
/// Uses absolute positioning (Stack/Positioned) instead of grid layout.
/// Card width is calculated to fit the pyramid base (7 cards) on screen.
class PyramidLayoutStrategy extends LayoutStrategy {
  const PyramidLayoutStrategy(super.config);

  @override
  Widget buildLayout(
    BuildContext context,
    GameController controller,
    BoxConstraints constraints,
  ) {
    final game = controller.game as PyramidGame;

    // Calculate card size to fit pyramid base (7 cards with overlap)
    // The base needs about 8 card widths of space (7 cards with 1.1x spacing)
    const horizontalPadding = 16.0;
    final availableWidth = constraints.maxWidth - (horizontalPadding * 2);
    final cardWidth = (availableWidth / 8.0).clamp(40.0, 100.0);
    final cardHeight = cardWidth / CardWidget.aspectRatio;

    // Calculate pyramid dimensions
    final pyramidHeight = 7 * cardHeight * 0.4 + cardHeight;
    final bottomRowHeight = cardHeight + 16; // Stock/waste/discard row

    // Calculate vertical spacing
    final totalContentHeight = pyramidHeight + bottomRowHeight + 20;
    final topPadding =
        ((constraints.maxHeight - totalContentHeight) / 3).clamp(8.0, 40.0);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: horizontalPadding),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Pyramid cards
          ..._buildPyramid(context, controller, game, cardWidth, cardHeight,
              topPadding, constraints),
          // Bottom row: Stock, Waste, Discard
          Positioned(
            bottom: 8,
            left: 0,
            right: 0,
            child: _buildBottomRow(
                context, controller, game, cardWidth, cardHeight),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildPyramid(
    BuildContext context,
    GameController controller,
    PyramidGame game,
    double cardWidth,
    double cardHeight,
    double topPadding,
    BoxConstraints constraints,
  ) {
    final pyramidWidgets = <Widget>[];
    final centerX =
        (constraints.maxWidth - 32) / 2; // Center of available space

    int pileIndex = 0;
    for (int row = 0; row < 7; row++) {
      for (int col = 0; col <= row; col++) {
        // Position formula from spec
        // x = centerX + (col - row/2) * cardWidth * 1.1
        // y = topPadding + row * cardHeight * 0.4
        final x = centerX + (col - row / 2.0) * cardWidth * 1.1 - cardWidth / 2;
        final y = topPadding + row * cardHeight * 0.4;

        pyramidWidgets.add(
          Positioned(
            left: x,
            top: y,
            child: _PyramidCardSelector(
              pileIndex: pileIndex,
              cardWidth: cardWidth,
            ),
          ),
        );
        pileIndex++;
      }
    }

    return pyramidWidgets;
  }

  Widget _buildBottomRow(
    BuildContext context,
    GameController controller,
    PyramidGame game,
    double cardWidth,
    double cardHeight,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Stock and Waste (left side)
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: cardWidth,
              height: cardHeight,
              child: _StockPileSelector(cardWidth: cardWidth),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: cardWidth,
              height: cardHeight,
              child: _WastePileSelector(cardWidth: cardWidth),
            ),
          ],
        ),
        // Discard pile (right side)
        SizedBox(
          width: cardWidth,
          height: cardHeight,
          child: _DiscardPileWidget(cardWidth: cardWidth),
        ),
      ],
    );
  }
}

/// Selector for individual pyramid card positions.
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
        final game = controller.game as PyramidGame;
        final pile = game.pyramidPiles[pileIndex];
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
          child: _PyramidCardWidget(
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

/// Widget for a single pyramid card/position.
class _PyramidCardWidget extends StatelessWidget {
  final Pile pile;
  final int pileIndex;
  final double cardWidth;
  final bool isUncovered;
  final GameController controller;

  const _PyramidCardWidget({
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
      // Empty slot - just show a subtle placeholder
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

/// Selector for waste pile.
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
          child: WastePileWidget(
            pile: data.pile,
            cardWidth: cardWidth,
            spreadCount: 1,
            controller: controller,
          ),
        );
      },
    );
  }
}

/// Widget for the discard pile in Pyramid.
/// In Pyramid, this is where matched pairs go.
class _DiscardPileWidget extends StatelessWidget {
  final double cardWidth;

  const _DiscardPileWidget({required this.cardWidth});

  @override
  Widget build(BuildContext context) {
    return Selector<GameController, FoundationPileRenderData>(
      selector: (_, controller) {
        final game = controller.game as PyramidGame;
        final pile = game.discard;
        return FoundationPileRenderData(
          pile: pile,
          pileVersion: pile.version,
          isValidDestination: controller.isValidDestination(pile),
          isHintDestination: controller.hintDestinationPile == pile,
        );
      },
      builder: (context, data, _) {
        final controller = Provider.of<GameController>(context, listen: false);
        final cardHeight = cardWidth / CardWidget.aspectRatio;

        return DragTarget<DragData>(
          onWillAcceptWithDetails: (details) {
            return controller.game.isValidMove(
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

                if (data.pile.isEmpty) {
                  return SizedBox(
                    width: cardWidth,
                    height: cardHeight,
                    child: EmptyPileIndicator(
                      width: cardWidth,
                      type: PileIndicatorType.foundation,
                      isHighlighted: isValidDest || isDropTarget,
                      isHintDestination: data.isHintDestination,
                      onTap: () => controller.tapPile(data.pile),
                    ),
                  );
                }

                // Show the top card of the discard pile
                return CardWidget(
                  card: data.pile.topCard!,
                  width: cardWidth,
                  isHighlighted: isDropTarget || isValidDest,
                  isHintDestination: data.isHintDestination,
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
