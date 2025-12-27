import 'package:flutter/foundation.dart';
import '../models/card.dart';
import '../models/pile.dart';

/// Immutable data class representing the state needed to render a tableau pile.
/// Used with Selector to enable granular rebuilds - only rebuilds when this data changes.
@immutable
class TableauPileRenderData {
  final Pile pile;
  final int pileVersion;  // Incremented when pile contents change
  final bool isValidDestination;
  final bool isHintDestination;
  final bool isHintSource;
  final bool isFocused;
  final List<PlayingCard>? selectedCards;
  final Pile? selectedPile;
  final List<PlayingCard>? hintCards;
  final PlayingCard? animatingCard;

  const TableauPileRenderData({
    required this.pile,
    required this.pileVersion,
    required this.isValidDestination,
    required this.isHintDestination,
    required this.isHintSource,
    required this.isFocused,
    required this.selectedCards,
    required this.selectedPile,
    required this.hintCards,
    required this.animatingCard,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! TableauPileRenderData) return false;

    return pile == other.pile &&
        pileVersion == other.pileVersion &&
        isValidDestination == other.isValidDestination &&
        isHintDestination == other.isHintDestination &&
        isHintSource == other.isHintSource &&
        isFocused == other.isFocused &&
        listEquals(selectedCards, other.selectedCards) &&
        selectedPile == other.selectedPile &&
        listEquals(hintCards, other.hintCards) &&
        animatingCard == other.animatingCard;
  }

  @override
  int get hashCode => Object.hash(
    pile,
    pileVersion,
    isValidDestination,
    isHintDestination,
    isHintSource,
    isFocused,
    selectedCards,
    selectedPile,
    hintCards,
    animatingCard,
  );
}

/// Immutable data class for stock pile rendering.
@immutable
class StockPileRenderData {
  final Pile pile;
  final int pileVersion;
  final bool isFocused;
  final bool isHintSource;

  const StockPileRenderData({
    required this.pile,
    required this.pileVersion,
    required this.isFocused,
    required this.isHintSource,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! StockPileRenderData) return false;

    return pile == other.pile &&
        pileVersion == other.pileVersion &&
        isFocused == other.isFocused &&
        isHintSource == other.isHintSource;
  }

  @override
  int get hashCode => Object.hash(pile, pileVersion, isFocused, isHintSource);
}

/// Immutable data class for waste pile rendering.
@immutable
class WastePileRenderData {
  final Pile pile;
  final int pileVersion;
  final bool isFocused;
  final bool isHintSource;
  final List<PlayingCard>? selectedCards;
  final Pile? selectedPile;
  final PlayingCard? animatingCard;

  const WastePileRenderData({
    required this.pile,
    required this.pileVersion,
    required this.isFocused,
    required this.isHintSource,
    required this.selectedCards,
    required this.selectedPile,
    required this.animatingCard,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! WastePileRenderData) return false;

    return pile == other.pile &&
        pileVersion == other.pileVersion &&
        isFocused == other.isFocused &&
        isHintSource == other.isHintSource &&
        listEquals(selectedCards, other.selectedCards) &&
        selectedPile == other.selectedPile &&
        animatingCard == other.animatingCard;
  }

  @override
  int get hashCode => Object.hash(
    pile,
    pileVersion,
    isFocused,
    isHintSource,
    selectedCards,
    selectedPile,
    animatingCard,
  );
}

/// Immutable data class for foundation pile rendering.
@immutable
class FoundationPileRenderData {
  final Pile pile;
  final int pileVersion;
  final bool isValidDestination;
  final bool isHintDestination;

  const FoundationPileRenderData({
    required this.pile,
    required this.pileVersion,
    required this.isValidDestination,
    required this.isHintDestination,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! FoundationPileRenderData) return false;

    return pile == other.pile &&
        pileVersion == other.pileVersion &&
        isValidDestination == other.isValidDestination &&
        isHintDestination == other.isHintDestination;
  }

  @override
  int get hashCode => Object.hash(
    pile,
    pileVersion,
    isValidDestination,
    isHintDestination,
  );
}
