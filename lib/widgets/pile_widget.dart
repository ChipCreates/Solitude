import 'package:flutter/material.dart';
import 'dart:async';
import '../models/card.dart';
import '../models/pile.dart';
import '../services/game_controller.dart';
import 'card_widget.dart';
import 'pile_indicator.dart';
import 'focused_pile_wrapper.dart';

// A lightweight pointer-based tap/double-tap detector that operates on raw
// pointer events so it isn't blocked by competing gesture recognizers like
// Draggable's internal recognizers. This is used to reliably detect taps and
// double-taps on cards even when wrapped by a Draggable.
class _PointerTapDetector extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onDoubleTap;

  // The `key` parameter is provided for consistency with widgets but is
  // rarely passed for this internal helper. Suppress the analyzer warning
  // about the parameter never being given.
  // ignore: unused_element_parameter
  const _PointerTapDetector({super.key, required this.child, this.onTap, this.onDoubleTap});

  @override
  State<_PointerTapDetector> createState() => _PointerTapDetectorState();
}

class _PointerTapDetectorState extends State<_PointerTapDetector> {
  static const _doubleTapTimeout = Duration(milliseconds: 300);
  static const _moveThreshold = 8.0;

  Offset? _downPosition;
  DateTime? _lastTapTime;
  Timer? _tapTimer;
  bool _moved = false;

  void _onPointerDown(PointerDownEvent event) {
    _downPosition = event.position;
    _moved = false;
  }

  void _onPointerMove(PointerMoveEvent event) {
    if (_downPosition != null && !_moved) {
      if ((event.position - _downPosition!).distance > _moveThreshold) {
        _moved = true;
      }
    }
  }

  void _onPointerUp(PointerUpEvent event) {
    if (_moved) {
      _downPosition = null;
      return;
    }

    final now = DateTime.now();
    if (_lastTapTime != null && now.difference(_lastTapTime!) <= _doubleTapTimeout) {
      // Double-tap detected
      _tapTimer?.cancel();
      _lastTapTime = null;
      widget.onDoubleTap?.call();
    } else {
      // Single tap - delay firing to allow double-tap to occur
      _lastTapTime = now;
      _tapTimer?.cancel();
      _tapTimer = Timer(_doubleTapTimeout, () {
        widget.onTap?.call();
        _lastTapTime = null;
      });
    }

    _downPosition = null;
  }

  @override
  void dispose() {
    _tapTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.opaque,
      onPointerDown: _onPointerDown,
      onPointerMove: _onPointerMove,
      onPointerUp: _onPointerUp,
      child: widget.child,
    );
  }
}

class TableauPileWidget extends StatelessWidget {
  final Pile pile;
  final double cardWidth;
  final double stackOffset;
  final GameController controller;

