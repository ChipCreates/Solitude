import 'dart:async';
import 'package:flutter/material.dart';
import '../games/game_interface.dart';
import '../games/klondike/klondike_game.dart';
import '../models/card.dart';
import '../models/pile.dart';
import '../models/move.dart';
import '../models/difficulty.dart';
import '../widgets/animated_card_overlay.dart';
import 'settings_provider.dart';
import 'statistics_service.dart';
import 'audio_service.dart';
import 'animation_state_notifier.dart';
import 'timer_state_notifier.dart';

enum GameState { playing, won, autoCompleting, autoplaying, lost }

class GameController extends ChangeNotifier {
  final SettingsProvider settingsProvider;
  final StatisticsService statisticsService;
  final AudioService audioService;

  // Separate notifiers for performance optimization
  final AnimationStateNotifier animationState;
  final TimerStateNotifier timerState;

  late GameInterface _game;
  GameState _state = GameState.playing;

  // Selection state
  Pile? _selectedPile;
  List<PlayingCard>? _selectedCards;

  // Hint state - tracks where the hint suggests moving to
  Pile? _hintDestination;

  // Keyboard focus state - tracks which pile has keyboard focus
  Pile? _focusedPile;
  int _focusedPileIndex = -1; // -1 = stock, 0-6 = tableau

  // Pile position tracking
  final Map<Pile, GlobalKey> pileKeys = {};

  // Track if game has been started (first move made)
  bool _gameStarted = false;

  // Inactivity timer for auto-hint
  Timer? _inactivityTimer;
  static const Duration _inactivityThreshold = Duration(seconds: 8);

  GameController({
    required this.settingsProvider,
    required this.statisticsService,
    required this.animationState,
    required this.timerState,
    required this.audioService,
  }) {
    _game = KlondikeGame(
      drawMode: settingsProvider.difficulty.drawMode,
      maxStockRecycles: settingsProvider.difficulty.maxStockRecycles,
    );
    _game.initialize();
    // Listen to settings changes to respond to autoplay and audio toggles
    settingsProvider.addListener(_onSettingsChanged);
  }
  
  // Getters
  GameInterface get game => _game;
  GameState get state => _state;
  Pile? get selectedPile => _selectedPile;
  List<PlayingCard>? get selectedCards => _selectedCards;
  Pile? get hintDestination => _hintDestination;
  Pile? get focusedPile => _focusedPile;

  // Delegate to separate notifiers
  CardAnimationData? get cardAnimationData => animationState.cardAnimationData;
  PlayingCard? get animatingCard => animationState.animatingCard;
  Duration get elapsed => timerState.elapsed;

  int get moveCount => _game.moveCount;
  bool get canUndo => _game.moveHistory.isNotEmpty;
  bool get canRedo => _game is KlondikeGame && (klondike.redoStack.isNotEmpty);
  bool get isWon => _state == GameState.won;
  bool get isLost => _state == GameState.lost;

  // Move history for UI display
  List<Move> get moveHistory => _game.moveHistory;
  List<Move> get redoHistory => _game is KlondikeGame ? klondike.redoStack : [];
  
  // Klondike-specific getters
  KlondikeGame get klondike => _game as KlondikeGame;
  Pile get stock => klondike.stock;
  Pile get waste => klondike.waste;
  List<Pile> get foundations => klondike.foundations;
  List<Pile> get tableau => klondike.tableau;

  /// Initialize pile keys for position tracking
  void initializePileKeys() {
    pileKeys.clear();
    pileKeys[stock] = GlobalKey();
    pileKeys[waste] = GlobalKey();
    for (final foundation in foundations) {
      pileKeys[foundation] = GlobalKey();
    }
    for (final tableauPile in tableau) {
      pileKeys[tableauPile] = GlobalKey();
    }
  }

  /// Get the GlobalKey for a specific pile
  GlobalKey? getKeyForPile(Pile pile) => pileKeys[pile];

