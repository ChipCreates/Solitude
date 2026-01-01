import 'dart:convert';
import 'package:hive/hive.dart';
import 'package:flutter/foundation.dart';
import '../games/game_interface.dart';
import '../games/game_factory.dart';
import '../models/card.dart';
import '../models/pile.dart';

/// Serializable representation of a playing card
class SerializedCard {
  final String suit;
  final String rank;
  final bool faceUp;
  final String uniqueId;

  SerializedCard({
    required this.suit,
    required this.rank,
    required this.faceUp,
    required this.uniqueId,
  });

  Map<String, dynamic> toJson() => {
        'suit': suit,
        'rank': rank,
        'faceUp': faceUp,
        'uniqueId': uniqueId,
      };

  factory SerializedCard.fromJson(Map<String, dynamic> json) => SerializedCard(
        suit: json['suit'] as String,
        rank: json['rank'] as String,
        faceUp: json['faceUp'] as bool,
        uniqueId: json['uniqueId'] as String,
      );

  factory SerializedCard.fromCard(PlayingCard card) => SerializedCard(
        suit: card.suit.name,
        rank: card.rank.name,
        faceUp: card.faceUp,
        uniqueId: card.uniqueId,
      );

  PlayingCard toCard() => PlayingCard(
        suit: Suit.values.firstWhere((s) => s.name == suit),
        rank: Rank.values.firstWhere((r) => r.name == rank),
        faceUp: faceUp,
        uniqueId: uniqueId,
      );
}

/// Serializable representation of a pile
class SerializedPile {
  final String type;
  final int index;
  final List<SerializedCard> cards;

  SerializedPile({
    required this.type,
    required this.index,
    required this.cards,
  });

  Map<String, dynamic> toJson() => {
        'type': type,
        'index': index,
        'cards': cards.map((c) => c.toJson()).toList(),
      };

  factory SerializedPile.fromJson(Map<String, dynamic> json) => SerializedPile(
        type: json['type'] as String,
        index: json['index'] as int,
        cards: (json['cards'] as List)
            .map((c) => SerializedCard.fromJson(c as Map<String, dynamic>))
            .toList(),
      );

  factory SerializedPile.fromPile(Pile pile) => SerializedPile(
        type: pile.type.name,
        index: pile.index,
        cards: pile.cards.map((c) => SerializedCard.fromCard(c)).toList(),
      );
}

/// Complete game state that can be saved/restored
class SavedGameState {
  final String gameType;
  final List<SerializedPile> piles;
  final int moveCount;
  final Duration elapsedTime;
  final DateTime savedAt;
  final Map<String, dynamic> gameSpecificData;

  SavedGameState({
    required this.gameType,
    required this.piles,
    required this.moveCount,
    required this.elapsedTime,
    required this.savedAt,
    this.gameSpecificData = const {},
  });

  Map<String, dynamic> toJson() => {
        'gameType': gameType,
        'piles': piles.map((p) => p.toJson()).toList(),
        'moveCount': moveCount,
        'elapsedTimeMs': elapsedTime.inMilliseconds,
        'savedAt': savedAt.toIso8601String(),
        'gameSpecificData': gameSpecificData,
      };

  factory SavedGameState.fromJson(Map<String, dynamic> json) => SavedGameState(
        gameType: json['gameType'] as String,
        piles: (json['piles'] as List)
            .map((p) => SerializedPile.fromJson(p as Map<String, dynamic>))
            .toList(),
        moveCount: json['moveCount'] as int,
        elapsedTime: Duration(milliseconds: json['elapsedTimeMs'] as int),
        savedAt: DateTime.parse(json['savedAt'] as String),
        gameSpecificData:
            (json['gameSpecificData'] as Map<String, dynamic>?) ?? {},
      );

  String toJsonString() => jsonEncode(toJson());

  factory SavedGameState.fromJsonString(String jsonString) =>
      SavedGameState.fromJson(jsonDecode(jsonString) as Map<String, dynamic>);
}

/// Repository for saving and loading game state
class GameStateRepository {
  static const String _boxName = 'game_state';
  static const String _currentGameKey = 'current_game';

  Box? _box;

  /// Initialize the repository (call once at app startup)
  Future<void> initialize() async {
    if (_box != null && _box!.isOpen) return;

    try {
      _box = await Hive.openBox(_boxName);
    } catch (e) {
      debugPrint('GameStateRepository: Failed to open Hive box: $e');
      rethrow;
    }
  }

  /// Check if there is a saved game
  Future<bool> hasSavedGame() async {
    await _ensureInitialized();
    return _box!.containsKey(_currentGameKey);
  }

  /// Get the saved game type (without loading full state)
  Future<GameType?> getSavedGameType() async {
    await _ensureInitialized();
    final jsonString = _box!.get(_currentGameKey) as String?;
    if (jsonString == null) return null;

    try {
      final json = jsonDecode(jsonString) as Map<String, dynamic>;
      final gameTypeStr = json['gameType'] as String;
      return GameType.values.firstWhere(
        (t) => t.name == gameTypeStr,
        orElse: () => GameType.klondike,
      );
    } catch (e) {
      debugPrint('GameStateRepository: Failed to parse saved game type: $e');
      return null;
    }
  }

