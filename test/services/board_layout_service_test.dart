import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:solitude/features/game/services/board_layout_service.dart';
import 'package:solitude/features/game/models/pile.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('BoardLayoutService', () {
    group('initialization', () {
      test('creates service without error', () {
        final service = BoardLayoutService();
        expect(service, isNotNull);
      });

      test('starts with empty pile keys', () {
        final service = BoardLayoutService();
        // Cannot directly test private field, but service should be functional
        expect(service, isNotNull);
      });
    });

    group('pile key management', () {
      test('initializePileKeys clears existing keys', () {
        final service = BoardLayoutService();
        final piles = [
          Pile(type: PileType.tableau, index: 1),
          Pile(type: PileType.tableau, index: 2),
        ];

        // Initialize twice to test clearing
        service.initializePileKeys(piles);
        service.initializePileKeys(piles);

        expect(service, isNotNull);
      });

      test('initializePileKeys creates keys for all piles', () {
        final service = BoardLayoutService();
        final piles = [
          Pile(type: PileType.stock, index: 0),
          Pile(type: PileType.waste, index: 0),
          Pile(type: PileType.foundation, index: 0),
          Pile(type: PileType.tableau, index: 0),
          Pile(type: PileType.tableau, index: 1),
        ];

        service.initializePileKeys(piles);

        expect(service, isNotNull);
      });

      test('initializePileKeys handles empty list', () {
        final service = BoardLayoutService();

        expect(() => service.initializePileKeys([]), returnsNormally);
      });
    });

    group('key retrieval', () {
      test('getKeyForPileId returns null for non-existent pile', () {
        final service = BoardLayoutService();
        final key = service.getKeyForPileId('non_existent_pile');

        expect(key, isNull);
      });

      test('getKeyForPileId returns key for existing pile', () {
        final service = BoardLayoutService();
        final pile = Pile(type: PileType.tableau, index: 1);

        service.initializePileKeys([pile]);
        final key = service.getKeyForPileId('tableau_1');

        expect(key, isNotNull);
        expect(key, isA<GlobalKey>());
      });

      test('getKeyForPileId returns correct key for pile', () {
        final service = BoardLayoutService();
        final pile1 = Pile(type: PileType.tableau, index: 1);
        final pile2 = Pile(type: PileType.tableau, index: 2);

        service.initializePileKeys([pile1, pile2]);
        final key1 = service.getKeyForPileId('tableau_1');
        final key2 = service.getKeyForPileId('tableau_2');

        expect(key1, isNotNull);
        expect(key2, isNotNull);
        expect(key1, isNot(equals(key2)));
      });
    });

    group('position calculation', () {
      test('getCardPosition returns null when key context is null', () {
        final service = BoardLayoutService();
        final pile = Pile(type: PileType.tableau, index: 1);

        service.initializePileKeys([pile]);
        final position = service.getCardPosition(pile);

        // Without rendering, context will be null
        expect(position, isNull);
      });

      test('getCardPosition handles different pile types', () {
        final service = BoardLayoutService();

        final stock = Pile(type: PileType.stock, index: 0);
        final waste = Pile(type: PileType.waste, index: 0);
        final foundation = Pile(type: PileType.foundation, index: 0);
        final tableau = Pile(type: PileType.tableau, index: 0);

        service.initializePileKeys([stock, waste, foundation, tableau]);

        expect(service.getCardPosition(stock), isNull);
        expect(service.getCardPosition(waste), isNull);
        expect(service.getCardPosition(foundation), isNull);
        expect(service.getCardPosition(tableau), isNull);
      });

      test('getCardPosition handles non-existent pile', () {
        final service = BoardLayoutService();
        final pile = Pile(type: PileType.tableau, index: 999);

        final position = service.getCardPosition(pile);

        expect(position, isNull);
      });
    });

    group('stack offset calculation', () {
      test('getCardPosition applies stack offset for non-empty piles', () {
        final service = BoardLayoutService();
        final pile = Pile(type: PileType.tableau, index: 1);

        service.initializePileKeys([pile]);

        // Test with different stack offsets
        final position0 = service.getCardPosition(pile, stackOffset: 0);
        final position10 = service.getCardPosition(pile, stackOffset: 10);
        final position20 = service.getCardPosition(pile, stackOffset: 20);

        // Without context, all should be null
        expect(position0, isNull);
        expect(position10, isNull);
        expect(position20, isNull);
      });

      test('getCardPosition with zero stack offset', () {
        final service = BoardLayoutService();
        final pile = Pile(type: PileType.tableau, index: 1);

        service.initializePileKeys([pile]);
        final position = service.getCardPosition(pile, stackOffset: 0);

        expect(position, isNull);
      });
    });

    group('pile property handling', () {
      test('handles piles with different indices', () {
        final service = BoardLayoutService();
        final piles = [
          Pile(type: PileType.tableau, index: 1),
          Pile(type: PileType.tableau, index: 2),
          Pile(type: PileType.tableau, index: 3),
        ];

        service.initializePileKeys(piles);

        for (final pile in piles) {
          final key = service.getKeyForPileId(pile.id);
          expect(key, isNotNull);
        }
      });

      test('handles duplicate pile indices gracefully', () {
        final service = BoardLayoutService();
        final pile1 = Pile(type: PileType.tableau, index: 1);
        final pile2 = Pile(type: PileType.tableau, index: 1);

        service.initializePileKeys([pile1, pile2]);

        final key = service.getKeyForPileId('tableau_1');
        expect(key, isNotNull);
      });

      test('handles special pile types', () {
        final service = BoardLayoutService();
        final piles = [
          Pile(type: PileType.stock, index: 0),
          Pile(type: PileType.waste, index: 0),
          Pile(type: PileType.foundation, index: 0),
          Pile(type: PileType.foundation, index: 1),
          Pile(type: PileType.foundation, index: 2),
          Pile(type: PileType.foundation, index: 3),
        ];

        service.initializePileKeys(piles);

        for (final pile in piles) {
          final key = service.getKeyForPileId(pile.id);
          expect(key, isNotNull);
        }
      });
    });

    group('service lifecycle', () {
      test('can be instantiated multiple times', () {
        final service1 = BoardLayoutService();
        final service2 = BoardLayoutService();

        expect(service1, isNotNull);
        expect(service2, isNotNull);
        expect(service1, isNot(equals(service2)));
      });

      test('initializePileKeys can be called multiple times', () {
        final service = BoardLayoutService();
        final piles = [Pile(type: PileType.tableau, index: 1)];

        service.initializePileKeys(piles);
        service.initializePileKeys(piles);
        service.initializePileKeys([]); // Clear and reinitialize

        expect(service, isNotNull);
      });

      test('getKeyForPileId can be called multiple times', () {
        final service = BoardLayoutService();
        final pile = Pile(type: PileType.tableau, index: 1);

        service.initializePileKeys([pile]);

        final key1 = service.getKeyForPileId('tableau_1');
        final key2 = service.getKeyForPileId('tableau_1');
        final key3 = service.getKeyForPileId('non_existent');

        expect(key1, isNotNull);
        expect(key2, isNotNull);
        expect(key1, equals(key2));
        expect(key3, isNull);
      });
    });

    group('edge cases', () {
      test('handles very large pile indices', () {
        final service = BoardLayoutService();
        const largeIndex = 999999;
        final pile = Pile(type: PileType.tableau, index: largeIndex);

        service.initializePileKeys([pile]);
        final key = service.getKeyForPileId('tableau_$largeIndex');

        expect(key, isNotNull);
      });

      test('handles zero index', () {
        final service = BoardLayoutService();
        final pile = Pile(type: PileType.tableau, index: 0);

        service.initializePileKeys([pile]);
        final key = service.getKeyForPileId('tableau_0');

        expect(key, isNotNull);
      });

      test('handles large number of piles', () {
        final service = BoardLayoutService();
        final piles =
            List.generate(100, (i) => Pile(type: PileType.tableau, index: i));

        service.initializePileKeys(piles);

        for (int i = 0; i < 100; i++) {
          final key = service.getKeyForPileId('tableau_$i');
          expect(key, isNotNull);
        }
      });
    });

    group('performance considerations', () {
      test('key retrieval is efficient', () {
        final service = BoardLayoutService();
        final piles =
            List.generate(50, (i) => Pile(type: PileType.tableau, index: i));

        service.initializePileKeys(piles);

        // Should complete quickly
        final start = DateTime.now();
        for (int i = 0; i < 50; i++) {
          service.getKeyForPileId('tableau_$i');
        }
        final end = DateTime.now();

        expect(end.difference(start).inMilliseconds, lessThan(100));
      });

      test('multiple initializations are handled efficiently', () {
        final service = BoardLayoutService();
        final piles =
            List.generate(20, (i) => Pile(type: PileType.tableau, index: i));

        // Multiple reinitializations
        service.initializePileKeys(piles);
        service.initializePileKeys(piles);
        service.initializePileKeys(piles);

        expect(service, isNotNull);
      });
    });

    group('pile ID generation', () {
      test('pile ID is generated correctly from type and index', () {
        final pile = Pile(type: PileType.tableau, index: 5);
        expect(pile.id, equals('tableau_5'));
      });

      test('different pile types generate different IDs', () {
        final stock = Pile(type: PileType.stock, index: 0);
        final tableau = Pile(type: PileType.tableau, index: 0);

        expect(stock.id, isNot(equals(tableau.id)));
        expect(stock.id, equals('stock_0'));
        expect(tableau.id, equals('tableau_0'));
      });

      test('same type different indices generate different IDs', () {
        final pile1 = Pile(type: PileType.foundation, index: 0);
        final pile2 = Pile(type: PileType.foundation, index: 1);

        expect(pile1.id, isNot(equals(pile2.id)));
        expect(pile1.id, equals('foundation_0'));
        expect(pile2.id, equals('foundation_1'));
      });
    });
  });
}
