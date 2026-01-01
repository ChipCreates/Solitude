import 'package:flutter/material.dart';
import 'package:solitude/features/game/models/draw_mode.dart';
import 'package:solitude/features/game/games/game_factory.dart';

/// Base difficulty levels (game-agnostic)
enum DifficultyLevel {
  easy,
  medium,
  hard;

  String get displayName {
    switch (this) {
      case DifficultyLevel.easy:
        return 'Easy';
      case DifficultyLevel.medium:
        return 'Medium';
      case DifficultyLevel.hard:
        return 'Hard';
    }
  }

  String get shortName {
    switch (this) {
      case DifficultyLevel.easy:
        return 'EASY';
      case DifficultyLevel.medium:
        return 'MED';
      case DifficultyLevel.hard:
        return 'HARD';
    }
  }

  Color get color {
    switch (this) {
      case DifficultyLevel.easy:
        return Colors.green;
      case DifficultyLevel.medium:
        return Colors.orange;
      case DifficultyLevel.hard:
        return Colors.red;
    }
  }

  /// Get the description for a specific game type
  String descriptionFor(GameType gameType) {
    switch (gameType) {
      case GameType.klondike:
        return _klondikeDescription;
      case GameType.spider:
        return _spiderDescription;
      // Future games - use generic description until implemented
      case GameType.pyramid:
      case GameType.golf:
      case GameType.freecell:
      case GameType.triPeaks:
      case GameType.yukon:
      case GameType.fortyThieves:
      case GameType.canfield:
      case GameType.scorpion:
        return displayName;
    }
  }

  String get _klondikeDescription {
    switch (this) {
      case DifficultyLevel.easy:
        return 'Draw 1 card • Unlimited passes';
      case DifficultyLevel.medium:
        return 'Draw 1 card • Unlimited passes';
      case DifficultyLevel.hard:
        return 'Draw 3 cards • 3 passes max';
    }
  }

  String get _spiderDescription {
    switch (this) {
      case DifficultyLevel.easy:
        return '1 suit • Easy to learn';
      case DifficultyLevel.medium:
        return '2 suits • Moderate challenge';
      case DifficultyLevel.hard:
        return '4 suits • Expert level';
    }
  }

  /// Get full description for a specific game type
  String fullDescriptionFor(GameType gameType) {
    switch (gameType) {
      case GameType.klondike:
        return _klondikeFullDescription;
      case GameType.spider:
        return _spiderFullDescription;
      // Future games - use display name until implemented
      case GameType.pyramid:
      case GameType.golf:
      case GameType.freecell:
      case GameType.triPeaks:
      case GameType.yukon:
      case GameType.fortyThieves:
      case GameType.canfield:
      case GameType.scorpion:
        return '$displayName difficulty for ${gameType.name}';
    }
  }

  String get _klondikeFullDescription {
    switch (this) {
      case DifficultyLevel.easy:
        return 'Relaxed gameplay with 1-card draw and unlimited deck recycling. Perfect for learning the game.';
      case DifficultyLevel.medium:
        return 'Standard Klondike rules with 1-card draw. A good balance of challenge and flexibility.';
      case DifficultyLevel.hard:
        return 'Challenge mode: 3-card draw and limited to 3 passes through the deck.';
    }
  }

  String get _spiderFullDescription {
    switch (this) {
      case DifficultyLevel.easy:
        return 'Single suit Spider solitaire. Build sequences and move them to foundations. Great for beginners.';
      case DifficultyLevel.medium:
        return 'Two suit Spider solitaire. Increased challenge with mixed suits requiring careful planning.';
      case DifficultyLevel.hard:
        return 'Four suit Spider solitaire. The ultimate challenge requiring strategic mastery of sequence building.';
    }
  }
}

/// Klondike-specific difficulty configuration
class KlondikeDifficulty {
  final DrawMode drawMode;
  final int? maxStockRecycles;

  const KlondikeDifficulty({
    required this.drawMode,
    this.maxStockRecycles,
  });

  /// Create from a difficulty level
  factory KlondikeDifficulty.fromLevel(DifficultyLevel level) {
    switch (level) {
      case DifficultyLevel.easy:
        return const KlondikeDifficulty(
          drawMode: DrawMode.one,
          maxStockRecycles: null, // Unlimited
        );
      case DifficultyLevel.medium:
        return const KlondikeDifficulty(
          drawMode: DrawMode.one,
          maxStockRecycles: null, // Unlimited
        );
      case DifficultyLevel.hard:
        return const KlondikeDifficulty(
          drawMode: DrawMode.three,
          maxStockRecycles: 2, // 3 passes total
        );
    }
  }
}

/// Legacy typedef for backward compatibility
typedef Difficulty = DifficultyLevel;

/// Extension to provide Klondike-specific getters on DifficultyLevel
/// for backward compatibility during migration
extension KlondikeDifficultyExtension on DifficultyLevel {
  /// Draw mode for Klondike
  DrawMode get drawMode => KlondikeDifficulty.fromLevel(this).drawMode;

  /// Maximum stock recycles for Klondike
  int? get maxStockRecycles =>
      KlondikeDifficulty.fromLevel(this).maxStockRecycles;

  /// Description (defaults to Klondike for backward compatibility)
  String get description => descriptionFor(GameType.klondike);

  /// Full description (defaults to Klondike for backward compatibility)
  String get fullDescription => fullDescriptionFor(GameType.klondike);
}

/// Scoring mode for Klondike Solitaire
enum ScoringMode {
  standard,
  vegas,
  vegasCumulative;

  String get displayName {
    switch (this) {
      case ScoringMode.standard:
        return 'Standard';
      case ScoringMode.vegas:
        return 'Vegas';
      case ScoringMode.vegasCumulative:
        return 'Vegas Cumulative';
    }
  }

  String get shortName {
    switch (this) {
      case ScoringMode.standard:
        return 'STD';
      case ScoringMode.vegas:
        return 'VEGAS';
      case ScoringMode.vegasCumulative:
        return 'VEGAS+';
    }
  }

  /// Vegas scoring: cost to start a game
  int get vegasGameCost => -52; // $52 to buy the deck

  /// Vegas scoring: payout per card to foundation
  int get vegasCardValue => 5; // $5 per card

  /// Description of scoring mode
  String get description {
    switch (this) {
      case ScoringMode.standard:
        return 'Track time and moves';
      case ScoringMode.vegas:
        return 'Pay \$52, earn \$5 per card';
      case ScoringMode.vegasCumulative:
        return 'Bankroll across games';
    }
  }

  /// Full explanation
  String get fullDescription {
    switch (this) {
      case ScoringMode.standard:
        return 'Traditional scoring that tracks your best time and fewest moves. Perfect for improving your skills.';
      case ScoringMode.vegas:
        return 'Casino-style scoring where you pay \$52 to play and earn \$5 for each card moved to the foundations. Win money by getting more than 11 cards to the foundations!';
      case ScoringMode.vegasCumulative:
        return 'Vegas scoring with a persistent bankroll that carries across games. Start with \$0 and build your casino fortune over multiple games!';
    }
  }
}
