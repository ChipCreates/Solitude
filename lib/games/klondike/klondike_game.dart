import 'dart:math';
import '../solitaire_game_base.dart';
import '../game_interface.dart';
import '../../models/card.dart';
import '../../models/deck.dart';
import '../../models/pile.dart';
import '../../models/move.dart';
import '../../models/draw_mode.dart';
import '../../models/difficulty.dart';

class KlondikeGame extends SolitaireGameBase {
  late Pile stock;
  late Pile waste;
  late List<Pile> foundations;
  late List<Pile> tableau;

  DrawMode drawMode;
  int? maxStockRecycles; // null = unlimited, otherwise max number of recycles allowed
  final List<Move> _moveHistory = [];
  final List<Move> _redoStack = [];
  int _moveCount = 0;
  int _stockRecycleCount = 0;

  KlondikeGame({this.drawMode = DrawMode.one, this.maxStockRecycles}) {
    _initializePiles();
  }
  
  void _initializePiles() {
    stock = Pile(type: PileType.stock);
    waste = Pile(type: PileType.waste);
    foundations = List.generate(4, (i) => Pile(type: PileType.foundation, index: i));
    tableau = List.generate(7, (i) => Pile(type: PileType.tableau, index: i));
  }
  
  @override
  void initialize({Random? random}) {
    _initializePiles();
    _moveHistory.clear();
    _redoStack.clear();
    _moveCount = 0;
    _stockRecycleCount = 0;

    final deck = Deck();
    deck.shuffle(random ?? Random());
    
    // Deal to tableau: pile i gets i+1 cards
    for (int i = 0; i < 7; i++) {
      for (int j = i; j < 7; j++) {
        final card = deck.draw()!;
        card.faceUp = (j == i); // Only top card is face up
        tableau[j].addCard(card);
      }
    }
    
    // Remaining cards go to stock (face down)
    while (!deck.isEmpty) {
      final card = deck.draw()!;
      card.faceUp = false;
      stock.addCard(card);
    }
  }
  
  @override
  void reset() {
    initialize();
  }
  
  @override
  List<Pile> get allPiles => [stock, waste, ...foundations, ...tableau];

  @override
  int get moveCount => _moveCount;

  @override
  List<Move> get moveHistory => List.unmodifiable(_moveHistory);

  @override
  List<Move> get redoStack => List.unmodifiable(_redoStack);

  @override
  bool get canRedo => _redoStack.isNotEmpty;

  int get stockRecycleCount => _stockRecycleCount;

  /// Check if stock can be recycled (returns false if limit reached)
  bool get canRecycleStock {
    if (maxStockRecycles == null) return true; // Unlimited
    return _stockRecycleCount < maxStockRecycles!;
  }

  @override
  LayoutConfig get layoutConfig => const LayoutConfig(
    tableauCount: 7,
    foundationCount: 4,
    hasStock: true,
    hasWaste: true,
  );

  // ==========================================================================
  // Pile Accessors (GameInterface)
  // ==========================================================================

  @override
  Pile? get stockPile => stock;

  @override
  Pile? get wastePile => waste;

  @override
  List<Pile> get foundationPiles => foundations;

  @override
  List<Pile> get tableauPiles => tableau;

  // ==========================================================================
  // Loss Detection (GameInterface)
  // ==========================================================================

  @override
  bool get isLost => isTrulyLost();

  // ==========================================================================
  // Configuration (GameInterface)
  // ==========================================================================

  @override
  void applyDifficulty(Difficulty difficulty) {
    drawMode = difficulty.drawMode;
    maxStockRecycles = difficulty.maxStockRecycles;
  }

  // ==========================================================================
  // Auto-Move (GameInterface)
  // ==========================================================================

  @override
  Pile? findBestAutoMoveDestination(Pile fromPile, List<PlayingCard> cards) {
    if (cards.isEmpty) return null;
    final card = cards.first;

    // Priority 1: Aces go to empty foundations
    if (card.rank == Rank.ace) {
      for (final foundation in foundations) {
        if (foundation.isEmpty && isValidMove(fromPile, foundation, [card])) {
          return foundation;
        }
      }
    }

    // Priority 2: Cards that can stack on foundations
    for (final foundation in foundations) {
      if (isValidMove(fromPile, foundation, [card])) {
        return foundation;
      }
    }

    // Priority 3: Kings to empty tableau
    if (card.rank == Rank.king) {
      for (final t in tableau) {
        if (t.isEmpty && t != fromPile && isValidMove(fromPile, t, cards)) {
          return t;
        }
      }
    }

    // Priority 4: Any valid tableau (prefer non-empty)
    for (final t in tableau) {
      if (!t.isEmpty && t != fromPile && isValidMove(fromPile, t, cards)) {
        return t;
      }
    }

    return null;
  }
  
