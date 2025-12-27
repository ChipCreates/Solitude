import 'package:flutter/material.dart';
import '../games/klondike/klondike_game.dart';

/// Difficulty levels for Klondike Solitaire
enum Difficulty {
  easy,
  medium,
  hard;

  String get displayName {
    switch (this) {
      case Difficulty.easy:
        return 'Easy';
      case Difficulty.medium:
        return 'Medium';
      case Difficulty.hard:
        return 'Hard';
    }
  }

  String get shortName {
    switch (this) {
      case Difficulty.easy:
        return 'EASY';
      case Difficulty.medium:
        return 'MED';
      case Difficulty.hard:
        return 'HARD';
    }
  }

  /// Draw mode for this difficulty
  DrawMode get drawMode {
    switch (this) {
      case Difficulty.easy:
        return DrawMode.one; // Draw 1 card
      case Difficulty.medium:
        return DrawMode.one; // Draw 1 card
      case Difficulty.hard:
        return DrawMode.three; // Draw 3 cards
    }
  }

  /// Maximum number of times the stock can be recycled (null = unlimited)
  int? get maxStockRecycles {
    switch (this) {
      case Difficulty.easy:
        return null; // Unlimited
      case Difficulty.medium:
        return null; // Unlimited
      case Difficulty.hard:
        return 2; // 3 passes total (initial + 2 recycles)
    }
  }

  /// Description of the difficulty rules
  String get description {
    switch (this) {
      case Difficulty.easy:
        return 'Draw 1 card • Unlimited passes';
      case Difficulty.medium:
        return 'Draw 1 card • Unlimited passes';
      case Difficulty.hard:
        return 'Draw 3 cards • 3 passes max';
    }
  }

  /// Full explanation of the difficulty
  String get fullDescription {
    switch (this) {
      case Difficulty.easy:
        return 'Relaxed gameplay with 1-card draw and unlimited deck recycling. Perfect for learning the game.';
      case Difficulty.medium:
        return 'Standard Klondike rules with 1-card draw. A good balance of challenge and flexibility.';
      case Difficulty.hard:
        return 'Challenge mode: 3-card draw and limited to 3 passes through the deck.';
    }
  }

  /// Color associated with this difficulty level
  Color get color {
    switch (this) {
      case Difficulty.easy:
        return Colors.green;
      case Difficulty.medium:
        return Colors.orange;
      case Difficulty.hard:
        return Colors.red;
    }
  }
}

/// Scoring mode for Klondike Solitaire
enum ScoringMode {
  standard,
  vegas;

  String get displayName {
    switch (this) {
      case ScoringMode.standard:
        return 'Standard';
      case ScoringMode.vegas:
        return 'Vegas';
    }
  }

  String get shortName {
    switch (this) {
      case ScoringMode.standard:
        return 'STD';
      case ScoringMode.vegas:
        return 'VEGAS';
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
    }
  }

  /// Full explanation
  String get fullDescription {
    switch (this) {
      case ScoringMode.standard:
        return 'Traditional scoring that tracks your best time and fewest moves. Perfect for improving your skills.';
      case ScoringMode.vegas:
        return 'Casino-style scoring where you pay \$52 to play and earn \$5 for each card moved to the foundations. Win money by getting more than 11 cards to the foundations!';
    }
  }
}
