import 'dart:async';
import 'dart:isolate';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../games/game_interface.dart';
import '../games/game_factory.dart';
import '../models/card.dart';
import '../models/pile.dart';
import '../models/move.dart';
import 'package:solitude/features/settings/models/difficulty.dart';
import 'package:solitude/core/models/game_event.dart';
import '../widgets/animated_card_overlay.dart';
import 'package:solitude/features/settings/services/settings_provider.dart';
import 'package:solitude/features/statistics/services/statistics_service.dart';
import 'animation_state_notifier.dart';
import 'hint_state_notifier.dart';
import 'selection_state_notifier.dart';
import 'timer_state_notifier.dart';
import 'board_layout_service.dart';
import 'solitaire_bot.dart';
import 'autocomplete_detector.dart';
import '../ai/solver_engine.dart';
import '../ai/games/klondike_solver_state.dart';
import 'package:solitude/features/settings/models/hint_mode.dart';
import 'audio_service.dart';

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

  // Audio service
  late final AudioService _audioService;

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

  // Cached winning path for smart hints
  List<KlondikeMove>? _cachedWinningPath;

  // Debounce timer for background solving
  Timer? _solveDebounceTimer;

  // Track if disposed
  bool _isDisposed = false;

  // Event stream for services
  final StreamController<GameEvent> _eventController =
      StreamController<GameEvent>.broadcast();
  Stream<GameEvent> get gameEvents => _eventController.stream;

  GameController({
    required this.settingsProvider,
    required this.statisticsService,
    required this.animationState,
    required this.hintState,
    required this.selectionState,
    required this.timerState,
    required this.boardLayout,
    required GameType gameType,
  }) {
    _game = GameFactory.createGame(gameType);
    _game.applyDifficulty(settingsProvider.difficulty);
    _game.initialize();
    // Initialize pile keys after game is set up
    initializePileKeys();
    _bot = SolitaireBot(
      _game,
      () {
        if (!_isDisposed) notifyListeners();
      },
      _handleWin,
      _handleLoss,
      (event) {
        if (!_isDisposed && !_eventController.isClosed) {
          _eventController.add(event);
        }
      },
    );
    _audioService = AudioService(settingsProvider);
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
  bool get canAutoFinish => AutoCompleteDetector.canAutoComplete(_game);
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

  /// Start a new game with the specified game type
  void startNewGame(GameType gameType) {
    if (_isDisposed) return;

    // Change the game type if different
    if (_game.runtimeType != GameFactory.createGame(gameType).runtimeType) {
      _game = GameFactory.createGame(gameType);

      // Reinitialize game-specific services
      _bot = SolitaireBot(
        _game,
        () {
          if (!_isDisposed) notifyListeners();
        },
        _handleWin,
        _handleLoss,
        (event) {
          if (!_isDisposed && !_eventController.isClosed) {
            _eventController.add(event);
          }
        },
      );

      // Reinitialize board layout
      initializePileKeys();
    }

    // Then proceed with normal new game logic
    newGame();
  }

  void newGame() {
    if (_isDisposed) return;
    _stopTimer();
    _stopInactivityTimer();
    timerState.reset();
    _gameStarted = false;

    // Update difficulty settings via game interface
    _game.applyDifficulty(settingsProvider.difficulty);

    // Configure game with current settings (Draw Mode, Vegas Mode, etc.)
    _game.configure(settingsProvider);

    _game.initialize();
    _state = GameState.playing;
    clearSelection();
    notifyListeners();
  }

  void _startTimer() {
    if (_isDisposed) return;
    timerState.start();
  }

  void _stopTimer() {
    timerState.stop();
  }

  void _recordGameStart() {
    if (_isDisposed) return;
    if (!_gameStarted) {
      _gameStarted = true;
      _startTimer();
      statisticsService.recordGameStarted();
      _resetInactivityTimer(); // Start inactivity timer when game begins
      if (!_eventController.isClosed) {
        _eventController.add(const GameEvent(GameEventType.gameStarted));
      }
    }
  }

  /// Reset the inactivity timer - call this on any user interaction
  void _resetInactivityTimer() {
    if (_isDisposed) return;
    _inactivityTimer?.cancel();
    _inactivityTimer = null;
    if (_state == GameState.playing && _gameStarted) {
      _inactivityTimer = Timer(_inactivityThreshold, _onInactivityTimeout);
    }
  }

  /// Called when player has been inactive - show a hint
  void _onInactivityTimeout() {
    if (_isDisposed) return;
    if (_state == GameState.playing &&
        !hintState.isActive &&
        !selectionState.hasSelection) {
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
    if (_isDisposed) return;
    // Update audio settings
    _audioService.updateSettings(settingsProvider);
    // If autoplay feature is disabled in settings, ensure we stop any running autoplay
    if (!settingsProvider.autoplay && _state == GameState.autoplaying) {
      stopAutoplay();
    }
  }

  void _emitMoveEvent(Move? move) {
    if (_isDisposed || _eventController.isClosed) return;
    if (move != null) {
      _eventController.add(GameEvent(GameEventType.moveExecuted, move));
      if (move.flippedCard == true) {
        _eventController.add(const GameEvent(GameEventType.cardFlipped));
      }
    }
  }

  void selectCard(Pile pile, PlayingCard card) {
    if (_isDisposed || _state != GameState.playing) return;

    // If same card selected, deselect
    if (selectionState.selectedPile == pile &&
        selectionState.selectedCards?.first == card) {
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
    if (_isDisposed) return;
    selectionState.clear();
    clearHint();
  }

  void clearHint() {
    if (_isDisposed) return;
    hintState.clear();
  }

  /// Cycle focus to the next pile with Tab key
  void cycleFocusForward() {
    if (_isDisposed || _state != GameState.playing) return;

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
    if (_isDisposed || _state != GameState.playing) return;

    final focusablePiles = _game.focusablePiles;
    if (focusablePiles.isEmpty) return;

    if (_focusedPile == null) {
      _focusedPile = focusablePiles.last;
    } else {
      final currentIndex = focusablePiles.indexOf(_focusedPile!);
      if (currentIndex >= 0) {
        final prevIndex =
            (currentIndex - 1 + focusablePiles.length) % focusablePiles.length;
        _focusedPile = focusablePiles[prevIndex];
      } else {
        _focusedPile = focusablePiles.last;
      }
    }

    notifyListeners();
  }

  /// Handle action on the currently focused pile (Enter/Space key)
  void activateFocusedPile() {
    if (_isDisposed || _state != GameState.playing || _focusedPile == null) {
      return;
    }

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
    Pile? fromPile,
    PlayingCard? animationCard,
  }) {
    if (_isDisposed) return;
    animationState.startCardAnimation(
      card: card,
      startPosition: startPosition,
      endPosition: endPosition,
      cardWidth: cardWidth,
      fromPile: fromPile,
      animationCard: animationCard,
    );
  }

  /// Animate drawing the top card from stock to waste with a mid-flight flip.
  /// For games without waste piles (like Spider), handle stock tap directly.
  Future<void> animateStockDraw(double cardWidth) async {
    if (_isDisposed || _state != GameState.playing) return;
    final stockPile = stock;
    if (stockPile == null) return;

    final wastePile = waste;
    if (wastePile == null) {
      // Game doesn't have a waste pile (e.g., Spider) - handle tap directly
      tapPile(stockPile);
      return;
    }

    // If stock is empty, handle recycling without animation
    if (stockPile.isEmpty) {
      tapPile(stockPile);
      return;
    }

    final startPosition = boardLayout.getCardPosition(stockPile);
    final endPosition = boardLayout.getCardPosition(wastePile);

    if (startPosition == null || endPosition == null) {
      final move = _game.handlePileTap(stockPile);
      _emitMoveEvent(move);
      clearSelection();
      _checkGameState();
      notifyListeners();
      return;
    }

    // 1. SPAWN FACE DOWN
    // Create a copy of the card forced to Face Down for the start of the flight
    final PlayingCard flyingCard = stockPile.topCard!.copyWith(faceUp: false);

    startCardAnimation(
      card: stockPile.topCard!, // original for hiding logic
      startPosition: startPosition,
      endPosition: endPosition,
      cardWidth: cardWidth,
      fromPile: stockPile,
      animationCard: flyingCard, // copy for display
    );

    // 2. TRIGGER FLIP (50ms Delay)
    // We wait a tiny bit, then tell the notifier to swap the card to "Face Up".
    // This change in state triggers the CardWidget's internal 3D flip animation.
    Future.delayed(const Duration(milliseconds: 50), () {
      if (!_isDisposed) {
        animationState.flipAnimatingCard();
      }
    });

    // 3. WAIT FOR COMPLETION
    // Wait for flight (300ms) + buffer for the flip to finish visually
    await Future.delayed(const Duration(milliseconds: 350));
    if (_isDisposed) return;

    // 4. UPDATE GAME STATE
    final move = _game.handlePileTap(stockPile);
    _emitMoveEvent(move);
    clearSelection();
    _checkGameState();

    // 5. CLEANUP
    clearCardAnimation();

    // Render the board with the real card now in the Waste pile
    notifyListeners();
  }

  void clearCardAnimation() {
    if (_isDisposed) return;
    animationState.clearCardAnimation();
  }

  bool isCardAnimating(PlayingCard card) {
    if (_isDisposed) return false;
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
    if (_isDisposed || _state != GameState.playing) return false;

    // Start animation
    startCardAnimation(
      card: card,
      startPosition: startPosition,
      endPosition: endPosition,
      cardWidth: cardWidth,
      fromPile: from,
    );

    // Wait for animation to complete
    await Future.delayed(const Duration(milliseconds: 400));
    if (_isDisposed) return false;

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
    if (_isDisposed) return false;
    return selectionState.isCardSelected(card);
  }

  bool isValidDestination(Pile pile) {
    if (_isDisposed) return false;
    final selectedPile = selectionState.selectedPile;
    final selectedCards = selectionState.selectedCards;
    if (selectedPile == null || selectedCards == null) return false;
    return _game.isValidMove(selectedPile, pile, selectedCards);
  }

  List<Pile> getValidDestinations() {
    if (_isDisposed) return [];
    final selectedPile = selectionState.selectedPile;
    final selectedCards = selectionState.selectedCards;
    if (selectedPile == null || selectedCards == null) return [];
    return _game.getValidDestinations(selectedPile, selectedCards);
  }

  void tapPile(Pile pile) {
    if (_isDisposed || _state != GameState.playing) return;
    _resetInactivityTimer();
    clearHint();

    // Handle game-specific pile tap
    final move = _game.handlePileTap(pile);
    if (move != null) {
      _recordGameStart();
      _emitMoveEvent(move);
      _triggerHaptic(); // Haptic feedback for drawing cards
      if (pile.type == PileType.stock) {
        _audioService.playSfx(SoundEffect.deal);
      }
      clearSelection();
      _checkGameState();
      notifyListeners();
      _invalidateCacheAndDebounceSolve();
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
        _triggerHaptic(); // Haptic feedback for card drops
        clearSelection();
        _checkGameState();
        notifyListeners();
        return;
      } else {
        if (!_eventController.isClosed) {
          _eventController.add(const GameEvent(GameEventType.invalidMove));
        }
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
    if (_isDisposed || _state != GameState.playing) return;
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
        _triggerHaptic(); // Haptic feedback for card drops
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
  Future<bool> doubleTapCardAnimated(
      Pile pile, PlayingCard card, double cardWidth, double stackOffset) async {
    if (_isDisposed || _state != GameState.playing) return false;
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
    final destinationPile =
        _game.findBestAutoMoveDestination(pile, cardsToMove);

    // If we found a destination, animate the move
    if (destinationPile != null) {
      final startPosition = getCardPosition(pile, stackOffset: stackOffset);
      // Calculate the final position where the card will rest after the move
      final baseEndPosition =
          getCardPosition(destinationPile, stackOffset: 0) ?? Offset.zero;
      Offset endPosition;
      if (destinationPile.type == PileType.tableau) {
        // For tableau piles, the card will be positioned at the end of the stack
        final finalStackIndex = destinationPile.length + cardsToMove.length - 1;
        endPosition = Offset(baseEndPosition.dx,
            baseEndPosition.dy + finalStackIndex * stackOffset);
      } else {
        // For foundation and other piles, cards are not stacked vertically
        endPosition = baseEndPosition;
      }

      // If start position is null, snap to destination without animation
      if (startPosition == null) {
        final move = _game.executeMove(pile, destinationPile, cardsToMove);
        _emitMoveEvent(move);
        clearSelection();
        _checkGameState();
        notifyListeners();
        return true;
      }

      // Trigger animation
      startCardAnimation(
        card: card,
        startPosition: startPosition,
        endPosition: endPosition,
        cardWidth: cardWidth,
        fromPile: pile,
      );

      // Wait for animation to complete
      await Future.delayed(const Duration(milliseconds: 300));
      if (_isDisposed) return false;

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
    if (_isDisposed || _state != GameState.playing) return false;
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
    final destinationPile =
        _game.findBestAutoMoveDestination(pile, cardsToMove);

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
    if (_isDisposed || _state != GameState.playing) return false;
    _resetInactivityTimer();
    clearHint();

    if (_game.isValidMove(from, to, cards)) {
      _recordGameStart();
      final move = _game.executeMove(from, to, cards);
      _emitMoveEvent(move);
      _audioService.playSfx(SoundEffect.cardFlip);
      clearSelection();
      _checkGameState();
      notifyListeners();
      _invalidateCacheAndDebounceSolve();
      return true;
    }

    _audioService.playSfx(SoundEffect.error);
    if (!_eventController.isClosed) {
      _eventController.add(const GameEvent(GameEventType.invalidMove));
    }
    return false;
  }

  void undo() {
    if (_isDisposed ||
        _state == GameState.autoCompleting ||
        _state == GameState.autoplaying) {
      return;
    }
    clearHint();

    if (_game.undo()) {
      if (!_eventController.isClosed) {
        _eventController.add(const GameEvent(GameEventType.undoUsed));
      }
      clearSelection();
      // If the game was marked lost, undoing may make it playable again
      if (_state == GameState.lost) {
        _state = GameState.playing;
        _startTimer(); // Resume timer
      }
      notifyListeners();
      _invalidateCacheAndDebounceSolve();
    }
  }

  void redo() {
    if (_isDisposed ||
        _state == GameState.autoCompleting ||
        _state == GameState.autoplaying) {
      return;
    }
    clearHint();

    if (_game.redo()) {
      clearSelection();
      // Check game state after redo
      _checkGameState();
      notifyListeners();
      _invalidateCacheAndDebounceSolve();
    }
  }

  /// Check game state after any move and update accordingly
  void _checkGameState() {
    if (_isDisposed) return;
    if (_game.checkWin()) {
      _handleWin();
    } else if (settingsProvider.autoComplete && _game.canAutoComplete()) {
      _startAutoComplete();
    } else if (_game.isLost) {
      _handleLoss();
    }

    // Notify listeners if auto-finish state has changed
    notifyListeners();
  }

  void _handleLoss() {
    if (_isDisposed) return;
    _stopTimer();
    _state = GameState.lost;
    statisticsService.recordLoss();
    if (!_eventController.isClosed) {
      _eventController.add(const GameEvent(GameEventType.gameLost));
    }

    // Record Vegas scoring if in Vegas mode
    if (settingsProvider.scoringMode == ScoringMode.vegas) {
      // Count cards in foundations
      int cardsInFoundations = 0;
      for (final foundation in _game.foundationPiles) {
        cardsInFoundations += foundation.length;
      }
      // Calculate Vegas score: -52 to start + $5 per card
      final vegasScore = ScoringMode.vegas.vegasGameCost +
          (cardsInFoundations * ScoringMode.vegas.vegasCardValue);
      statisticsService.recordVegasScore(vegasScore);
    }

    notifyListeners();
  }

  void _handleWin() {
    if (_isDisposed) return;
    _stopTimer();
    _state = GameState.won;
    _audioService.playSfx(SoundEffect.win);
    statisticsService.recordWin(
        time: timerState.elapsed, moves: _game.moveCount);
    if (!_eventController.isClosed) {
      _eventController.add(const GameEvent(GameEventType.gameWon));
    }

    // Record Vegas scoring if in Vegas mode (winning = all 52 cards in foundations)
    if (settingsProvider.scoringMode == ScoringMode.vegas) {
      // Vegas win score: -52 + (52 * 5) = 208
      final vegasScore = ScoringMode.vegas.vegasGameCost +
          (52 * ScoringMode.vegas.vegasCardValue);
      statisticsService.recordVegasScore(vegasScore);
    }

    notifyListeners();
  }

  void _startAutoComplete() {
    if (_isDisposed) return;
    _state = GameState.autoCompleting;
    if (!_eventController.isClosed) {
      _eventController
          .add(const GameEvent(GameEventType.autoCompleteTriggered));
    }
    notifyListeners();

    _bot.startAutoComplete();
  }

  // Autoplay controls
  bool get isAutoplaying => _state == GameState.autoplaying;

  void toggleAutoplay() {
    if (_isDisposed) return;
    if (_state == GameState.autoplaying) {
      stopAutoplay();
    } else if (settingsProvider.autoplay) {
      startAutoplay();
    }
  }

  void startAutoplay() {
    if (_isDisposed || _state == GameState.autoplaying) return;
    _state = GameState.autoplaying;
    notifyListeners();
    _bot.startAutoplay();
  }

  void stopAutoplay() {
    if (_isDisposed || _state != GameState.autoplaying) return;
    _bot.stopAutoplay();
    _state = GameState.playing;
    _checkGameState(); // Check if lost after stopping
    notifyListeners();
  }

  void clearLoss() {
    if (_isDisposed || _state == GameState.lost) {
      _state = GameState.playing;
      _startTimer(); // Resume timer so player can continue trying
      notifyListeners();
    }
  }

  void showHint() {
    if (_isDisposed) return;
    clearHint();

    // Check hint mode setting
    switch (settingsProvider.hintMode) {
      case HintMode.off:
        // Do nothing
        return;
      case HintMode.fast:
        // Use greedy heuristic
        _showFastHint();
        return;
      case HintMode.smart:
        // Use AI solver (existing logic)
        break;
    }

    // Check smart hint from solver cache
    if (_cachedWinningPath != null && _cachedWinningPath!.isNotEmpty) {
      final firstMove = _cachedWinningPath!.first;
      Pile? sourcePile, destinationPile;
      List<PlayingCard>? cards;

      switch (firstMove.type) {
        case KlondikeMoveType.tableauToTableau:
          sourcePile = _game.tableauPiles[firstMove.fromPile];
          destinationPile = _game.tableauPiles[firstMove.toPile];
          cards = !sourcePile.isEmpty ? [sourcePile.topCard!] : null;
          break;
        case KlondikeMoveType.tableauToFoundation:
          sourcePile = _game.tableauPiles[firstMove.fromPile];
          destinationPile = _game.foundationPiles[firstMove.toPile];
          cards = !sourcePile.isEmpty ? [sourcePile.topCard!] : null;
          break;
        case KlondikeMoveType.wasteToTableau:
          sourcePile = _game.wastePile;
          destinationPile = _game.tableauPiles[firstMove.toPile];
          cards = sourcePile != null && !sourcePile.isEmpty
              ? [sourcePile.topCard!]
              : null;
          break;
        case KlondikeMoveType.wasteToFoundation:
          sourcePile = _game.wastePile;
          destinationPile = _game.foundationPiles[firstMove.toPile];
          cards = sourcePile != null && !sourcePile.isEmpty
              ? [sourcePile.topCard!]
              : null;
          break;
        case KlondikeMoveType.drawCard:
          sourcePile = _game.stockPile;
          destinationPile = _game.stockPile;
          cards = null;
          break;
        case KlondikeMoveType.flipTableauCard:
          // Skip flip hints
          break;
      }

      if (sourcePile != null && destinationPile != null) {
        hintState.setHint(
          sourcePile: sourcePile,
          cards: cards,
          destinationPile: destinationPile,
        );
        if (!_eventController.isClosed) {
          _eventController.add(const GameEvent(GameEventType.hintUsed));
        }

        // Auto-clear hint after delay
        Future.delayed(const Duration(seconds: 2), () {
          if (!_isDisposed &&
              hintState.sourcePile == sourcePile &&
              hintState.destinationPile == destinationPile) {
            clearHint();
          }
        });
        return;
      }
    }

    // If smart hint cache is empty, fallback to fast hints
    _showFastHint();
  }

  /// Triggers haptic feedback if enabled
  void _triggerHaptic() {
    if (settingsProvider.vibrationEnabled) {
      HapticFeedback.selectionClick();
    }
  }

  /// Shows fast hint using greedy heuristic
  void _showFastHint() {
    // Fallback to traditional hints (greedy heuristic)
    // Check for stock draw/recycle
    if (_game.getPile(PileType.stock) != null &&
        _game.getPile(PileType.stock)!.isEmpty &&
        _game.getPile(PileType.waste) != null &&
        !_game.getPile(PileType.waste)!.isEmpty) {
      // Recycle suggestion - hint source and destination are both stock
      hintState.setHint(
        sourcePile: _game.getPile(PileType.stock)!,
        cards: null,
        destinationPile: _game.getPile(PileType.stock)!,
      );
      if (!_eventController.isClosed) {
        _eventController.add(const GameEvent(GameEventType.hintUsed));
      }
      return;
    }

    final hint = _game.getHint();
    if (hint != null) {
      hintState.setHint(
        sourcePile: hint.from,
        cards: hint.cards,
        destinationPile: hint.to,
      );
      if (!_eventController.isClosed) {
        _eventController.add(const GameEvent(GameEventType.hintUsed));
      }

      // Auto-clear hint after delay
      Future.delayed(const Duration(seconds: 2), () {
        if (!_isDisposed &&
            hintState.sourcePile == hint.from &&
            hintState.destinationPile == hint.to) {
          clearHint();
        }
      });
    } else {
      // No moves available, try suggesting drawing from stock
      if (_game.getPile(PileType.stock) != null &&
          !_game.getPile(PileType.stock)!.isEmpty) {
        hintState.setHint(
          sourcePile: _game.getPile(PileType.stock)!,
          cards: null,
          destinationPile: _game.getPile(PileType.stock)!,
        );
        Future.delayed(const Duration(seconds: 2), () {
          if (!_isDisposed &&
              hintState.sourcePile == _game.getPile(PileType.stock)) {
            clearHint();
          }
        });
      } else {
        // Absolutely no moves
        if (!_eventController.isClosed) {
          _eventController.add(const GameEvent(GameEventType.invalidMove));
        }
      }
    }
  }

  /// Solves the current game using the AI solver in a background isolate.
  /// Returns null if the game doesn't support solving (e.g., Spider).
  Future<List<KlondikeMove>?> solveGame() async {
    if (_isDisposed) return null;

    // Get solver state from the game interface
    final solverState = _game.getSolverState();

    // If the game doesn't support solving, return null
    if (solverState == null) return null;

    // Currently only KlondikeSolverState is supported
    if (solverState is! KlondikeSolverState) return null;

    // Run the solver in a background isolate
    return await Isolate.run(() async {
      final engine = SolverEngine();
      return await engine.solve(solverState);
    });
  }

  /// Executes a single solver move using existing game logic.
  Future<void> executeSolverMove(KlondikeMove move) async {
    if (_isDisposed || _state != GameState.playing) return;

    try {
      switch (move.type) {
        case KlondikeMoveType.tableauToTableau:
          final fromPile = _game.tableauPiles[move.fromPile];
          final toPile = _game.tableauPiles[move.toPile];
          if (fromPile.isEmpty) throw Exception('Source tableau pile is empty');
          final card = fromPile.topCard!;
          tryMove(fromPile, toPile, [card]);
          break;

        case KlondikeMoveType.tableauToFoundation:
          final fromPile = _game.tableauPiles[move.fromPile];
          final toPile = _game.foundationPiles[move.toPile];
          if (fromPile.isEmpty) throw Exception('Source tableau pile is empty');
          final card = fromPile.topCard!;
          tryMove(fromPile, toPile, [card]);
          break;

        case KlondikeMoveType.wasteToTableau:
          final fromPile = _game.wastePile!;
          final toPile = _game.tableauPiles[move.toPile];
          if (fromPile.isEmpty) throw Exception('Waste pile is empty');
          final card = fromPile.topCard!;
          tryMove(fromPile, toPile, [card]);
          break;

        case KlondikeMoveType.wasteToFoundation:
          final fromPile = _game.wastePile!;
          final toPile = _game.foundationPiles[move.toPile];
          if (fromPile.isEmpty) throw Exception('Waste pile is empty');
          final card = fromPile.topCard!;
          tryMove(fromPile, toPile, [card]);
          break;

        case KlondikeMoveType.drawCard:
          if (_game.stockPile != null && !_game.stockPile!.isEmpty) {
            tapPile(_game.stockPile!);
          }
          break;

        case KlondikeMoveType.flipTableauCard:
          // Face-down tracking not implemented, skip
          break;
      }
    } catch (e) {
      // Gracefully handle execution errors (sync issues)
      debugPrint('Solver move execution failed: $e');
    }
  }

  /// Auto-plays a sequence of solver moves with visual pacing.
  Future<void> autoPlaySolution(List<KlondikeMove> moves) async {
    if (_isDisposed) return;

    for (var move in moves) {
      await Future.delayed(const Duration(milliseconds: 200));
      if (_isDisposed || _state != GameState.playing) break;
      await executeSolverMove(move);
    }
  }

  /// Solves and auto-plays the current game (debug/power user tool).
  Future<void> solveAndAutoPlay() async {
    if (_isDisposed) return;
    final path = await solveGame();
    if (path != null && !_isDisposed) {
      await autoPlaySolution(path);
    }
  }

  /// Invalidates cache and starts debounce timer for background solving.
  void _invalidateCacheAndDebounceSolve() {
    _cachedWinningPath = null;
    _solveDebounceTimer?.cancel();
    // Check settings.hintMode: if smart, proceed with debounce; if fast or off, do not run solver
    // Also check if the game supports solving
    if (settingsProvider.hintMode == HintMode.smart &&
        _game.getSolverState() != null) {
      _solveDebounceTimer =
          Timer(const Duration(milliseconds: 500), _backgroundSolve);
    }
  }

  /// Background solver execution.
  void _backgroundSolve() async {
    if (_isDisposed) return;
    final path = await solveGame();
    if (!_isDisposed) {
      _cachedWinningPath = path;
    }
  }

  /// Triggers the auto-finish mode for the game.
  /// This should be called when the player presses the "Auto Finish" button.
  void autoFinishGame() {
    if (_isDisposed || !canAutoFinish) return;

    // Emit the event for achievements and other listeners
    if (!_eventController.isClosed) {
      _eventController
          .add(const GameEvent(GameEventType.autoCompleteTriggered));
    }
  }

  @override
  void notifyListeners() {
    if (!_isDisposed) {
      super.notifyListeners();
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    _stopTimer();
    _stopInactivityTimer();
    _bot.stopAutoplay();
    _bot.stopAutoComplete();
    _solveDebounceTimer?.cancel();
    _eventController.close();
    _audioService.dispose();
    settingsProvider.removeListener(_onSettingsChanged);
    super.dispose();
  }
}