  /// Calculate card position from pile position
  Offset? getCardPosition(Pile pile, {double stackOffset = 0}) {
    final key = pileKeys[pile];
    if (key?.currentContext == null) return null;

    final RenderBox? box = key!.currentContext!.findRenderObject() as RenderBox?;
    if (box == null) return null;

    // Get position relative to screen
    final position = box.localToGlobal(Offset.zero);

    // For tableau piles, offset by stack position if there are cards
    if (!pile.isEmpty && stackOffset > 0) {
      final cardIndex = pile.length - 1;
      return Offset(position.dx, position.dy + (cardIndex * stackOffset));
    }

    return position;
  }
  
  void newGame() {
    _stopTimer();
    _stopInactivityTimer();
    timerState.reset();
    _gameStarted = false;

    // Update difficulty settings (draw mode and stock recycle limit)
    if (_game is KlondikeGame) {
      final klondikeGame = _game as KlondikeGame;
      klondikeGame.drawMode = settingsProvider.difficulty.drawMode;
      klondikeGame.maxStockRecycles = settingsProvider.difficulty.maxStockRecycles;
    }

    _game.initialize();
    _state = GameState.playing;
    clearSelection();
    notifyListeners();
  }
  
  void _startTimer() {
    timerState.start();
  }

  void _stopTimer() {
    timerState.stop();
  }
  
  void _recordGameStart() {
    if (!_gameStarted) {
      _gameStarted = true;
      _startTimer();
      statisticsService.recordGameStarted();
      _resetInactivityTimer(); // Start inactivity timer when game begins
    }
  }
  
  /// Reset the inactivity timer - call this on any user interaction
  void _resetInactivityTimer() {
    _inactivityTimer?.cancel();
    _inactivityTimer = null;
    if (_state == GameState.playing && _gameStarted) {
      _inactivityTimer = Timer(_inactivityThreshold, _onInactivityTimeout);
    }
  }
  
  /// Called when player has been inactive - show a hint
  void _onInactivityTimeout() {
    if (_state == GameState.playing && _hintDestination == null && _selectedCards == null) {
      showHint();
      // Restart timer so hint shows again if still inactive
      _resetInactivityTimer();
    }
  }
  
  /// Stop the inactivity timer
  void _stopInactivityTimer() {
    _inactivityTimer?.cancel();
    _inactivityTimer = null;
  }

  void _onSettingsChanged() {
    // If autoplay feature is disabled in settings, ensure we stop any running autoplay
    if (!settingsProvider.autoplay && _state == GameState.autoplaying) {
      stopAutoplay();
    }

    // Sync audio settings
    audioService.setEnabled(settingsProvider.soundEnabled);
    audioService.setVolume(settingsProvider.soundVolume);
  }
  
  void selectCard(Pile pile, PlayingCard card) {
    if (_state != GameState.playing) return;
    
    // If same card selected, deselect
    if (_selectedPile == pile && _selectedCards?.first == card) {
      clearSelection();
      return;
    }
    
    // Can only select face-up cards
    if (!card.faceUp) return;
    
    // Get all cards from selected card to top of pile
    final cardIndex = pile.indexOfCard(card);
    if (cardIndex == -1) return;
    
    final cards = pile.cards.sublist(cardIndex);
    
    // For waste pile, can only select top card
    if (pile.type == PileType.waste && cards.length > 1) {
      _selectedPile = pile;
      _selectedCards = [pile.topCard!];
    } else {
      _selectedPile = pile;
      _selectedCards = cards;
    }
    
    notifyListeners();
  }
  
  void clearSelection() {
    _selectedPile = null;
    _selectedCards = null;
    _hintDestination = null;
    notifyListeners();
  }

  /// Cycle focus to the next pile with Tab key
  void cycleFocusForward() {
    if (_state != GameState.playing) return;

    // Order: stock/waste -> tableau[0] -> tableau[1] -> ... -> tableau[6] -> back to stock
    if (_focusedPileIndex == -1) {
      // Move from stock to first tableau
      _focusedPileIndex = 0;
      _focusedPile = klondike.tableau[0];
    } else if (_focusedPileIndex < 6) {
      // Move to next tableau pile
      _focusedPileIndex++;
      _focusedPile = klondike.tableau[_focusedPileIndex];
    } else {
      // Wrap around to stock
      _focusedPileIndex = -1;
      _focusedPile = klondike.waste.isEmpty ? klondike.stock : klondike.waste;
    }

    notifyListeners();
  }

