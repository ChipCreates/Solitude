import 'dart:async';
import 'dart:developer';
import '../../models/game_event.dart';
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
        // Game started - could track game sessions
        break;
      case GameEventType.gameWon:
        _achievementService.checkWinAchievements(event.data);
        break;
      case GameEventType.moveExecuted:
        _achievementService.incrementMoveCount();
        break;
      // ... handle other events
      default:
        break;
    }
  }

  void dispose() {
    _subscription?.cancel();
  }
}