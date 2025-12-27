import 'package:flutter/foundation.dart';
import '../models/card.dart';
import '../models/pile.dart';

/// Manages selection state separately from GameController to enable granular rebuilds.
/// Only widgets that care about selection state need to listen to this notifier.
class SelectionStateNotifier extends ChangeNotifier {
  Pile? _selectedPile;
  List<PlayingCard>? _selectedCards;

  /// The pile containing the selected cards.
  Pile? get selectedPile => _selectedPile;

  /// The currently selected cards.
  List<PlayingCard>? get selectedCards => _selectedCards;

  /// Whether any cards are currently selected.
  bool get hasSelection => _selectedCards != null && _selectedCards!.isNotEmpty;

  /// Sets the selection and notifies listeners.
  void setSelection({
    required Pile pile,
    required List<PlayingCard> cards,
  }) {
    _selectedPile = pile;
    _selectedCards = cards;
    notifyListeners();
  }

  /// Clears the selection and notifies listeners.
  void clear() {
    if (_selectedPile != null || _selectedCards != null) {
      _selectedPile = null;
      _selectedCards = null;
      notifyListeners();
    }
  }

  /// Checks if the given card is currently selected.
  bool isCardSelected(PlayingCard card) => _selectedCards?.contains(card) ?? false;

  /// Checks if the given pile is the source of the current selection.
  bool isSelectedPile(Pile pile) => _selectedPile == pile;
}