  /// Cycle focus to the previous pile with Shift+Tab
  void cycleFocusBackward() {
    if (_state != GameState.playing) return;

    if (_focusedPileIndex == -1) {
      // Move from stock to last tableau
      _focusedPileIndex = 6;
      _focusedPile = klondike.tableau[6];
    } else if (_focusedPileIndex > 0) {
      // Move to previous tableau pile
      _focusedPileIndex--;
      _focusedPile = klondike.tableau[_focusedPileIndex];
    } else {
      // Wrap around to stock
      _focusedPileIndex = -1;
      _focusedPile = klondike.waste.isEmpty ? klondike.stock : klondike.waste;
    }

    notifyListeners();
  }

  /// Handle action on the currently focused pile (Enter/Space key)
  void activateFocusedPile() {
    if (_state != GameState.playing || _focusedPile == null) return;

    // If focused pile is stock or waste, tap it
    if (_focusedPile == klondike.stock || _focusedPile == klondike.waste) {
      if (_focusedPile == klondike.stock) {
        tapPile(klondike.stock);
      } else if (!klondike.waste.isEmpty) {
        // Select top card of waste
        selectCard(klondike.waste, klondike.waste.topCard!);
      }
    } else {
      // For tableau piles, select the top face-up card
      if (!_focusedPile!.isEmpty && _focusedPile!.topCard!.faceUp) {
        selectCard(_focusedPile!, _focusedPile!.topCard!);
      }
    }
  }

  void startCardAnimation({
    required PlayingCard card,
    required Offset startPosition,
    required Offset endPosition,
    required double cardWidth,
  }) {
    animationState.startCardAnimation(
      card: card,
      startPosition: startPosition,
      endPosition: endPosition,
      cardWidth: cardWidth,
    );
  }

  void clearCardAnimation() {
    animationState.clearCardAnimation();
  }

  bool isCardAnimating(PlayingCard card) {
    return animationState.isCardAnimating(card);
  }

  /// Execute a move with animation
  /// This should be called from the widget layer where positions can be calculated
  Future<bool> executeAnimatedMove({
    required Pile from,
    required Pile to,
    required PlayingCard card,
    required Offset startPosition,
    required Offset endPosition,
    required double cardWidth,
  }) async {
    if (_state != GameState.playing) return false;

    // Start animation
    startCardAnimation(
      card: card,
      startPosition: startPosition,
      endPosition: endPosition,
      cardWidth: cardWidth,
    );

    // Wait for animation to complete
    await Future.delayed(const Duration(milliseconds: 400));

    // Execute the actual move
    final move = _game.executeMove(from, to, [card]);
    audioService.playCardPlace();
    if (move?.flippedCard == true) {
      audioService.playCardFlip();
    }
    clearSelection();
    clearCardAnimation();
    _checkGameState();
    notifyListeners();

    return true;
  }
  
  bool isSelected(PlayingCard card) {
    return _selectedCards?.contains(card) ?? false;
  }
  
  bool isValidDestination(Pile pile) {
    if (_selectedPile == null || _selectedCards == null) return false;
    return _game.isValidMove(_selectedPile!, pile, _selectedCards!);
  }
  
  List<Pile> getValidDestinations() {
    if (_selectedPile == null || _selectedCards == null) return [];
    return _game.getValidDestinations(_selectedPile!, _selectedCards!);
  }
  
