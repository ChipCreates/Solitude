import 'dart:async';
import 'game_controller.dart';
import 'audio_service.dart';
import '../models/game_event.dart';

/// Service that listens to GameController events and plays appropriate sounds
class GameAudioObserver {
  final AudioService _audioService;
  StreamSubscription<GameEvent>? _subscription;

  GameAudioObserver(this._audioService);

  void attach(GameController controller) {
    _subscription?.cancel();
    _subscription = controller.gameEvents.listen(_handleGameEvent);
  }

  void _handleGameEvent(GameEvent event) {
    switch (event.type) {
      case GameEventType.moveExecuted:
        _audioService.playCardPlace();
        break;
      case GameEventType.cardFlipped:
        _audioService.playCardFlip();
        break;
      case GameEventType.stockDrawn:
        _audioService.playCardFlip();
        break;
      case GameEventType.invalidMove:
        _audioService.playInvalidMove();
        break;
      case GameEventType.gameWon:
        _audioService.playWin();
        break;
      case GameEventType.gameLost:
        // No specific sound for losing yet
        break;
      default:
        // New achievement events don't trigger audio
        break;
    }
  }

  void dispose() {
    _subscription?.cancel();
  }
}