  /// Save the current game state
  Future<void> saveGame({
    required GameInterface game,
    required Duration elapsedTime,
  }) async {
    await _ensureInitialized();

    final piles = game.allPiles.map((p) => SerializedPile.fromPile(p)).toList();

    // Extract game-specific data
    final gameSpecificData = _extractGameSpecificData(game);

    final state = SavedGameState(
      gameType: game.gameType.name,
      piles: piles,
      moveCount: game.moveCount,
      elapsedTime: elapsedTime,
      savedAt: DateTime.now(),
      gameSpecificData: gameSpecificData,
    );

    await _box!.put(_currentGameKey, state.toJsonString());
    debugPrint('GameStateRepository: Game saved (${game.gameType.name})');
  }

  /// Load the saved game state
  Future<SavedGameState?> loadGame() async {
    await _ensureInitialized();
    final jsonString = _box!.get(_currentGameKey) as String?;
    if (jsonString == null) return null;

    try {
      return SavedGameState.fromJsonString(jsonString);
    } catch (e) {
      debugPrint('GameStateRepository: Failed to load game: $e');
      await clearSavedGame();
      return null;
    }
  }

  /// Clear the saved game
  Future<void> clearSavedGame() async {
    await _ensureInitialized();
    await _box!.delete(_currentGameKey);
    debugPrint('GameStateRepository: Saved game cleared');
  }

  /// Restore game state from saved data
  GameInterface? restoreGame(SavedGameState state) {
    try {
      final gameType = GameType.values.firstWhere(
        (t) => t.name == state.gameType,
        orElse: () => GameType.klondike,
      );

      final game = GameFactory.createGame(gameType);

      // Initialize the game to create pile structures
      game.initialize();

      // Restore pile contents
      _restorePiles(game, state.piles);

      // Restore game-specific data
      _restoreGameSpecificData(game, state.gameSpecificData);

      debugPrint(
          'GameStateRepository: Game restored (${gameType.name}, ${state.moveCount} moves)');
      return game;
    } catch (e) {
      debugPrint('GameStateRepository: Failed to restore game: $e');
      return null;
    }
  }

  Future<void> _ensureInitialized() async {
    if (_box == null || !_box!.isOpen) {
      await initialize();
    }
  }

  /// Extract game-specific data for serialization
  Map<String, dynamic> _extractGameSpecificData(GameInterface game) {
    final data = <String, dynamic>{};

    // Handle Klondike-specific data
    if (game.gameType == GameType.klondike) {
      // Use reflection-free approach - check for known properties
      try {
        final dynamic dynamicGame = game;
        if (dynamicGame.stockRecycleCount != null) {
          data['stockRecycleCount'] = dynamicGame.stockRecycleCount;
        }
        if (dynamicGame.drawMode != null) {
          data['drawMode'] = dynamicGame.drawMode.index;
        }
        if (dynamicGame.maxStockRecycles != null) {
          data['maxStockRecycles'] = dynamicGame.maxStockRecycles;
        }
      } catch (_) {
        // Not a Klondike game or doesn't have these properties
      }
    }

    // Handle Spider-specific data
    if (game.gameType == GameType.spider) {
      try {
        final dynamic dynamicGame = game;
        if (dynamicGame.numberOfSuits != null) {
          data['numberOfSuits'] = dynamicGame.numberOfSuits;
        }
      } catch (_) {}
    }

    return data;
  }

  /// Restore game-specific data after loading
  void _restoreGameSpecificData(
      GameInterface game, Map<String, dynamic> data) {
    if (data.isEmpty) return;

    // Handle Spider-specific data
    if (game.gameType == GameType.spider && data.containsKey('numberOfSuits')) {
      try {
        final dynamic dynamicGame = game;
        dynamicGame.numberOfSuits = data['numberOfSuits'] as int;
      } catch (_) {}
    }
  }

  /// Restore pile contents from serialized data
  void _restorePiles(GameInterface game, List<SerializedPile> serializedPiles) {
    // Create a map of pile ID to serialized pile for quick lookup
    final pileDataMap = <String, SerializedPile>{};
    for (final sp in serializedPiles) {
      final id = '${sp.type}_${sp.index}';
      pileDataMap[id] = sp;
    }

    // Restore each pile in the game
    for (final pile in game.allPiles) {
      final serialized = pileDataMap[pile.id];
      if (serialized != null) {
        // Clear existing cards
        pile.removeAll();

        // Add cards from saved state
        for (final sc in serialized.cards) {
          pile.addCard(sc.toCard());
        }
      }
    }
  }

  /// Dispose of resources
  Future<void> dispose() async {
    await _box?.close();
    _box = null;
  }
}
