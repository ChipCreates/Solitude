import 'dart:async';
import 'package:flutter/material.dart';
import '../games/game_interface.dart';
import '../games/game_factory.dart';
import '../models/card.dart';
import '../models/pile.dart';
import '../models/move.dart';
import '../models/difficulty.dart';
import '../widgets/animated_card_overlay.dart';
import 'settings_provider.dart';
import 'statistics_service.dart';
import 'audio_service.dart';
import 'animation_state_notifier.dart';
import 'hint_state_notifier.dart';
import 'selection_state_notifier.dart';
import 'timer_state_notifier.dart';

enum GameState { playing, won, autoCompleting, autoplaying, lost }

class GameController extends ChangeNotifier {
  final SettingsProvider settingsProvider;
  final StatisticsService statisticsService;
  final AudioService audioService;

  // Separate notifiers for performance optimization
  final AnimationStateNotifier animationState;
  final HintStateNotifier hintState;
  final SelectionStateNotifier selectionState;
  final TimerStateNotifier timerState;

  late GameInterface _game;
  GameState _state = GameState.playing;

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
    required this.hintState,
    required this.selectionState,
    required this.timerState,
    required this.audioService,
  }) {
    _game = GameFactory.createGame(GameType.klondike);
    _game.applyDifficulty(settingsProvider.difficulty);
    _game.initialize();
    // Listen to settings changes to respond to autoplay and audio toggles
    settingsProvider.addListener(_onSettingsChanged);
  }

  // Getters
  GameInterface get game => _game;
  GameState get state => _state;
  Pile? get selectedPile => selectionState.selectedPile;
  List<PlayingCard>? get selectedCards => selectionState.selectedCards;
  Pile? get hintSourcePile => hintState.sourcePile;
  List<PlayingCard>? get hintCards => hintState.cards;
  Pile? get hintDestinationPile => hintState.destinationPile;
  Pile? get focusedPile => _focusedPile;

  // Delegate to separate notifiers
  CardAnimationData? get cardAnimationData => animationState.cardAnimationData;
  PlayingCard? get animatingCard => animationState.animatingCard;
  Duration get elapsed => timerState.elapsed;

  int get moveCount => _game.moveCount;
  bool get canUndo => _game.moveHistory.isNotEmpty;
  bool get canRedo => _game.canRedo;
  bool get isWon => _state == GameState.won;
  bool get isLost => _state == GameState.lost;

  // Move history for UI display
  List<Move> get moveHistory => _game.moveHistory;
  List<Move> get redoHistory => _game.redoStack;

  // Game-agnostic pile accessors
  Pile? get stock => _game.stockPile;
  Pile? get waste => _game.wastePile;
  List<Pile> get foundations => _game.foundationPiles;
  List<Pile> get tableau => _game.tableauPiles;

  /// Initialize pile keys for position tracking
  void initializePileKeys() {
    pileKeys.clear();
    final stockPile = _game.stockPile;
    final wastePile = _game.wastePile;
    if (stockPile != null) {
      pileKeys[stockPile] = GlobalKey();
    }
    if (wastePile != null) {
      pileKeys[wastePile] = GlobalKey();
    }
    for (final foundation in _game.foundationPiles) {
      pileKeys[foundation] = GlobalKey();
    }
    for (final tableauPile in _game.tableauPiles) {
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

    // Update difficulty settings via game interface
    _game.applyDifficulty(settingsProvider.difficulty);

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
    if (_state == GameState.playing && !hintState.isActive && !selectionState.hasSelection) {
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
    if (selectionState.selectedPile == pile && selectionState.selectedCards?.first == card) {
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
      selectionState.setSelection(pile: pile, cards: [pile.topCard!]);
    } else {
      selectionState.setSelection(pile: pile, cards: cards);
    }
  }

  void clearSelection() {
    selectionState.clear();
    clearHint();
  }

  void clearHint() {
    hintState.clear();
  }

  /// Cycle focus to the next pile with Tab key
  void cycleFocusForward() {
    if (_state != GameState.playing) return;

    final tableauPiles = _game.tableauPiles;
    final tableauCount = tableauPiles.length;
    final wastePile = _game.wastePile;
    final stockPile = _game.stockPile;

    // Order: stock/waste -> tableau[0] -> tableau[1] -> ... -> tableau[n-1] -> back to stock
    if (_focusedPileIndex == -1) {
      // Move from stock to first tableau
      _focusedPileIndex = 0;
      _focusedPile = tableauPiles.isNotEmpty ? tableauPiles[0] : stockPile;
    } else if (_focusedPileIndex < tableauCount - 1) {
      // Move to next tableau pile
      _focusedPileIndex++;
      _focusedPile = tableauPiles[_focusedPileIndex];
    } else {
      // Wrap around to stock/waste
      _focusedPileIndex = -1;
      _focusedPile = (wastePile != null && !wastePile.isEmpty) ? wastePile : stockPile;
    }

    notifyListeners();
  }

  /// Cycle focus to the previous pile with Shift+Tab
  void cycleFocusBackward() {
    if (_state != GameState.playing) return;

    final tableauPiles = _game.tableauPiles;
    final tableauCount = tableauPiles.length;
    final wastePile = _game.wastePile;
    final stockPile = _game.stockPile;

    if (_focusedPileIndex == -1) {
      // Move from stock to last tableau
      _focusedPileIndex = tableauCount - 1;
      _focusedPile = tableauPiles.isNotEmpty ? tableauPiles[_focusedPileIndex] : stockPile;
    } else if (_focusedPileIndex > 0) {
      // Move to previous tableau pile
      _focusedPileIndex--;
      _focusedPile = tableauPiles[_focusedPileIndex];
    } else {
      // Wrap around to stock/waste
      _focusedPileIndex = -1;
      _focusedPile = (wastePile != null && !wastePile.isEmpty) ? wastePile : stockPile;
    }

    notifyListeners();
  }

  /// Handle action on the currently focused pile (Enter/Space key)
  void activateFocusedPile() {
    if (_state != GameState.playing || _focusedPile == null) return;

    final stockPile = _game.stockPile;
    final wastePile = _game.wastePile;

    // If focused pile is stock or waste, tap it
    if (_focusedPile == stockPile || _focusedPile == wastePile) {
      if (_focusedPile == stockPile && stockPile != null) {
        tapPile(stockPile);
      } else if (wastePile != null && !wastePile.isEmpty) {
        // Select top card of waste
        selectCard(wastePile, wastePile.topCard!);
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
    return selectionState.isCardSelected(card);
  }

  bool isValidDestination(Pile pile) {
    final selectedPile = selectionState.selectedPile;
    final selectedCards = selectionState.selectedCards;
    if (selectedPile == null || selectedCards == null) return false;
    return _game.isValidMove(selectedPile, pile, selectedCards);
  }

  List<Pile> getValidDestinations() {
    final selectedPile = selectionState.selectedPile;
    final selectedCards = selectionState.selectedCards;
    if (selectedPile == null || selectedCards == null) return [];
    return _game.getValidDestinations(selectedPile, selectedCards);
  }
  
  void tapPile(Pile pile) {
    if (_state != GameState.playing) return;
    _resetInactivityTimer();
    clearHint();

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
    final selectedPile = selectionState.selectedPile;
    final selectedCards = selectionState.selectedCards;
    if (selectedPile != null && selectedCards != null) {
      if (_game.isValidMove(selectedPile, pile, selectedCards)) {
        _recordGameStart();
        final move = _game.executeMove(selectedPile, pile, selectedCards);
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
    clearHint();

    // If we have a selection, try to move to this pile
    final selectedPile = selectionState.selectedPile;
    final selectedCards = selectionState.selectedCards;
    if (selectedPile != null && selectedCards != null && pile != selectedPile) {
      if (_game.isValidMove(selectedPile, pile, selectedCards)) {
        _recordGameStart();
        final move = _game.executeMove(selectedPile, pile, selectedCards);
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
    clearHint();

    // Only allow double-tap on top card of pile (or waste)
    if (pile.topCard != card && pile.type != PileType.tableau) return false;

    // For tableau, only allow if it's the top card
    if (pile.type == PileType.tableau && pile.topCard != card) return false;

    _recordGameStart();

    // Get cards to move (for tableau, may be a stack)
    final cardIndex = pile.indexOfCard(card);
    final cardsToMove = cardIndex >= 0 ? pile.cards.sublist(cardIndex) : [card];

    // Ask the game for the best destination
    final destinationPile = _game.findBestAutoMoveDestination(pile, cardsToMove);

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
        final move = _game.executeMove(pile, destinationPile, cardsToMove);
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
    clearHint();

    // Only allow double-tap on top card of pile (or waste)
    if (pile.topCard != card && pile.type != PileType.tableau) return false;

    // For tableau, only allow if it's the top card
    if (pile.type == PileType.tableau && pile.topCard != card) return false;

    _recordGameStart();

    // Get cards to move (for tableau, may be a stack)
    final cardIndex = pile.indexOfCard(card);
    final cardsToMove = cardIndex >= 0 ? pile.cards.sublist(cardIndex) : [card];

    // Ask the game for the best destination
    final destinationPile = _game.findBestAutoMoveDestination(pile, cardsToMove);

    if (destinationPile != null) {
      final move = _game.executeMove(pile, destinationPile, cardsToMove);
      audioService.playCardPlace();
      if (move?.flippedCard == true) {
        audioService.playCardFlip();
      }
      clearSelection();
      _checkGameState();
      notifyListeners();
      return true;
    }

    return false;
  }
  
  bool tryMove(Pile from, Pile to, List<PlayingCard> cards) {
    if (_state != GameState.playing) return false;
    _resetInactivityTimer();
    clearHint();

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
    clearHint();

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
    clearHint();

    if (_game.redo()) {
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
    } else if (_game.isLost) {
      _handleLoss();
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
      for (final foundation in _game.foundationPiles) {
        cardsInFoundations += foundation.length;
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
    final stockPile = _game.stockPile;
    final wastePile = _game.wastePile;

    // Track progress through the stock to detect when we've cycled without progress
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
      if (_game.isLost) {
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
          final stockEmpty = stockPile == null || stockPile.isEmpty;
          final wasteEmpty = wastePile == null || wastePile.isEmpty;
          if (stockEmpty && wasteEmpty) {
            _handleLoss();
            return;
          }
          // Try drawing instead of repeating the move
          _recordGameStart();
          final move = _game.tapStock();
          // Play appropriate sound based on draw mode
          if (move != null && move.cards.isNotEmpty) {
            if (move.cards.length == 1) {
              audioService.playCardFlip();
            } else {
              audioService.playCardDraw();
            }
          }
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
        recyclesSinceLastMove = 0;

        notifyListeners();
        await Future.delayed(const Duration(milliseconds: 400));

      } else {
        // No hint available - try drawing from stock
        final stockEmpty = stockPile == null || stockPile.isEmpty;
        final wasteEmpty = wastePile == null || wastePile.isEmpty;
        if (stockEmpty && wasteEmpty) {
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
        final move = _game.tapStock();
        // Play appropriate sound based on draw mode
        if (move != null && move.cards.isNotEmpty) {
          if (move.cards.length == 1) {
            audioService.playCardFlip();
          } else {
            audioService.playCardDraw();
          }
        }

        // If we just recycled (waste -> stock), track it
        if (move != null && move.toPile.type == PileType.stock) {
          recyclesSinceLastMove++;

          // After recycling, immediately check if we're truly lost
          if (_game.isLost) {
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
    clearHint();

    // Check for stock draw/recycle
    if (_game.stockPile != null && _game.stockPile!.isEmpty && _game.wastePile != null && !_game.wastePile!.isEmpty) {
        // Recycle suggestion - hint source and destination are both stock
        hintState.setHint(
          sourcePile: _game.stockPile!,
          cards: null,
          destinationPile: _game.stockPile!,
        );
        return;
    }

    final hint = _game.getHint();
    if (hint != null) {
      hintState.setHint(
        sourcePile: hint.from,
        cards: hint.cards,
        destinationPile: hint.to,
      );

      // Auto-clear hint after delay
      Future.delayed(const Duration(seconds: 2), () {
        if (hintState.sourcePile == hint.from && hintState.destinationPile == hint.to) {
          clearHint();
        }
      });
    } else {
      // No moves available, try suggesting drawing from stock
      if (_game.stockPile != null && !_game.stockPile!.isEmpty) {
        hintState.setHint(
          sourcePile: _game.stockPile!,
          cards: null,
          destinationPile: _game.stockPile!,
        );
        Future.delayed(const Duration(seconds: 2), () {
            if (hintState.sourcePile == _game.stockPile) {
                clearHint();
            }
        });
      } else {
          // Absolutely no moves
          audioService.playInvalidMove();
      }
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