  void tapPile(Pile pile) {
    if (_state != GameState.playing) return;
    _resetInactivityTimer();
    
    // Handle stock tap
    if (pile.type == PileType.stock) {
      _recordGameStart();
      final move = _game.tapStock();
      // Play card flip sound whenever cards are drawn
      if (move != null && move.cards.isNotEmpty) {
        audioService.playCardFlip();
      }
      clearSelection();
      _checkGameState();
      notifyListeners();
      return;
    }
    
    // If we have a selection, try to move to this pile
    if (_selectedPile != null && _selectedCards != null) {
      if (_game.isValidMove(_selectedPile!, pile, _selectedCards!)) {
        _recordGameStart();
        final move = _game.executeMove(_selectedPile!, pile, _selectedCards!);
        audioService.playCardPlace();
        if (move?.flippedCard == true) {
          audioService.playCardFlip();
        }
        clearSelection();
        _checkGameState();
        notifyListeners();
        return;
      } else {
        audioService.playInvalidMove();
      }
    }
    
    // Select the top card of the pile
    if (!pile.isEmpty && pile.topCard!.faceUp) {
      selectCard(pile, pile.topCard!);
    } else {
      clearSelection();
    }
  }
  
  void tapCard(Pile pile, PlayingCard card) {
    if (_state != GameState.playing) return;
    _resetInactivityTimer();
    
    // If we have a selection, try to move to this pile
    if (_selectedPile != null && _selectedCards != null && pile != _selectedPile) {
      if (_game.isValidMove(_selectedPile!, pile, _selectedCards!)) {
        _recordGameStart();
        final move = _game.executeMove(_selectedPile!, pile, _selectedCards!);
        audioService.playCardPlace();
        if (move?.flippedCard == true) {
          audioService.playCardFlip();
        }
        clearSelection();
        _checkGameState();
        notifyListeners();
        return;
      }
    }
    
    // Select this card
    selectCard(pile, card);
  }
  
  /// Handle double-tap on a card with animation - auto-move to best destination
  /// Returns true if a move was made
  Future<bool> doubleTapCardAnimated(Pile pile, PlayingCard card, double cardWidth, double stackOffset) async {
    if (_state != GameState.playing) return false;
    if (!card.faceUp) return false;
    _resetInactivityTimer();

    // Only allow double-tap on top card of pile (or waste)
    if (pile.topCard != card && pile.type != PileType.tableau) return false;

    // For tableau, only allow if it's the top card
    if (pile.type == PileType.tableau && pile.topCard != card) return false;

    _recordGameStart();

    Pile? destinationPile;

    // Priority 1: Aces go to empty foundations
    if (card.rank == Rank.ace) {
      for (final foundation in klondike.foundations) {
        if (foundation.isEmpty && _game.isValidMove(pile, foundation, [card])) {
          destinationPile = foundation;
          break;
        }
      }
    }

    // Priority 2: Cards that can go to foundation (build on existing)
    if (destinationPile == null) {
      for (final foundation in klondike.foundations) {
        if (_game.isValidMove(pile, foundation, [card])) {
          destinationPile = foundation;
          break;
        }
      }
    }

    // Priority 3: Kings go to empty tableau
    if (destinationPile == null && card.rank == Rank.king) {
      final cardIndex = pile.indexOfCard(card);
      final cardsToMove = cardIndex >= 0 ? pile.cards.sublist(cardIndex) : [card];

      for (final tableau in klondike.tableau) {
        if (tableau.isEmpty && tableau != pile && _game.isValidMove(pile, tableau, cardsToMove)) {
          destinationPile = tableau;
          break;
        }
      }
    }

    // Priority 4: Any valid tableau move (prefer non-empty piles)
    if (destinationPile == null) {
      final cardIndex = pile.indexOfCard(card);
      final cardsToMove = cardIndex >= 0 ? pile.cards.sublist(cardIndex) : [card];

      for (final tableau in klondike.tableau) {
        if (!tableau.isEmpty && tableau != pile && _game.isValidMove(pile, tableau, cardsToMove)) {
          destinationPile = tableau;
          break;
        }
      }
    }

    // If we found a destination, animate the move
    if (destinationPile != null) {
      final startPos = getCardPosition(pile, stackOffset: stackOffset);
      final endPos = getCardPosition(destinationPile, stackOffset: stackOffset);

      if (startPos != null && endPos != null) {
        // Trigger animation
        startCardAnimation(
          card: card,
          startPosition: startPos,
          endPosition: endPos,
          cardWidth: cardWidth,
        );

        // Wait for animation to complete
        await Future.delayed(const Duration(milliseconds: 300));

        // Execute the move
        final move = _game.executeMove(pile, destinationPile, [card]);
        audioService.playCardPlace();
        if (move?.flippedCard == true) {
          audioService.playCardFlip();
        }
        clearSelection();
        clearCardAnimation();
        _checkGameState();
        notifyListeners();
        return true;
      }
    }

    // Fall back to non-animated if no destination or positions unavailable
    return false;
  }

