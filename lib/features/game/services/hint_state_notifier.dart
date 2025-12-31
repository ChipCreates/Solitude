import 'package:flutter/foundation.dart';
import '../models/card.dart';
import '../models/pile.dart';

/// Manages hint state separately from GameController to enable granular rebuilds.
/// Only widgets that care about hint state need to listen to this notifier.
class HintStateNotifier extends ChangeNotifier {
  Pile? _sourcePile;
  List<PlayingCard>? _cards;
  Pile? _destinationPile;

  /// The pile where the hint originates (source of the move).
  Pile? get sourcePile => _sourcePile;

  /// The cards to be moved in the hint.
  List<PlayingCard>? get cards => _cards;

  /// The destination pile for the hint move.
  Pile? get destinationPile => _destinationPile;

  /// Whether a hint is currently active.
  bool get isActive => _destinationPile != null;

  /// Sets hint state and notifies listeners.
  void setHint({
    required Pile sourcePile,
    required List<PlayingCard>? cards,
    required Pile destinationPile,
  }) {
    _sourcePile = sourcePile;
    _cards = cards;
    _destinationPile = destinationPile;
    notifyListeners();
  }

  /// Clears the hint and notifies listeners.
  void clear() {
    if (_sourcePile != null || _cards != null || _destinationPile != null) {
      _sourcePile = null;
      _cards = null;
      _destinationPile = null;
      notifyListeners();
    }
  }

  /// Checks if the given pile is the hint source.
  bool isSourcePile(Pile pile) => _sourcePile == pile;

  /// Checks if the given pile is the hint destination.
  bool isDestinationPile(Pile pile) => _destinationPile == pile;

  /// Checks if the given card is part of the hint.
  bool isHintCard(PlayingCard card) => _cards?.contains(card) ?? false;
}