  @override
  bool isValidMove(Pile from, Pile to, List<PlayingCard> cards) {
    if (cards.isEmpty) return false;
    final movingCard = cards.first;
    
    // Can't move to stock
    if (to.type == PileType.stock) return false;
    
    // Can't move to waste (only stock draws to waste)
    if (to.type == PileType.waste) return false;
    
    // Foundation moves
    if (to.type == PileType.foundation) {
      // Only single cards to foundation
      if (cards.length > 1) return false;
      return movingCard.canStackOnFoundation(to.topCard);
    }
    
    // Tableau moves
    if (to.type == PileType.tableau) {
      if (to.isEmpty) {
        // Only kings can go on empty tableau
        return movingCard.rank == Rank.king;
      }
      // Must be alternating colors and descending
      return movingCard.canStackOn(to.topCard!, alternatingColors: true, descending: true);
    }
    
    return false;
  }
  
  @override
  Move? executeMove(Pile from, Pile to, List<PlayingCard> cards) {
    if (!isValidMove(from, to, cards)) return null;
    
    // Find index of first card being moved
    final startIndex = from.indexOfCard(cards.first);
    if (startIndex == -1) return null;
    
    // Check if we'll need to flip a card after this move
    bool willFlipCard = false;
    if (from.type == PileType.tableau && startIndex > 0) {
      final cardBelow = from.cardAt(startIndex - 1);
      if (cardBelow != null && !cardBelow.faceUp) {
        willFlipCard = true;
      }
    }
    
    // Remove cards from source
    final removed = from.removeFrom(startIndex);
    
    // Add to destination
    to.addCards(removed);
    
    // Flip the newly exposed card if needed
    if (willFlipCard) {
      from.flipTopCard();
    }
    
    // Record move
    final move = Move(
      fromPile: from,
      toPile: to,
      cards: removed,
      flippedCard: willFlipCard,
    );
    _moveHistory.add(move);
    _redoStack.clear(); // Clear redo stack when a new move is made
    _moveCount++;

    return move;
  }
  
  @override
  Move? tapStock() {
    if (stock.isEmpty) {
      // Recycle waste back to stock
      if (waste.isEmpty) return null;

      // Check if recycling is allowed
      if (!canRecycleStock) return null;

      final wasteCards = waste.removeAll();
      for (final card in wasteCards.reversed) {
        card.faceUp = false;
        stock.addCard(card);
      }
      _stockRecycleCount++;

      // Record as a special move for undo
      final move = Move(
        fromPile: waste,
        toPile: stock,
        cards: wasteCards,
        drewFromStock: true,
        stockRecycleCount: _stockRecycleCount,
      );
      _moveHistory.add(move);
      _redoStack.clear(); // Clear redo stack when a new move is made
      _moveCount++;
      return move;
    }
    
    // Draw cards from stock to waste
    final drawCount = drawMode == DrawMode.one ? 1 : 3;
    final drawnCards = <PlayingCard>[];
    
    for (int i = 0; i < drawCount && !stock.isEmpty; i++) {
      final card = stock.removeTop()!;
      card.faceUp = true;
      waste.addCard(card);
      drawnCards.add(card);
    }
    
    final move = Move(
      fromPile: stock,
      toPile: waste,
      cards: drawnCards,
      drewFromStock: true,
    );
    _moveHistory.add(move);
    _redoStack.clear(); // Clear redo stack when a new move is made
    _moveCount++;

    return move;
  }
  
  @override
  bool undo() {
    if (_moveHistory.isEmpty) return false;

    final move = _moveHistory.removeLast();
    _redoStack.add(move); // Add to redo stack
    _moveCount--;

    // Handle stock recycle undo
    if (move.drewFromStock && move.toPile.type == PileType.stock) {
      // Undo a recycle: move all cards back to waste
      final stockCards = stock.removeAll();
      for (final card in stockCards.reversed) {
        card.faceUp = true;
        waste.addCard(card);
      }
      _stockRecycleCount--;
      return true;
    }

    // Handle normal stock draw undo
    if (move.drewFromStock) {
      for (final card in move.cards.reversed) {
        waste.removeTop();
        card.faceUp = false;
        stock.addCard(card);
      }
      return true;
    }

    // Handle normal move undo
    // If a card was flipped, un-flip it
    if (move.flippedCard && move.fromPile.topCard != null) {
      move.fromPile.topCard!.faceUp = false;
    }

    // Move cards back
    for (final card in move.cards) {
      move.toPile.removeTop();
      move.fromPile.addCard(card);
    }

    return true;
  }

