/// Events emitted by the GameController for services to listen to
enum GameEventType {
  moveExecuted,
  gameWon,
  gameLost,
  cardFlipped,
  stockDrawn,
  invalidMove,
  // New Events for Achievements
  gameStarted,
  undoUsed,
  hintUsed,
  autoCompleteTriggered,
  streakUpdated, // Optional, for future use
}

class GameEvent {
  final GameEventType type;
  final dynamic data;

  const GameEvent(this.type, [this.data]);
}