  /// Handle double-tap on a card - auto-move to best destination (non-animated fallback)
  /// Returns true if a move was made
  bool doubleTapCard(Pile pile, PlayingCard card) {
    if (_state != GameState.playing) return false;
    if (!card.faceUp) return false;
    _resetInactivityTimer();
    
    // Only allow double-tap on top card of pile (or waste)
    if (pile.topCard != card && pile.type != PileType.tableau) return false;
    
    // For tableau, only allow if it's the top card
    if (pile.type == PileType.tableau && pile.topCard != card) return false;
    
    _recordGameStart();
    
    // Priority 1: Aces go to empty foundations
    if (card.rank == Rank.ace) {
      for (final foundation in klondike.foundations) {
        if (foundation.isEmpty && _game.isValidMove(pile, foundation, [card])) {
          final move = _game.executeMove(pile, foundation, [card]);
          audioService.playCardPlace();
          if (move?.flippedCard == true) {
            audioService.playCardFlip();
          }
          clearSelection();
          _checkGameState();
          notifyListeners();
          return true;
        }
      }
    }

    // Priority 2: Cards that can go to foundation (build on existing)
    for (final foundation in klondike.foundations) {
      if (_game.isValidMove(pile, foundation, [card])) {
        final move = _game.executeMove(pile, foundation, [card]);
        audioService.playCardPlace();
        if (move?.flippedCard == true) {
          audioService.playCardFlip();
        }
        clearSelection();
        _checkGameState();
        notifyListeners();
        return true;
      }
    }
    
    // Priority 3: Kings go to empty tableau
    if (card.rank == Rank.king) {
      // Get all cards from this card to top (for tableau moves)
      final cardIndex = pile.indexOfCard(card);
      final cardsToMove = cardIndex >= 0 ? pile.cards.sublist(cardIndex) : [card];
      
      for (final tableau in klondike.tableau) {
        if (tableau.isEmpty && tableau != pile && _game.isValidMove(pile, tableau, cardsToMove)) {
          final move = _game.executeMove(pile, tableau, cardsToMove);
          audioService.playCardPlace();
          if (move?.flippedCard == true) {
            audioService.playCardFlip();
          }
          clearSelection();
          _checkGameState();
          notifyListeners();
          return true;
        }
      }
    }

    // Priority 4: Any valid tableau move (prefer non-empty piles)
    final cardIndex = pile.indexOfCard(card);
    final cardsToMove = cardIndex >= 0 ? pile.cards.sublist(cardIndex) : [card];

    // First try non-empty piles
    for (final tableau in klondike.tableau) {
      if (!tableau.isEmpty && tableau != pile && _game.isValidMove(pile, tableau, cardsToMove)) {
        final move = _game.executeMove(pile, tableau, cardsToMove);
        audioService.playCardPlace();
        if (move?.flippedCard == true) {
          audioService.playCardFlip();
        }
        clearSelection();
        _checkGameState();
        notifyListeners();
        return true;
      }
    }
    
    return false;
  }
  
  bool tryMove(Pile from, Pile to, List<PlayingCard> cards) {
    if (_state != GameState.playing) return false;
    _resetInactivityTimer();

    if (_game.isValidMove(from, to, cards)) {
      _recordGameStart();
      final move = _game.executeMove(from, to, cards);
      audioService.playCardPlace();
      if (move?.flippedCard == true) {
        audioService.playCardFlip();
      }
      clearSelection();
      _checkGameState();
      notifyListeners();
      return true;
    }

    audioService.playInvalidMove();
    return false;
  }
  
  void undo() {
    if (_state == GameState.autoCompleting || _state == GameState.autoplaying) return;

    if (_game.undo()) {
      clearSelection();
      // If the game was marked lost, undoing may make it playable again
      if (_state == GameState.lost) {
        _state = GameState.playing;
        _startTimer(); // Resume timer
      }
      notifyListeners();
    }
  }

