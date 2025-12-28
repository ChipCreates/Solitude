/// Events emitted by the GameController for services to listen to
enum GameEventType {
  moveExecuted,
  gameWon,
  gameLost,
  cardFlipped,
  stockDrawn,
  invalidMove,
}

class GameEvent {
  final GameEventType type;
  final dynamic data;

  const GameEvent(this.type, [this.data]);
}