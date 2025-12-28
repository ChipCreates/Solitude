import 'dart:async';
import 'package:flutter/foundation.dart';
import '../games/game_interface.dart';
import '../models/card.dart';
import '../models/pile.dart';
import '../models/game_event.dart';

/// Service for handling automated gameplay (autoplay and auto-complete)
class SolitaireBot {
  final GameInterface _game;
  final VoidCallback _onMoveExecuted;
  final VoidCallback _onGameWon;
  final VoidCallback _onGameLost;
  final void Function(GameEvent) _emitEvent;

  bool _isRunning = false;
  Timer? _autoplayTimer;

  SolitaireBot(
    this._game,
    this._onMoveExecuted,
    this._onGameWon,
    this._onGameLost,
    this._emitEvent,
  );

  bool get isRunning => _isRunning;

  void startAutoplay() {
    if (_isRunning) return;
    _isRunning = true;
    _runAutoplay();
  }

  void stopAutoplay() {
    _isRunning = false;
    _autoplayTimer?.cancel();
  }

  void startAutoComplete() {
    if (_isRunning) return;
    _isRunning = true;
    _runAutoComplete();
  }

  void stopAutoComplete() {
    _isRunning = false;
  }

  Future<void> _runAutoplay() async {
    final stockPile = _game.stockPile;
    final wastePile = _game.wastePile;

    // Track progress through the stock to detect when we've cycled without progress
    int recyclesSinceLastMove = 0;

    // Track recent moves to detect oscillation
    final List<String> recentMoveSignatures = [];
    const int maxRecentMoves = 10;

    while (_isRunning) {
      // Check for win
      if (_game.checkWin()) {
        _onGameWon();
        return;
      }

      // Check if truly lost
      if (_game.isLost) {
        _onGameLost();
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
            _onGameLost();
            return;
          }
          // Try drawing instead of repeating the move
          final move = _game.tapStock();
          _emitEvent(GameEvent(GameEventType.stockDrawn, move));
          if (move != null && move.flippedCard == true) {
            _emitEvent(const GameEvent(GameEventType.cardFlipped));
          }
          _onMoveExecuted();
          await Future.delayed(const Duration(milliseconds: 300));
          continue;
        }

        // Execute the move
        final move = _game.executeMove(hint.from, hint.to, hint.cards);
        _emitEvent(GameEvent(GameEventType.moveExecuted, move));
        if (move?.flippedCard == true) {
          _emitEvent(const GameEvent(GameEventType.cardFlipped));
        }

        // Track the move
        recentMoveSignatures.add(sig);
        if (recentMoveSignatures.length > maxRecentMoves) {
          recentMoveSignatures.removeAt(0);
        }

        // Reset counters since we made progress
        recyclesSinceLastMove = 0;

        _onMoveExecuted();
        await Future.delayed(const Duration(milliseconds: 400));

      } else {
        // No hint available - try drawing from stock
        final stockEmpty = stockPile == null || stockPile.isEmpty;
        final wasteEmpty = wastePile == null || wastePile.isEmpty;
        if (stockEmpty && wasteEmpty) {
          // Nothing to draw at all
          _onGameLost();
          return;
        }

        // Check if we've recycled twice without making any moves
        // This means we've gone through the entire deck twice with no progress
        if (recyclesSinceLastMove >= 2) {
          _onGameLost();
          return;
        }

        final move = _game.tapStock();
        _emitEvent(GameEvent(GameEventType.stockDrawn, move));
        if (move != null && move.flippedCard == true) {
          _emitEvent(const GameEvent(GameEventType.cardFlipped));
        }

        // If we just recycled (waste -> stock), track it
        if (move != null && move.toPile.type == PileType.stock) {
          recyclesSinceLastMove++;

          // After recycling, immediately check if we're truly lost
          if (_game.isLost) {
            _onGameLost();
            return;
          }
        }

        _onMoveExecuted();
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
    while (_isRunning && !_game.checkWin()) {
      if (_game.autoCompleteStep()) {
        _emitEvent(const GameEvent(GameEventType.moveExecuted));
        _onMoveExecuted();
        await Future.delayed(const Duration(milliseconds: 100));
      } else {
        break;
      }
    }

    if (_game.checkWin()) {
      _onGameWon();
    } else {
      _isRunning = false;
    }
  }
}