  /// Redo the last undone move
  @override
  bool redo() {
    if (_redoStack.isEmpty) return false;

    final move = _redoStack.removeLast();
    _moveCount++;

    // Handle stock recycle redo
    if (move.drewFromStock && move.toPile.type == PileType.stock) {
      // Redo a recycle: move all cards from waste back to stock
      final wasteCards = waste.removeAll();
      for (final card in wasteCards.reversed) {
        card.faceUp = false;
        stock.addCard(card);
      }
      _stockRecycleCount++;
      _moveHistory.add(move);
      return true;
    }

    // Handle normal stock draw redo
    if (move.drewFromStock) {
      for (final card in move.cards) {
        stock.removeTop();
        card.faceUp = true;
        waste.addCard(card);
      }
      _moveHistory.add(move);
      return true;
    }

    // Handle normal move redo
    // Find index of first card being moved
    final startIndex = move.fromPile.indexOfCard(move.cards.first);
    if (startIndex == -1) return false;

    // Remove cards from source
    final removed = move.fromPile.removeFrom(startIndex);

    // Add to destination
    move.toPile.addCards(removed);

    // Flip the newly exposed card if needed
    if (move.flippedCard && move.fromPile.topCard != null) {
      move.fromPile.flipTopCard();
    }

    _moveHistory.add(move);
    return true;
  }
  
  @override
  bool checkWin() {
    // Win when all foundations have 13 cards (Ace through King)
    return foundations.every((f) => f.length == 13);
  }
  
  @override
  bool canAutoComplete() {
    // Can auto-complete when all cards in tableau and stock/waste are face-up
    // Essentially, no hidden cards remain
    for (final pile in tableau) {
      for (final card in pile.cards) {
        if (!card.faceUp) return false;
      }
    }
    return stock.isEmpty;
  }
  
  @override
  bool autoCompleteStep() {
    // Try to move cards to foundations
    // Check waste first
    if (!waste.isEmpty) {
      final card = waste.topCard!;
      for (final foundation in foundations) {
        if (card.canStackOnFoundation(foundation.topCard)) {
          executeMove(waste, foundation, [card]);
          return true;
        }
      }
    }
    
    // Check tableau piles
    for (final pile in tableau) {
      if (pile.isEmpty) continue;
      final card = pile.topCard!;
      for (final foundation in foundations) {
        if (card.canStackOnFoundation(foundation.topCard)) {
          executeMove(pile, foundation, [card]);
          return true;
        }
      }
    }
    
    return false;
  }
  
  @override
  List<Pile> getValidDestinations(Pile from, List<PlayingCard> cards) {
    final destinations = <Pile>[];
    
    for (final foundation in foundations) {
      if (isValidMove(from, foundation, cards)) {
        destinations.add(foundation);
      }
    }
    
    for (final pile in tableau) {
      if (pile != from && isValidMove(from, pile, cards)) {
        destinations.add(pile);
      }
    }
    
    return destinations;
  }

  @override
  bool canDrawFromStock() {
    return !stock.isEmpty;
  }

  @override
  bool hasValidWasteMoves() {
    if (waste.isEmpty) return false;
    final card = waste.topCard!;
    // Check foundations
    for (final foundation in foundations) {
      if (card.canStackOnFoundation(foundation.topCard)) return true;
    }
    // Check tableau
    for (final pile in tableau) {
      if (isValidMove(waste, pile, [card])) return true;
    }
    return false;
  }

  @override
  bool hasValidTableauMoves() {
    for (final fromPile in tableau) {
      if (fromPile.isEmpty) continue;

      // Consider each possible face-up run
      for (int i = 0; i < fromPile.cards.length; i++) {
        final c = fromPile.cardAt(i);
        if (c == null || !c.faceUp) continue;
        final cardsToMove = fromPile.cards.sublist(i);

        // Try moving to foundations
        for (final foundation in foundations) {
          if (cardsToMove.length == 1 && cardsToMove.first.canStackOnFoundation(foundation.topCard)) return true;
        }

        // Try moving to other tableau piles
        for (final toPile in tableau) {
          if (toPile == fromPile) continue;
          if (isValidMove(fromPile, toPile, cardsToMove)) return true;
        }
      }
    }
    return false;
  }