  void redo() {
    if (_state == GameState.autoCompleting || _state == GameState.autoplaying) return;
    if (_game is! KlondikeGame) return;

    if (klondike.redo()) {
      clearSelection();
      // Check game state after redo
      _checkGameState();
      notifyListeners();
    }
  }
  
  /// Check game state after any move and update accordingly
  void _checkGameState() {
    if (_game.checkWin()) {
      _handleWin();
    } else if (settingsProvider.autoComplete && _game.canAutoComplete()) {
      _startAutoComplete();
    } else if (_game is KlondikeGame) {
      final k = _game as KlondikeGame;
      if (k.isTrulyLost()) {
        _handleLoss();
      }
    }
  }

  void _handleLoss() {
    _stopTimer();
    _state = GameState.lost;
    statisticsService.recordLoss();

    // Record Vegas scoring if in Vegas mode
    if (settingsProvider.scoringMode == ScoringMode.vegas) {
      // Count cards in foundations
      int cardsInFoundations = 0;
      if (_game is KlondikeGame) {
        final klondikeGame = _game as KlondikeGame;
        for (final foundation in klondikeGame.foundations) {
          cardsInFoundations += foundation.length;
        }
      }
      // Calculate Vegas score: -52 to start + $5 per card
      final vegasScore = ScoringMode.vegas.vegasGameCost + (cardsInFoundations * ScoringMode.vegas.vegasCardValue);
      statisticsService.recordVegasScore(vegasScore);
    }

    audioService.playInvalidMove();
    notifyListeners();
  }

  void _handleWin() {
    _stopTimer();
    _state = GameState.won;
    audioService.playWin();
    statisticsService.recordWin(time: timerState.elapsed, moves: _game.moveCount);

    // Record Vegas scoring if in Vegas mode (winning = all 52 cards in foundations)
    if (settingsProvider.scoringMode == ScoringMode.vegas) {
      // Vegas win score: -52 + (52 * 5) = 208
      final vegasScore = ScoringMode.vegas.vegasGameCost + (52 * ScoringMode.vegas.vegasCardValue);
      statisticsService.recordVegasScore(vegasScore);
    }

    notifyListeners();
  }
  
  void _startAutoComplete() {
    _state = GameState.autoCompleting;
    notifyListeners();
    
    _runAutoComplete();
  }

  // Autoplay controls
  bool get isAutoplaying => _state == GameState.autoplaying;

  void toggleAutoplay() {
    if (_state == GameState.autoplaying) {
      stopAutoplay();
    } else if (settingsProvider.autoplay) {
      startAutoplay();
    }
  }

  void startAutoplay() {
    if (_state == GameState.autoplaying) return;
    _state = GameState.autoplaying;
    notifyListeners();
    _runAutoplay();
  }

  void stopAutoplay() {
    if (_state != GameState.autoplaying) return;
    _state = GameState.playing;
    _checkGameState(); // Check if lost after stopping
    notifyListeners();
  }

  void clearLoss() {
    if (_state == GameState.lost) {
      _state = GameState.playing;
      _startTimer(); // Resume timer so player can continue trying
      notifyListeners();
    }
  }

