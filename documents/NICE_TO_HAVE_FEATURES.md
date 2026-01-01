# Nice to Have Features for v1.1+

This document outlines the implementation plans for "Nice to Have" features identified in the architectural code review.

## 1. Spider Undo for Completed Sequences

### Current Issue
When a K→A sequence is completed in Spider solitaire, it's automatically moved to the foundation pile, but this action cannot be undone because it's not tracked in the move history.

### Location
[`spider_game.dart:490`](../lib/features/game/games/spider/spider_game.dart#L490)

### Implementation Plan

#### Step 1: Extend Move Model
Add tracking for sequence completions in the `extraData` field:

```dart
// When a sequence is completed, store:
final move = Move(
  fromPile: from,
  toPile: to,
  cards: cards,
  extraData: {
    'sequenceCompleted': true,
    'completedFrom': pile.id, // Which tableau pile
    'completedTo': foundationPile.id, // Which foundation
    'completedCards': sequenceCards.map((c) => c.uniqueId).toList(),
    'flippedAfterCompletion': didFlipCard,
  },
);
```

#### Step 2: Modify `_checkAndRemoveCompletedSequence`
Instead of silently removing sequences, return completion data:

```dart
SequenceCompletion? _checkAndRemoveCompletedSequence(Pile pile) {
  // ... existing validation logic ...
  
  if (sequenceFound) {
    return SequenceCompletion(
      sourcePile: pile,
      destinationPile: foundationPile,
      cards: removedCards,
      flippedCard: didFlipTopCard,
    );
  }
  return null;
}
```

#### Step 3: Update `executeMove`
Track completions in move history:

```dart
@override
Move? executeMove(Pile from, Pile to, List<PlayingCard> cards) {
  // ... existing move logic ...
  
  final move = Move(/* ... */);
  _moveHistory.add(move);
  
  // Check for completed sequences
  final completion = _checkAndRemoveCompletedSequence(to);
  if (completion != null) {
    // Store completion info in the move that triggered it
    final updatedMove = Move(
      fromPile: move.fromPile,
      toPile: move.toPile,
      cards: move.cards,
      flippedCard: move.flippedCard,
      extraData: {
        ...?move.extraData,
        'sequenceCompletion': completion.toJson(),
      },
    );
    _moveHistory[_moveHistory.length - 1] = updatedMove;
  }
  
  return move;
}
```

#### Step 4: Implement Undo Logic
```dart
@override
bool undo() {
  if (_moveHistory.isEmpty) return false;
  
  final move = _moveHistory.removeLast();
  _redoStack.add(move);
  _moveCount--;
  
  // Check if this move completed a sequence
  if (move.extraData?['sequenceCompletion'] != null) {
    final completion = SequenceCompletion.fromJson(
      move.extraData!['sequenceCompletion'] as Map<String, dynamic>
    );
    
    // Restore the completed sequence to the source pile
    final foundationPile = _findPileById(completion.destinationPileId);
    final sourcePile = _findPileById(completion.sourcePileId);
    
    if (foundationPile != null && sourcePile != null) {
      // Remove from foundation
      final cardsToRestore = <PlayingCard>[];
      for (int i = 0; i < 13; i++) {
        final card = foundationPile.removeTop();
        if (card != null) cardsToRestore.insert(0, card);
      }
      
      // Restore to source pile
      sourcePile.addCards(cardsToRestore);
      
      // Unflip the card if it was flipped due to sequence removal
      if (completion.flippedCard && sourcePile.length > 13) {
        sourcePile.cardAt(sourcePile.length - 14)?.faceUp = false;
      }
    }
  }
  
  // ... existing undo logic for the move itself ...
  
  return true;
}
```

### Estimated Effort
- 4-6 hours of implementation
- 2-3 hours of testing
- Requires creating `SequenceCompletion` data class

### Benefits
- Improved user experience - players can undo any action
- More forgiving gameplay
- Aligns with player expectations

---

## 2. Layout Strategy Consolidation

### Current Issue
Grid-based games (Klondike, Spider, FreeCell, etc.) duplicate layout calculation logic across multiple strategy classes.

### Implementation Plan

#### Step 1: Create GridLayoutStrategy Base Class

```dart
/// Base class for grid-based solitaire layouts
/// Provides common grid calculation and positioning logic
abstract class GridLayoutStrategy extends LayoutStrategy {
  const GridLayoutStrategy();
  
  // Configuration (subclasses override these)
  int get tableauCount;
  int get foundationCount;
  bool get hasStock;
  bool get hasWaste;
  int get freeCellCount => 0; // For FreeCell-style games
  
  // Grid calculation
  double get minPileSpacing => GameConstants.minPileSpacing;
  double get horizontalPadding => GameConstants.boardHorizontalPadding;
  double get verticalPadding => GameConstants.boardVerticalPadding;
  
  @override
  Map<String, Offset> calculatePilePositions({
    required Size boardSize,
    required double cardWidth,
    required double cardHeight,
    required GameInterface game,
  }) {
    final positions = <String, Offset>{};
    
    // Calculate grid dimensions
    final availableWidth = boardSize.width - (2 * horizontalPadding);
    final availableHeight = boardSize.height - (2 * verticalPadding);
    
    // Top row (stock, waste, foundations, free cells)
    double currentX = horizontalPadding;
    final topRowY = verticalPadding;
    
    // Stock
    if (hasStock) {
      positions['stock_0'] = Offset(currentX, topRowY);
      currentX += cardWidth + minPileSpacing;
    }
    
    // Waste
    if (hasWaste) {
      positions['waste_0'] = Offset(currentX, topRowY);
      currentX += cardWidth + minPileSpacing;
    }
    
    // Gap before foundations
    currentX += minPileSpacing;
    
    // Foundations (right-aligned)
    final foundationStartX = boardSize.width - horizontalPadding - 
                             (foundationCount * cardWidth) - 
                             ((foundationCount - 1) * minPileSpacing);
    currentX = foundationStartX;
    
    for (int i = 0; i < foundationCount; i++) {
      positions['foundation_$i'] = Offset(currentX, topRowY);
      currentX += cardWidth + minPileSpacing;
    }
    
    // Tableau (second row)
    final tableauY = topRowY + cardHeight + (minPileSpacing * 2);
    final tableauSpacing = (availableWidth - (tableauCount * cardWidth)) / 
                           (tableauCount - 1);
    currentX = horizontalPadding;
    
    for (int i = 0; i < tableauCount; i++) {
      positions['tableau_$i'] = Offset(currentX, tableauY);
      currentX += cardWidth + tableauSpacing;
    }
    
    return positions;
  }
}
```

#### Step 2: Convert Existing Strategies

```dart
class KlondikeLayoutStrategy extends GridLayoutStrategy {
  const KlondikeLayoutStrategy();
  
  @override
  int get tableauCount => GameConstants.klondikeTableauCount;
  
  @override
  int get foundationCount => GameConstants.standardFoundationCount;
  
  @override
  bool get hasStock => true;
  
  @override
  bool get hasWaste => true;
}

class SpiderLayoutStrategy extends GridLayoutStrategy {
  const SpiderLayoutStrategy();
  
  @override
  int get tableauCount => GameConstants.spiderTableauCount;
  
  @override
  int get foundationCount => 8;
  
  @override
  bool get hasStock => true;
  
  @override
  bool get hasWaste => false;
}

class FreeCellLayoutStrategy extends GridLayoutStrategy {
  const FreeCellLayoutStrategy();
  
  @override
  int get tableauCount => GameConstants.freecellTableauCount;
  
  @override
  int get foundationCount => GameConstants.standardFoundationCount;
  
  @override
  bool get hasStock => false;
  
  @override
  bool get hasWaste => false;
  
  @override
  int get freeCellCount => GameConstants.freecellFreeCount;
  
  @override
  Map<String, Offset> calculatePilePositions({
    required Size boardSize,
    required double cardWidth,
    required double cardHeight,
    required GameInterface game,
  }) {
    final positions = super.calculatePilePositions(
      boardSize: boardSize,
      cardWidth: cardWidth,
      cardHeight: cardHeight,
      game: game,
    );
    
    // Add free cell positions (left side of top row)
    double currentX = horizontalPadding;
    final topRowY = verticalPadding;
    
    for (int i = 0; i < freeCellCount; i++) {
      positions['cell_$i'] = Offset(currentX, topRowY);
      currentX += cardWidth + minPileSpacing;
    }
    
    return positions;
  }
}
```

### Estimated Effort
- 6-8 hours to create base class and refactor
- 3-4 hours of testing
- Minimal risk (can be done incrementally)

### Benefits
- Reduced code duplication (~500 lines saved)
- Easier to maintain and modify layouts
- Consistent positioning across games
- Simpler to add new grid-based games

---

## 3. GameController Decomposition

### Current Issue
[`GameController`](../lib/features/game/services/game_controller.dart) is 1089 lines and handles too many responsibilities:
- Game lifecycle
- UI state (selection, focus, hints)
- Animation orchestration
- Audio coordination
- Timer management
- Solver service management

### Implementation Plan

#### Create Focused Controllers

##### GameLifecycleController
```dart
/// Manages game lifecycle: new game, win/loss detection, game state
class GameLifecycleController {
  final GameInterface game;
  final StatisticsService statisticsService;
  final GameStateRepository? gameStateRepository;
  
  GameState _state = GameState.playing;
  bool _gameStarted = false;
  
  GameState get state => _state;
  bool get isWon => _state == GameState.won;
  bool get isLost => game.isLost || _state == GameState.lost;
  
  void startNewGame(GameType gameType) { /* ... */ }
  void checkGameState() { /* ... */ }
  void handleWin() { /* ... */ }
  void handleLoss() { /* ... */ }
}
```

##### GameInputController
```dart
/// Manages user input: tap, drag, selection, keyboard focus
class GameInputController {
  final GameInterface game;
  final SelectionStateNotifier selectionState;
  
  Pile? _focusedPile;
  
  void selectCard(Pile pile, PlayingCard card) { /* ... */ }
  void clearSelection() { /* ... */ }
  void cycleFocusForward() { /* ... */ }
  void cycleFocusBackward() { /* ... */ }
  void activateFocusedPile() { /* ... */ }
  void tapPile(Pile pile) { /* ... */ }
  void tapCard(Pile pile, PlayingCard card) { /* ... */ }
  Future<bool> doubleTapCard(Pile pile, PlayingCard card) { /* ... */ }
}
```

##### GameAnimationController
```dart
/// Manages card animations
class GameAnimationController {
  final AnimationStateNotifier animationState;
  final BoardLayoutService boardLayout;
  
  void startCardAnimation({
    required PlayingCard card,
    required Offset startPosition,
    required Offset endPosition,
    required double cardWidth,
  }) { /* ... */ }
  
  Future<void> animateStockDraw(double cardWidth) { /* ... */ }
  void clearCardAnimation() { /* ... */ }
  bool isCardAnimating(PlayingCard card) { /* ... */ }
}
```

##### Refactored GameController
```dart
/// Orchestrates game controllers and coordinates interactions
class GameController extends ChangeNotifier {
  // Delegates
  late final GameLifecycleController lifecycle;
  late final GameInputController input;
  late final GameAnimationController animation;
  late final SolverService solver;
  
  GameController({/* ... */}) {
    lifecycle = GameLifecycleController(
      game: _game,
      statisticsService: statisticsService,
      gameStateRepository: gameStateRepository,
    );
    
    input = GameInputController(
      game: _game,
      selectionState: selectionState,
    );
    
    animation = GameAnimationController(
      animationState: animationState,
      boardLayout: boardLayout,
    );
    
    solver = SolverService(
      game: _game,
      hintState: hintState,
    );
  }
  
  // Simplified public API that delegates to focused controllers
  void startNewGame(GameType gameType) => lifecycle.startNewGame(gameType);
  void selectCard(Pile pile, PlayingCard card) => input.selectCard(pile, card);
  void startCardAnimation(/* ... */) => animation.startCardAnimation(/* ... */);
  Future<List<dynamic>?> solveGame() => solver.solveGame();
  
  // Coordination methods (when controllers need to work together)
  Future<void> executeAnimatedMove(/* ... */) async {
    animation.startCardAnimation(/* ... */);
    await Future.delayed(GameConstants.moveAnimationDuration);
    final move = game.executeMove(from, to, cards);
    input.clearSelection();
    lifecycle.checkGameState();
    notifyListeners();
  }
}
```

### Migration Strategy
1. Create new controller classes
2. Move methods one-by-one from GameController to focused controllers
3. Update GameController to delegate to new controllers
4. Test each controller independently
5. Remove old methods from GameController once delegation is complete

### Estimated Effort
- 10-12 hours for initial refactoring
- 4-6 hours for testing
- Can be done incrementally without breaking changes

### Benefits
- Improved maintainability
- Easier to test individual components
- Clearer responsibilities
- Reduced cognitive load when working on specific features

---

## 4. Integration/E2E Test Template

### Current Gap
No integration or end-to-end tests exist. All tests are unit tests.

### Test Template

#### Integration Test Example
```dart
// test/integration/game_flow_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:solitude/main.dart';
import 'package:flutter/material.dart';

void main() {
  group('Klondike Game Flow Integration Tests', () {
    testWidgets('Complete game flow: start -> play -> win', (tester) async {
      // 1. Launch app
      await tester.pumpWidget(const SolitaireApp());
      await tester.pumpAndSettle();
      
      // 2. Select Klondike from game chooser
      expect(find.text('Klondike'), findsOneWidget);
      await tester.tap(find.text('Klondike'));
      await tester.pumpAndSettle();
      
      // 3. Verify game screen loaded
      expect(find.byType(GameScreen), findsOneWidget);
      
      // 4. Make some moves
      // ... tap cards, verify state changes ...
      
      // 5. Use hint
      final hintButton = find.byIcon(Icons.lightbulb);
      await tester.tap(hintButton);
      await tester.pumpAndSettle();
      
      // 6. Verify hint is shown
      // ... check for highlight/glow on cards ...
      
      // 7. Undo move
      final undoButton = find.byIcon(Icons.undo);
      await tester.tap(undoButton);
      await tester.pumpAndSettle();
      
      // 8. Open settings
      final settingsButton = find.byIcon(Icons.settings);
      await tester.tap(settingsButton);
      await tester.pumpAndSettle();
      
      // 9. Change difficulty
      await tester.tap(find.text('Easy'));
      await tester.pumpAndSettle();
      
      // 10. Return to game
      await tester.pageBack();
      await tester.pumpAndSettle();
      
      // 11. Verify game continued properly
      expect(find.byType(GameScreen), findsOneWidget);
    });
    
    testWidgets('Game state persistence: pause -> resume', (tester) async {
      // 1. Start game
      await tester.pumpWidget(const SolitaireApp());
      await tester.pumpAndSettle();
      
      // 2. Make moves
      // ... execute some moves ...
      
      // 3. Pause/background app (trigger save)
      final binding = tester.binding;
      binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await tester.pumpAndSettle();
      
      // 4. Completely restart app
      await tester.pumpWidget(Container()); // Clear widget tree
      await tester.pumpWidget(const SolitaireApp());
      await tester.pumpAndSettle();
      
      // 5. Verify game restored
      expect(find.byType(GameScreen), findsOneWidget);
      // ... verify move count, timer, card positions ...
    });
    
    testWidgets('Achievement unlock flow', (tester) async {
      // 1. Start game
      await tester.pumpWidget(const SolitaireApp());
      await tester.pumpAndSettle();
      
      // 2. Win game (use test hooks to force win)
      // ... execute win scenario ...
      
      // 3. Verify achievement notification shown
      expect(find.text('First Victory'), findsOneWidget);
      
      // 4. Open achievements screen
      // ... navigate to achievements ...
      
      // 5. Verify achievement is unlocked
      // ... check achievement state ...
    });
  });
}
```

#### E2E Test Template
```dart
// integration_test/app_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:solitude/main.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  
  group('E2E Tests', () {
    testWidgets('Full user journey', (tester) async {
      await tester.pumpWidget(const SolitaireApp());
      await tester.pumpAndSettle();
      
      // Complete user journey testing:
      // 1. First launch experience
      // 2. Game selection
      // 3. Playing multiple games
      // 4. Settings changes
      // 5. Statistics tracking
      // 6. Achievement unlocking
      // 7. Theme switching
      // 8. Sound/vibration toggles
      // ... etc
    });
  });
}
```

### Test Coverage Goals
- **Unit Tests**: Already at 929+ tests ✅
- **Integration Tests**: Target 20-30 tests covering:
  - Game flow for each game type
  - State persistence
  - Settings changes
  - Statistics tracking
  - Achievement system
- **E2E Tests**: Target 5-10 tests covering:
  - Complete user journeys
  - Cross-screen navigation
  - Data persistence across app restarts

### Estimated Effort
- 8-10 hours for integration test suite
- 4-6 hours for E2E test setup and tests
- Ongoing: Add tests for new features

### Benefits
- Catch integration bugs before release
- Verify user flows work end-to-end
- Confidence in app stability
- Regression detection

---

## Priority Recommendations

### High Priority (v1.1)
1. **Integration Tests** - Essential for release confidence
2. **Spider Undo** - High user impact, moderate effort

### Medium Priority (v1.2)
3. **Layout Strategy Consolidation** - Technical debt reduction
4. **GameController Decomposition** - Maintainability improvement

### Implementation Order
1. Start with Integration/E2E tests (can run in parallel with development)
2. Implement Spider undo (standalone feature)
3. Consolidate layout strategies (code health)
4. Decompose GameController (major refactoring, save for last)

---

## Conclusion

All "Nice to Have" features are well-documented with implementation plans. The codebase is ready for v1.0 release, and these enhancements can be implemented incrementally in future versions without disrupting existing functionality.
