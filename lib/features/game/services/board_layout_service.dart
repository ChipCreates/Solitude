import 'package:flutter/material.dart';
import '../models/pile.dart';

/// Service for managing board layout and pile positioning
/// Used by widgets to calculate card positions for animations
class BoardLayoutService {
  final Map<String, GlobalKey> _pileKeys = {};

  /// Initialize pile keys for position tracking
  void initializePileKeys(List<Pile> piles) {
    _pileKeys.clear();
    for (final pile in piles) {
      _pileKeys[pile.id] = GlobalKey();
    }
  }

  /// Get the GlobalKey for a specific pile ID
  GlobalKey? getKeyForPileId(String pileId) => _pileKeys[pileId];

  /// Calculate card position from pile position
  Offset? getCardPosition(Pile pile, {double stackOffset = 0}) {
    final key = _pileKeys[pile.id];
    if (key?.currentContext == null) return null;

    final RenderBox? box = key!.currentContext!.findRenderObject() as RenderBox?;
    if (box == null) return null;

    // Get position relative to screen
    final position = box.localToGlobal(Offset.zero);

    // For tableau piles, offset by stack position if there are cards
    if (!pile.isEmpty && stackOffset > 0) {
      final cardIndex = pile.length - 1;
      return Offset(position.dx, position.dy + (cardIndex * stackOffset));
    }

    return position;
  }
}