  const TableauPileWidget({
    super.key,
    required this.pile,
    required this.cardWidth,
    required this.stackOffset,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final cardHeight = cardWidth / CardWidget.aspectRatio;
    final isValidDest = controller.isValidDestination(pile);
    final isHintDest = controller.hintDestinationPile == pile;
    final isHintSource = controller.hintSourcePile == pile;
    final isFocused = controller.focusedPile == pile;

    if (pile.isEmpty) {
      return SizedBox(
        height: cardHeight,
        child: DragTarget<DragData>(
          onWillAcceptWithDetails: (details) {
            return controller.game.isValidMove(
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
                  type: PileIndicatorType.tableau,
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

    // Calculate total height needed
    final totalHeight = cardHeight + (pile.length - 1) * stackOffset;

    return FocusedPileWrapper(
      isFocused: isFocused,
      width: cardWidth,
      child: SizedBox(
        width: cardWidth,
        height: totalHeight,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            for (int i = 0; i < pile.cards.length; i++)
              Positioned(
                key: ValueKey('tableau_${pile.hashCode}_card_${pile.cards[i].suit}_${pile.cards[i].rank}_$i'),
                top: i * stackOffset,
                child: _buildDraggableCard(
                    context, 
                    pile.cards[i], 
                    i, 
                    isHintDest && i == pile.cards.length - 1,
                    isHintSource && controller.hintCards?.contains(pile.cards[i]) == true
                ),
              ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildDraggableCard(BuildContext context, PlayingCard card, int index, bool isHintDest, bool isHintSource) {
    final cardsFromHere = pile.cards.sublist(index);

    if (!card.faceUp) {
      return CardWidget(
        card: card,
        width: cardWidth,
        isSelected: false,
      );
    }

    // Wrap in a pointer-based detector outside the Draggable so taps and
    // double-taps are detected even when Draggable's gesture recognizers are present.
    return _PointerTapDetector(
      onTap: () => controller.tapCard(pile, card),
      onDoubleTap: () => controller.doubleTapCardAnimated(pile, card, cardWidth, stackOffset),
      child: Draggable<DragData>(
        data: DragData(pile: pile, cards: cardsFromHere),
        feedback: Material(
          color: Colors.transparent,
          child: _buildDragFeedback(cardsFromHere),
        ),
        childWhenDragging: Opacity(
          opacity: 0.3,
          child: _buildCardStack(cardsFromHere, isSelected: false),
        ),
        onDragStarted: () => controller.selectCard(pile, card),
        onDragEnd: (_) {},
        child: DragTarget<DragData>(
          onWillAcceptWithDetails: (details) {
            return controller.game.isValidMove(
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
            final isAnimating = controller.isCardAnimating(card);
            return ListenableBuilder(
              listenable: controller.selectionState,
              builder: (context, _) {
                final isSelected = controller.selectionState.isCardSelected(card);
                return Opacity(
                  opacity: isAnimating ? 0.0 : 1.0,
                  child: CardWidget(
                    card: card,
                    width: cardWidth,
                    isSelected: isSelected,
                    isHighlighted: isDropTarget,
                    isHintDestination: isHintDest,
                    isHintSource: isHintSource,
                    // Don't pass tap handlers - handled by outer GestureDetector
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
  
  Widget _buildDragFeedback(List<PlayingCard> cards) {
    return SizedBox(
      width: cardWidth,
      height: cardWidth / CardWidget.aspectRatio + (cards.length - 1) * stackOffset,
      child: Stack(
        children: [
          for (int i = 0; i < cards.length; i++)
            Positioned(
              top: i * stackOffset,
              child: CardWidget(
                card: cards[i],
                width: cardWidth,
                isDragging: true,
              ),
            ),
        ],
      ),
    );
  }
  
  Widget _buildCardStack(List<PlayingCard> cards, {required bool isSelected}) {
    return SizedBox(
      width: cardWidth,
      height: cardWidth / CardWidget.aspectRatio + (cards.length - 1) * stackOffset,
      child: Stack(
        children: [
          for (int i = 0; i < cards.length; i++)
            Positioned(
              key: ValueKey('stack_card_${cards[i].suit}_${cards[i].rank}_$i'),
              top: i * stackOffset,
              child: CardWidget(
                card: cards[i],
                width: cardWidth,
                isSelected: isSelected,
              ),
            ),
        ],
      ),
    );
  }
}

class FoundationPileWidget extends StatelessWidget {
  final Pile pile;
  final double cardWidth;
  final Suit suit;
  final GameController controller;
  
  const FoundationPileWidget({
    super.key,
    required this.pile,
    required this.cardWidth,
    required this.suit,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final isHintDest = controller.hintDestinationPile == pile;
    
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
                type: PileIndicatorType.foundation,
                suit: suit,
                isHighlighted: isValidDest || isDropTarget,
                isHintDestination: isHintDest,
                onTap: () => controller.tapPile(pile),
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

class StockPileWidget extends StatelessWidget {
  final Pile pile;
  final double cardWidth;
  final GameController controller;
  
  const StockPileWidget({
    super.key,
    required this.pile,
    required this.cardWidth,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final isFocused = controller.focusedPile == pile;
    final isHintSource = controller.hintSourcePile == pile;

    if (pile.isEmpty) {
      return EmptyPileIndicator(
        width: cardWidth,
        type: PileIndicatorType.stock,
        isFocused: isFocused,
        isHintSource: isHintSource,
        onTap: () => controller.tapPile(pile),
      );
    }

    // Show stack of cards
    return FocusedPileWrapper(
      isFocused: isFocused,
      width: cardWidth,
      child: GestureDetector(
        onTap: () => controller.tapPile(pile),
        child: SizedBox(
          width: cardWidth,
          height: cardWidth / CardWidget.aspectRatio,
          child: Stack(
            children: [
              // Show depth with offset cards
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
              CardWidget(
                card: pile.topCard!,
                width: cardWidth,
                isHintSource: isHintSource,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class WastePileWidget extends StatelessWidget {
  final Pile pile;
  final double cardWidth;
  final int spreadCount;
  final GameController controller;
  
  const WastePileWidget({
    super.key,
    required this.pile,
    required this.cardWidth,
    required this.spreadCount,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final isFocused = controller.focusedPile == pile;
    final isHintSource = controller.hintSourcePile == pile;

    if (pile.isEmpty) {
      return EmptyPileIndicator(
        width: cardWidth,
        type: PileIndicatorType.waste,
        isFocused: isFocused,
        isHintSource: isHintSource,
      );
    }

    // Show spread cards for draw-3 mode
    final visibleCards = pile.cards.length >= spreadCount
        ? pile.cards.sublist(pile.cards.length - spreadCount)
        : pile.cards;

    final spreadOffset = cardWidth * 0.25;
    final totalWidth = cardWidth + (visibleCards.length - 1) * spreadOffset;

    return FocusedPileWrapper(
      isFocused: isFocused,
      width: totalWidth,
      child: SizedBox(
        width: totalWidth,
        height: cardWidth / CardWidget.aspectRatio,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            for (int i = 0; i < visibleCards.length; i++)
              Positioned(
                key: ValueKey('waste_card_${visibleCards[i].suit}_${visibleCards[i].rank}_$i'),
                left: i * spreadOffset,
                child: i == visibleCards.length - 1
                    ? _buildDraggableTopCard(visibleCards[i], isHintSource)
                    : CardWidget(
                        card: visibleCards[i],
                        width: cardWidth,
                      ),
              ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildDraggableTopCard(PlayingCard card, bool isHintSource) {
    final isAnimating = controller.isCardAnimating(card);

    // Wrap in a pointer-based detector outside the Draggable so taps and
    // double-taps are detected even when Draggable's gesture recognizers are present.
    return _PointerTapDetector(
      onTap: () => controller.tapCard(pile, card),
      onDoubleTap: () => controller.doubleTapCardAnimated(pile, card, cardWidth, 0.0),
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
        childWhenDragging: Opacity(
          opacity: 0.3,
          child: CardWidget(
            card: card,
            width: cardWidth,
          ),
        ),
        onDragStarted: () => controller.selectCard(pile, card),
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
                // Don't pass tap handlers - handled by outer GestureDetector
              ),
            );
          },
        ),
      ),
    );
  }
}

class DragData {
  final Pile pile;
  final List<PlayingCard> cards;
  
  DragData({required this.pile, required this.cards});
}