  Future<void> _runAutoplay() async {
    if (_game is! KlondikeGame) {
      _state = GameState.playing;
      notifyListeners();
      return;
    }
    
    final k = _game as KlondikeGame;
    
    // Track progress through the stock to detect when we've cycled without progress
    // int drawsSinceLastMove = 0;  // Currently unused, may be used for future heuristics
    int recyclesSinceLastMove = 0;
    
    // Track recent moves to detect oscillation
    final List<String> recentMoveSignatures = [];
    const int maxRecentMoves = 10;

    while (_state == GameState.autoplaying) {
      // Check for win
      if (_game.checkWin()) {
        _handleWin();
        return;
      }
      
      // Check if truly lost
      if (k.isTrulyLost()) {
        _handleLoss();
        return;
      }
      
      // Try to get a hint
      final hint = _game.getHint();
      
      if (hint != null) {
        // Create a signature for this move to detect oscillation
        final sig = _createMoveSignature(hint.from, hint.to, hint.cards);
        
        // Check for oscillation (same move appearing multiple times recently)
        final occurrences = recentMoveSignatures.where((s) => s == sig).length;
        if (occurrences >= 2) {
          // We're oscillating - check if there's anything left to try
          if (k.stock.isEmpty && k.waste.isEmpty) {
            _handleLoss();
            return;
          }
          // Try drawing instead of repeating the move
          _recordGameStart();
          final move = k.tapStock();
          // Play appropriate sound based on draw mode
          if (move != null && move.cards.isNotEmpty) {
            if (move.cards.length == 1) {
              audioService.playCardFlip();
            } else {
              audioService.playCardDraw();
            }
          }
          // drawsSinceLastMove++;
          notifyListeners();
          await Future.delayed(const Duration(milliseconds: 300));
          continue;
        }
        
        // Execute the move
        _recordGameStart();
        final move = _game.executeMove(hint.from, hint.to, hint.cards);
        audioService.playCardPlace();
        if (move?.flippedCard == true) {
          audioService.playCardFlip();
        }

        // Track the move
        recentMoveSignatures.add(sig);
        if (recentMoveSignatures.length > maxRecentMoves) {
          recentMoveSignatures.removeAt(0);
        }
        
        // Reset counters since we made progress
        // drawsSinceLastMove = 0;
        recyclesSinceLastMove = 0;
        
        notifyListeners();
        await Future.delayed(const Duration(milliseconds: 400));
        
      } else {
        // No hint available - try drawing from stock
        if (k.stock.isEmpty && k.waste.isEmpty) {
          // Nothing to draw at all
          _handleLoss();
          return;
        }
        
        // Check if we've recycled twice without making any moves
        // This means we've gone through the entire deck twice with no progress
        if (recyclesSinceLastMove >= 2) {
          _handleLoss();
          return;
        }
        
        _recordGameStart();
        final move = k.tapStock();
        // Play appropriate sound based on draw mode
        if (move != null && move.cards.isNotEmpty) {
          if (move.cards.length == 1) {
            audioService.playCardFlip();
          } else {
            audioService.playCardDraw();
          }
        }
        // drawsSinceLastMove++;
        
        // If we just recycled (waste -> stock), track it
        if (move != null && move.toPile.type == PileType.stock) {
          recyclesSinceLastMove++;
          
          // After recycling, immediately check if we're truly lost
          if (k.isTrulyLost()) {
            _handleLoss();
            return;
          }
        }
        
        notifyListeners();
        await Future.delayed(const Duration(milliseconds: 300));
      }
    }
  }
  
  /// Create a unique signature for a move to detect repetition
  String _createMoveSignature(Pile from, Pile to, List<PlayingCard> cards) {
    final cardIds = cards.map((c) => c.svgId).join(',');
    return '${from.type.name}[${from.index}]->${to.type.name}[${to.index}]:$cardIds';
  }
  
  Future<void> _runAutoComplete() async {
    while (_state == GameState.autoCompleting && !_game.checkWin()) {
      if (_game.autoCompleteStep()) {
        audioService.playCardPlace();
        notifyListeners();
        await Future.delayed(const Duration(milliseconds: 100));
      } else {
        break;
      }
    }
    
    if (_game.checkWin()) {
      _handleWin();
    } else {
      _state = GameState.playing;
      notifyListeners();
    }
  }
  
  void showHint() {
    final hint = _game.getHint();
    if (hint != null) {
      _selectedPile = hint.from;
      _selectedCards = hint.cards;
      _hintDestination = hint.to;
      notifyListeners();
      
      // Auto-clear hint after delay
      Future.delayed(const Duration(seconds: 2), () {
        if (_selectedPile == hint.from && _hintDestination == hint.to) {
          clearSelection();
        }
      });
    }
  }
  
  @override
  void dispose() {
    _stopTimer();
    _stopInactivityTimer();
    settingsProvider.removeListener(_onSettingsChanged);
    audioService.dispose();
    super.dispose();
  }
}
