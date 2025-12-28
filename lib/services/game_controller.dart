import 'dart:async';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import '../games/game_interface.dart';
import '../games/game_factory.dart';
import '../models/card.dart';
import '../models/pile.dart';
import '../models/move.dart';
import '../models/difficulty.dart';
import '../models/game_event.dart';
import '../widgets/animated_card_overlay.dart';
import 'settings_provider.dart';
import 'statistics_service.dart';
import 'animation_state_notifier.dart';
import 'hint_state_notifier.dart';
import 'selection_state_notifier.dart';
import 'timer_state_notifier.dart';
import 'board_layout_service.dart';
import 'solitaire_bot.dart';

enum GameState { playing, won, autoCompleting, autoplaying, lost }

class GameController extends ChangeNotifier {
  final SettingsProvider settingsProvider;
  final StatisticsService statisticsService;
  final BoardLayoutService boardLayout;

  // Separate notifiers for performance optimization
  final AnimationStateNotifier animationState;
  final HintStateNotifier hintState;
  final SelectionStateNotifier selectionState;
  final TimerStateNotifier timerState;

  late GameInterface _game;
  GameState _state = GameState.playing;

  // Keyboard focus state - tracks which pile has keyboard focus
  Pile? _focusedPile;

  // Track if game has been started (first move made)
  bool _gameStarted = false;

  // Inactivity timer for auto-hint
  Timer? _inactivityTimer;
  static const Duration _inactivityThreshold = Duration(seconds: 8);

  // Bot for autoplay and auto-complete
  late SolitaireBot _bot;

  // Event stream for services
  final StreamController<GameEvent> _eventController = StreamController<GameEvent>.broadcast();
  Stream<GameEvent> get gameEvents => _eventController.stream;

  GameController({
    required this.settingsProvider,
    required this.statisticsService,
    required this.animationState,
    required this.hintState,
    required this.selectionState,
    required this.timerState,
    required this.boardLayout,
  }) {
    _game = GameFactory.createGame(GameType.klondike);
    _game.applyDifficulty(settingsProvider.difficulty);
    _game.initialize();
    _bot = SolitaireBot(
      _game,
      () => notifyListeners(),
      _handleWin,
      _handleLoss,
      _eventController.add,
    );
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
  
  // Game state shortcuts for UI
  int get moveCount => _game.moveCount;
  bool get canUndo => _game.moveHistory.isNotEmpty;
  bool get canRedo => _game.canRedo;
  bool get isWon => _state == GameState.won;
  bool get isLost => _game.isLost || _state == GameState.lost;
  List<Move> get moveHistory => _game.moveHistory;
  List<Move> get redoHistory => _game.redoStack;
  
  // Game interface shortcuts
  Pile? get stock => _game.stockPile;
  Pile? get waste => _game.wastePile;
  List<Pile> get foundations => _game.foundationPiles;
  List<Pile> get tableau => _game.tableauPiles;

  // Delegate to separate notifiers
  CardAnimationData? get cardAnimationData => animationState.cardAnimationData;
  PlayingCard? get animatingCard => animationState.animatingCard;
  Duration get elapsed => timerState.elapsed;
  
  // Delegate to board layout service
  void initializePileKeys() => boardLayout.initializePileKeys(_game.allPiles);
  String? getPileId(Pile pile) => pile.id;
  Offset? getCardPosition(Pile pile, {double stackOffset = 0}) => 
      boardLayout.getCardPosition(pile, stackOffset: stackOffset);
  
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
  }

  void _emitMoveEvent(Move? move) {
    if (move != null) {
      _eventController.add(GameEvent(GameEventType.moveExecuted, move));
      if (move.flippedCard == true) {
        _eventController.add(const GameEvent(GameEventType.cardFlipped));
      }
    }
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

    final focusablePiles = _game.focusablePiles;
    if (focusablePiles.isEmpty) return;

    if (_focusedPile == null) {
      _focusedPile = focusablePiles.first;
    } else {
      final currentIndex = focusablePiles.indexOf(_focusedPile!);
      if (currentIndex >= 0) {
        final nextIndex = (currentIndex + 1) % focusablePiles.length;
        _focusedPile = focusablePiles[nextIndex];
      } else {
        _focusedPile = focusablePiles.first;
      }
    }

    notifyListeners();
  }

