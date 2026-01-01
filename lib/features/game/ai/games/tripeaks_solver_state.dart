import 'dart:convert';

import '../abstract_solver.dart';

/// Represents a card in the TriPeaks solver.
/// Format: 'rankSuit' where rank 1-13 (1=Ace, 13=King), suit H/D/C/S.
class TriPeaksCard {
  final String value;

  TriPeaksCard(this.value);

  int get rank => int.parse(value.substring(0, value.length - 1));

  String get suit => value.substring(value.length - 1);

  @override
  String toString() => value;

  /// Check if this card can be played to waste (+/- 1 rank with wrapping)
  bool canPlayOn(TriPeaksCard wasteTop) {
    final diff = (rank - wasteTop.rank).abs();
    return diff == 1 || diff == 12; // 12 handles K-A wrapping
  }
}

/// Enum for different move types in TriPeaks.
enum TriPeaksMoveType {
  peakToWaste,
  drawFromStock,
}

/// Represents a move in TriPeaks solitaire.
class TriPeaksMove extends SolverMove {
  final TriPeaksMoveType type;
  final int peakIndex; // Which peak pile (-1 for stock draw)

  TriPeaksMove(this.type, this.peakIndex);

  @override
  int get priority => _calculatePriority();

  int _calculatePriority() {
    switch (type) {
      case TriPeaksMoveType.peakToWaste:
        return 5; // Prefer playing cards
      case TriPeaksMoveType.drawFromStock:
        return 2; // Draw when needed
    }
  }

  @override
  String toString() => '$type idx:$peakIndex';
}

/// Lightweight state representation for TriPeaks solver.
class TriPeaksSolverState implements SolverState<TriPeaksMove> {
  /// 28 peak positions (null = empty, String = card)
  final List<String?> peaks;
  final List<String> stock;
  final String? wasteTop;

  /// Peak structure: which positions each position covers
  static const List<List<int>> peakCovers = [
    // Row 0: Peak tops
    [3, 4], // 0 covers 3, 4
    [5, 6], // 1 covers 5, 6
    [7, 8], // 2 covers 7, 8
    // Row 1
    [9, 10], // 3 covers 9, 10
    [10, 11], // 4 covers 10, 11
    [12, 13], // 5 covers 12, 13
    [13, 14], // 6 covers 13, 14
    [15, 16], // 7 covers 15, 16
    [16, 17], // 8 covers 16, 17
    // Row 2
    [18, 19], // 9 covers 18, 19
    [19, 20], // 10 covers 19, 20
    [20, 21], // 11 covers 20, 21
    [21, 22], // 12 covers 21, 22
    [22, 23], // 13 covers 22, 23
    [23, 24], // 14 covers 23, 24
    [24, 25], // 15 covers 24, 25
    [25, 26], // 16 covers 25, 26
    [26, 27], // 17 covers 26, 27
    // Row 3 (bottom) - covers nothing
    [], [], [], [], [], [], [], [], [], []
  ];

  TriPeaksSolverState({
    required this.peaks,
    required this.stock,
    required this.wasteTop,
  });

  /// Creates a copy with modified fields.
  TriPeaksSolverState copyWith({
    List<String?>? peaks,
    List<String>? stock,
    String? wasteTop,
  }) {
    return TriPeaksSolverState(
      peaks: peaks ?? List.from(this.peaks),
      stock: stock ?? List.from(this.stock),
      wasteTop: wasteTop ?? this.wasteTop,
    );
  }

  /// Check if a peak position is uncovered
  bool isUncovered(int index) {
    if (index < 0 || index >= 28) return false;
    if (peaks[index] == null) return false;

    // Card is uncovered if all cards it covers are empty
    for (final coveredIndex in peakCovers[index]) {
      if (peaks[coveredIndex] != null) {
        return false;
      }
    }
    return true;
  }

  @override
  List<TriPeaksMove> getAvailableMoves() {
    final moves = <TriPeaksMove>[];

    // Peak to waste moves
    if (wasteTop != null) {
      final wasteCard = TriPeaksCard(wasteTop!);

      for (int i = 0; i < 28; i++) {
        if (!isUncovered(i)) continue;
        final peakCard = TriPeaksCard(peaks[i]!);
        if (peakCard.canPlayOn(wasteCard)) {
          moves.add(TriPeaksMove(TriPeaksMoveType.peakToWaste, i));
        }
      }
    }

    // Draw from stock
    if (stock.isNotEmpty) {
      moves.add(TriPeaksMove(TriPeaksMoveType.drawFromStock, -1));
    }

    return moves;
  }

  @override
  SolverState<TriPeaksMove> applyMove(TriPeaksMove move) {
    switch (move.type) {
      case TriPeaksMoveType.peakToWaste:
        final newPeaks = List<String?>.from(peaks);
        final card = newPeaks[move.peakIndex];
        newPeaks[move.peakIndex] = null;
        return copyWith(peaks: newPeaks, wasteTop: card);

      case TriPeaksMoveType.drawFromStock:
        final newStock = List<String>.from(stock);
        final card = newStock.removeLast();
        return copyWith(stock: newStock, wasteTop: card);
    }
  }

  @override
  bool get isWon => peaks.every((p) => p == null);

  @override
  String get signature {
    return jsonEncode({
      'peaks': peaks,
      'stock': stock.length,
      'waste': wasteTop,
    });
  }

  @override
  int get heuristicScore {
    if (isWon) return 1000;

    int score = 0;

    // Count cards cleared (28 - remaining)
    final remaining = peaks.where((p) => p != null).length;
    score += (28 - remaining) * 15;

    // Bonus for available moves
    if (wasteTop != null) {
      final wasteCard = TriPeaksCard(wasteTop!);
      for (int i = 0; i < 28; i++) {
        if (!isUncovered(i)) continue;
        final peakCard = TriPeaksCard(peaks[i]!);
        if (peakCard.canPlayOn(wasteCard)) {
          score += 10;
        }
      }
    }

    // Bonus for clearing peak tops (indices 0, 1, 2)
    for (int i = 0; i < 3; i++) {
      if (peaks[i] == null) {
        score += 20;
      }
    }

    // Penalty for empty stock
    if (stock.isEmpty) score -= 20;

    return score;
  }
}
