import 'dart:async';
import 'dart:developer';
import 'package:solitude/core/models/game_event.dart';
import 'achievement_service.dart';

class AchievementObserver {
  final AchievementService _achievementService;
  StreamSubscription<GameEvent>? _subscription;

  AchievementObserver(this._achievementService);

  void startObserving(Stream<GameEvent> gameEvents) {
    _subscription?.cancel();
    _subscription = gameEvents.listen(_handleGameEvent);
  }

  void _handleGameEvent(GameEvent event) {
    // Print to debug log for all events
    log('AchievementObserver saw: ${event.type}');

    switch (event.type) {
      case GameEventType.gameStarted:
        // Reset session tracking for perfect game achievement
        _achievementService.resetSessionTracking();
        break;

      case GameEventType.gameWon:
        // Pass game data to check achievements
        _achievementService.checkWinAchievements(event.data);
        break;

      case GameEventType.moveExecuted:
        // Track move count for efficiency achievements
        _achievementService.incrementMoveCount();
        break;

      case GameEventType.undoUsed:
        // Track undo usage (disqualifies perfect game achievement)
        _achievementService.trackUndoUsed();
        break;

      case GameEventType.hintUsed:
        // Track hint usage (disqualifies perfect game achievement)
        _achievementService.trackHintUsed();
        break;

      case GameEventType.cardFlipped:
      case GameEventType.stockDrawn:
      case GameEventType.invalidMove:
      case GameEventType.gameLost:
      case GameEventType.autoCompleteTriggered:
      case GameEventType.streakUpdated:
        // These events don't affect achievements directly
        break;
    }
  }

  void dispose() {
    _subscription?.cancel();
  }
}