  /// Cycle focus to the previous pile with Shift+Tab
  void cycleFocusBackward() {
    if (_state != GameState.playing) return;

    final focusablePiles = _game.focusablePiles;
    if (focusablePiles.isEmpty) return;

    if (_focusedPile == null) {
      _focusedPile = focusablePiles.last;
    } else {
      final currentIndex = focusablePiles.indexOf(_focusedPile!);
      if (currentIndex >= 0) {
        final prevIndex = (currentIndex - 1 + focusablePiles.length) % focusablePiles.length;
        _focusedPile = focusablePiles[prevIndex];
      } else {
        _focusedPile = focusablePiles.last;
      }
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
    _emitMoveEvent(move);
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

    // Handle game-specific pile tap
    final move = _game.handlePileTap(pile);
    if (move != null) {
      _recordGameStart();
      _emitMoveEvent(move);
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
        _emitMoveEvent(move);
        clearSelection();
        _checkGameState();
        notifyListeners();
        return;
      } else {
        _eventController.add(const GameEvent(GameEventType.invalidMove));
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
        _emitMoveEvent(move);
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
      final startPosition = getCardPosition(pile, stackOffset: stackOffset) ?? Offset.zero;
      final endPosition = getCardPosition(destinationPile) ?? Offset.zero;

      // Trigger animation
      startCardAnimation(
        card: card,
        startPosition: startPosition,
        endPosition: endPosition,
        cardWidth: cardWidth,
      );

      // Wait for animation to complete
      await Future.delayed(const Duration(milliseconds: 300));

      // Execute the move
      final move = _game.executeMove(pile, destinationPile, cardsToMove);
      _emitMoveEvent(move);
      clearSelection();
      clearCardAnimation();
      _checkGameState();
      notifyListeners();
      return true;
    }

    // Fall back to non-animated if no destination
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
      _emitMoveEvent(move);
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
      _emitMoveEvent(move);
      clearSelection();
      _checkGameState();
      notifyListeners();
      return true;
    }

    _eventController.add(const GameEvent(GameEventType.invalidMove));
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
    _eventController.add(const GameEvent(GameEventType.gameLost));

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

    notifyListeners();
  }

  void _handleWin() {
    _stopTimer();
    _state = GameState.won;
    statisticsService.recordWin(time: timerState.elapsed, moves: _game.moveCount);
    _eventController.add(const GameEvent(GameEventType.gameWon));

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
    
    _bot.startAutoComplete();
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
    _bot.startAutoplay();
  }

  void stopAutoplay() {
    if (_state != GameState.autoplaying) return;
    _bot.stopAutoplay();
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

  void showHint() {
    clearHint();

    // Check for stock draw/recycle
    if (_game.getPile(PileType.stock) != null && _game.getPile(PileType.stock)!.isEmpty && _game.getPile(PileType.waste) != null && !_game.getPile(PileType.waste)!.isEmpty) {
        // Recycle suggestion - hint source and destination are both stock
        hintState.setHint(
          sourcePile: _game.getPile(PileType.stock)!,
          cards: null,
          destinationPile: _game.getPile(PileType.stock)!,
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
      if (_game.getPile(PileType.stock) != null && !_game.getPile(PileType.stock)!.isEmpty) {
        hintState.setHint(
          sourcePile: _game.getPile(PileType.stock)!,
          cards: null,
          destinationPile: _game.getPile(PileType.stock)!,
        );
        Future.delayed(const Duration(seconds: 2), () {
            if (hintState.sourcePile == _game.getPile(PileType.stock)) {
                clearHint();
            }
        });
      } else {
          // Absolutely no moves
          _eventController.add(const GameEvent(GameEventType.invalidMove));
      }
    }
  }
  
  @override
  void dispose() {
    _stopTimer();
    _stopInactivityTimer();
    _eventController.close();
    settingsProvider.removeListener(_onSettingsChanged);
    super.dispose();
  }
}
