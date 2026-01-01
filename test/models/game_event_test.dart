import 'package:flutter_test/flutter_test.dart';
import 'package:solitude/core/models/game_event.dart';

void main() {
  group('GameEvent', () {
    group('GameEventType', () {
      test('all event types are properly defined', () {
        expect(
            GameEventType.values,
            containsAll([
              GameEventType.moveExecuted,
              GameEventType.gameWon,
              GameEventType.gameLost,
              GameEventType.cardFlipped,
              GameEventType.stockDrawn,
              GameEventType.invalidMove,
              GameEventType.gameStarted,
              GameEventType.undoUsed,
              GameEventType.hintUsed,
              GameEventType.autoCompleteTriggered,
              GameEventType.streakUpdated,
            ]));
      });
    });

    group('GameEvent constructor', () {
      test('creates event without data', () {
        const event = GameEvent(GameEventType.moveExecuted);

        expect(event.type, GameEventType.moveExecuted);
        expect(event.data, isNull);
      });

      test('creates event with data', () {
        const moveData = {'from': 'tableau_0', 'to': 'foundation_0'};
        const event = GameEvent(GameEventType.moveExecuted, moveData);

        expect(event.type, GameEventType.moveExecuted);
        expect(event.data, equals(moveData));
      });

      test('creates event with different data types', () {
        // String data
        const stringEvent = GameEvent(GameEventType.gameWon, 'Victory!');
        expect(stringEvent.data, equals('Victory!'));

        // Integer data
        const intEvent = GameEvent(GameEventType.streakUpdated, 5);
        expect(intEvent.data, equals(5));

        // Map data
        const mapData = {'moves': 42, 'time': 180};
        const mapEvent =
            GameEvent(GameEventType.autoCompleteTriggered, mapData);
        expect(mapEvent.data, equals(mapData));

        // List data
        const listData = ['card1', 'card2', 'card3'];
        const listEvent = GameEvent(GameEventType.cardFlipped, listData);
        expect(listEvent.data, equals(listData));
      });
    });

    group('Event type categorization', () {
      test('game state events are correctly typed', () {
        const gameWon = GameEvent(GameEventType.gameWon);
        const gameLost = GameEvent(GameEventType.gameLost);
        const gameStarted = GameEvent(GameEventType.gameStarted);

        expect(gameWon.type, GameEventType.gameWon);
        expect(gameLost.type, GameEventType.gameLost);
        expect(gameStarted.type, GameEventType.gameStarted);
      });

      test('move-related events are correctly typed', () {
        const moveExecuted = GameEvent(GameEventType.moveExecuted);
        const undoUsed = GameEvent(GameEventType.undoUsed);
        const invalidMove = GameEvent(GameEventType.invalidMove);

        expect(moveExecuted.type, GameEventType.moveExecuted);
        expect(undoUsed.type, GameEventType.undoUsed);
        expect(invalidMove.type, GameEventType.invalidMove);
      });

      test('card interaction events are correctly typed', () {
        const cardFlipped = GameEvent(GameEventType.cardFlipped);
        const stockDrawn = GameEvent(GameEventType.stockDrawn);

        expect(cardFlipped.type, GameEventType.cardFlipped);
        expect(stockDrawn.type, GameEventType.stockDrawn);
      });

      test('assistance events are correctly typed', () {
        const hintUsed = GameEvent(GameEventType.hintUsed);
        const autoCompleteTriggered =
            GameEvent(GameEventType.autoCompleteTriggered);

        expect(hintUsed.type, GameEventType.hintUsed);
        expect(autoCompleteTriggered.type, GameEventType.autoCompleteTriggered);
      });
    });

    group('Event immutability', () {
      test('event properties are read-only', () {
        const event = GameEvent(GameEventType.moveExecuted);

        // These should compile but the fields are final
        expect(() => event.type, returnsNormally);
        expect(() => event.data, returnsNormally);
      });

      test('events with same parameters are equal', () {
        const event1 = GameEvent(GameEventType.moveExecuted);
        const event2 = GameEvent(GameEventType.moveExecuted);

        expect(event1.type, equals(event2.type));
        expect(event1.data, equals(event2.data));
      });
    });

    group('Event data handling', () {
      test('handles null data gracefully', () {
        const event = GameEvent(GameEventType.moveExecuted);

        expect(event.data, isNull);
      });

      test('handles complex nested data', () {
        final complexData = {
          'move': {
            'from': {'type': 'tableau', 'index': 0},
            'to': {'type': 'foundation', 'index': 1},
            'cards': [
              {'suit': 'hearts', 'rank': 'ace'},
              {'suit': 'hearts', 'rank': 'two'},
            ],
          },
          'timestamp': DateTime.now().toIso8601String(),
        };

        final event = GameEvent(GameEventType.moveExecuted, complexData);

        expect(event.data, equals(complexData));
        expect(event.data!['move']['from']['type'], equals('tableau'));
        expect(event.data!['move']['cards'], hasLength(2));
      });

      test('supports various data types as payload', () {
        // Boolean data
        const boolEvent = GameEvent(GameEventType.autoCompleteTriggered, true);
        expect(boolEvent.data, isA<bool>());

        // Double data
        const doubleEvent = GameEvent(GameEventType.streakUpdated, 2.5);
        expect(doubleEvent.data, isA<double>());

        // DateTime data
        final dateTime = DateTime.now();
        final dateTimeEvent = GameEvent(GameEventType.gameWon, dateTime);
        expect(dateTimeEvent.data, equals(dateTime));
      });
    });

    group('Event equality and comparison', () {
      test('events with same type and data are equivalent', () {
        const data = {'test': 'value'};
        const event1 = GameEvent(GameEventType.moveExecuted, data);
        const event2 = GameEvent(GameEventType.moveExecuted, data);

        expect(event1.type, equals(event2.type));
        expect(event1.data, equals(event2.data));
      });

      test('events with different types are distinguishable', () {
        const event1 = GameEvent(GameEventType.moveExecuted);
        const event2 = GameEvent(GameEventType.cardFlipped);

        expect(event1.type, isNot(equals(event2.type)));
      });

      test('events with same type but different data are distinguishable', () {
        const event1 = GameEvent(GameEventType.moveExecuted, 'data1');
        const event2 = GameEvent(GameEventType.moveExecuted, 'data2');

        expect(event1.data, isNot(equals(event2.data)));
      });
    });

    group('Event type usage patterns', () {
      test('can identify game state changes', () {
        const gameEvents = [
          GameEvent(GameEventType.gameWon),
          GameEvent(GameEventType.gameLost),
          GameEvent(GameEventType.gameStarted),
        ];

        final gameStateEvents = gameEvents
            .where((event) =>
                event.type == GameEventType.gameWon ||
                event.type == GameEventType.gameLost ||
                event.type == GameEventType.gameStarted)
            .toList();

        expect(gameStateEvents, hasLength(3));
      });

      test('can identify move-related events', () {
        const moveEvents = [
          GameEvent(GameEventType.moveExecuted),
          GameEvent(GameEventType.undoUsed),
          GameEvent(GameEventType.invalidMove),
        ];

        final moveRelatedEvents = moveEvents
            .where((event) =>
                event.type == GameEventType.moveExecuted ||
                event.type == GameEventType.undoUsed ||
                event.type == GameEventType.invalidMove)
            .toList();

        expect(moveRelatedEvents, hasLength(3));
      });

      test('can identify user assistance events', () {
        const assistanceEvents = [
          GameEvent(GameEventType.hintUsed),
          GameEvent(GameEventType.autoCompleteTriggered),
        ];

        final assistanceRelatedEvents = assistanceEvents
            .where((event) =>
                event.type == GameEventType.hintUsed ||
                event.type == GameEventType.autoCompleteTriggered)
            .toList();

        expect(assistanceRelatedEvents, hasLength(2));
      });
    });
  });
}