  /// Returns true if the game is in a lost state (no moves available and
  /// cannot possibly reveal any face-down cards or draw any more).
  bool isTrulyLost() {
    // If stock has cards, we can draw
    if (!stock.isEmpty) return false;

    // Check if any card in waste could move anywhere
    if (!waste.isEmpty) {
      for (final card in waste.cards) {
        // Check foundations
        for (final foundation in foundations) {
          if (card.canStackOnFoundation(foundation.topCard)) return false;
        }
        // Check tableau
        for (final pile in tableau) {
          if (pile.isEmpty) {
            if (card.rank == Rank.king) return false;
          } else if (card.canStackOn(pile.topCard!, alternatingColors: true, descending: true)) {
            return false;
          }
        }
      }
    }

    // Check tableau moves that would make progress
    for (final fromPile in tableau) {
      if (fromPile.isEmpty) continue;

      for (int i = 0; i < fromPile.cards.length; i++) {
        final c = fromPile.cardAt(i);
        if (c == null || !c.faceUp) continue;
        final cardsToMove = fromPile.cards.sublist(i);

        // Moves to foundations are always progress
        if (cardsToMove.length == 1) {
          final top = cardsToMove.first;
          for (final foundation in foundations) {
            if (top.canStackOnFoundation(foundation.topCard)) return false;
          }
        }

        // Tableau moves that expose face-down cards are progress
        final wouldExposeCard = i > 0 && !fromPile.cardAt(i - 1)!.faceUp;
        
        for (final toPile in tableau) {
          if (toPile == fromPile) continue;
          if (!isValidMove(fromPile, toPile, cardsToMove)) continue;
          
          // Moving to non-empty pile or exposing a card = progress
          if (!toPile.isEmpty || wouldExposeCard) {
            return false;
          }
        }
      }
    }

    // No useful moves available
    return true;
  }
  
  @override
  ({Pile from, Pile to, List<PlayingCard> cards})? getHint() {
    // Priority 1: Move cards to foundations (always good)
    // Check waste to foundation
    if (!waste.isEmpty) {
      final card = waste.topCard!;
      for (final foundation in foundations) {
        if (card.canStackOnFoundation(foundation.topCard)) {
          return (from: waste, to: foundation, cards: [card]);
        }
      }
    }
    
    // Check tableau to foundation
    for (final pile in tableau) {
      if (pile.isEmpty) continue;
      final card = pile.topCard!;
      for (final foundation in foundations) {
        if (card.canStackOnFoundation(foundation.topCard)) {
          return (from: pile, to: foundation, cards: [card]);
        }
      }
    }
    
    // Priority 2: Moves that expose face-down cards
    for (final fromPile in tableau) {
      if (fromPile.isEmpty) continue;
      
      // Find the first face-up card
      int firstFaceUp = -1;
      for (int i = 0; i < fromPile.cards.length; i++) {
        if (fromPile.cards[i].faceUp) {
          firstFaceUp = i;
          break;
        }
      }
      
      // Only interested if there's a face-down card to expose
      if (firstFaceUp <= 0) continue;
      
      final cardsToMove = fromPile.cards.sublist(firstFaceUp);
      
      // Try moving to non-empty tableau piles first
      for (final toPile in tableau) {
        if (toPile == fromPile) continue;
        if (toPile.isEmpty) continue;
        if (isValidMove(fromPile, toPile, cardsToMove)) {
          return (from: fromPile, to: toPile, cards: cardsToMove);
        }
      }
      
      // Then try empty piles (only if moving a King)
      if (cardsToMove.first.rank == Rank.king) {
        for (final toPile in tableau) {
          if (toPile == fromPile) continue;
          if (!toPile.isEmpty) continue;
          if (isValidMove(fromPile, toPile, cardsToMove)) {
            return (from: fromPile, to: toPile, cards: cardsToMove);
          }
        }
      }
    }
    
    // Priority 3: Waste to tableau (brings new cards into play)
    if (!waste.isEmpty) {
      final card = waste.topCard!;
      // Prefer non-empty piles
      for (final pile in tableau) {
        if (pile.isEmpty) continue;
        if (isValidMove(waste, pile, [card])) {
          return (from: waste, to: pile, cards: [card]);
        }
      }
      // Then empty piles for Kings
      if (card.rank == Rank.king) {
        for (final pile in tableau) {
          if (!pile.isEmpty) continue;
          if (isValidMove(waste, pile, [card])) {
            return (from: waste, to: pile, cards: [card]);
          }
        }
      }
    }
    
    // Priority 4: Tableau to tableau that builds stacks (no face-down exposure)
    for (final fromPile in tableau) {
      if (fromPile.isEmpty) continue;
      
      int firstFaceUp = 0;
      for (int i = 0; i < fromPile.cards.length; i++) {
        if (fromPile.cards[i].faceUp) {
          firstFaceUp = i;
          break;
        }
      }
      
      // Skip if this would expose a card (already handled in Priority 2)
      if (firstFaceUp > 0) continue;
      
      final cardsToMove = fromPile.cards.sublist(firstFaceUp);
      
      // Only move to non-empty piles (avoid shuffling Kings to empty)
      for (final toPile in tableau) {
        if (toPile == fromPile) continue;
        if (toPile.isEmpty) continue;
        if (isValidMove(fromPile, toPile, cardsToMove)) {
          return (from: fromPile, to: toPile, cards: cardsToMove);
        }
      }
    }
    
    // No useful moves found - caller should try drawing from stock
    return null;
  }
  
  void setDrawMode(DrawMode mode) {
    drawMode = mode;
  }
}
