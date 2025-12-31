# Solitude - Architectural Design Document
## Achievement System, Auto-Complete, and Victory Animation Overhaul

---

## Executive Summary

This document outlines the architectural design for three major features to be implemented in the Solitude solitaire game:

1. **Game-Independent Achievement System** using Hive for persistence
2. **Autocomplete Heuristic & UI** for detecting and finishing won games
3. **End Game Animation Overhaul** using actual Card widgets

---

## 1. Game-Independent Achievement System

### 1.1 Architecture Overview

The achievement system will follow an **event-driven architecture** that decouples game logic from achievement tracking. The system will:
- Listen to generic game events emitted by `GameController`
- Track progress towards achievements using Hive for persistence
- Display unlocked achievements through a notification system

### 1.2 Directory Structure

```
lib/
├── achievements/
│   ├── models/
│   │   ├── achievement.dart          # Achievement data model
│   │   ├── achievement_progress.dart # Progress tracking model
│   │   └── achievement_category.dart # Achievement categorization
│   ├── services/
│   │   ├── achievement_service.dart  # Core achievement logic
│   │   └── achievement_observer.dart # Event listener/observer
│   └── widgets/
│       ├── achievement_badge.dart    # Badge display widget
│       ├── achievement_list.dart     # Achievement gallery view
│       └── achievement_popup.dart    # Unlock notification popup
```

### 1.3 Data Models

#### Achievement Model (Hive Type ID: 0)
```dart
@HiveType(typeId: 0)
class Achievement extends HiveObject {
  @HiveField(0)
  final String id;
  
  @HiveField(1)
  final String title;
  
  @HiveField(2)
  final String description;
  
  @HiveField(3)
  final String iconPath;  // Asset path for badge icon
  
  @HiveField(4)
  final AchievementCategory category;
  
  @HiveField(5)
  final int targetValue;  // For progress-based achievements
  
  @HiveField(6)
  final Map<String, dynamic> criteria;  // Flexible criteria definition
  
  @HiveField(7)
  bool isUnlocked;
  
  @HiveField(8)
  DateTime? unlockedAt;
  
  @HiveField(9)
  int currentProgress;
}
```

#### Achievement Categories
```dart
enum AchievementCategory {
  speed,      // Time-based achievements
  efficiency, // Move-based achievements  
  streak,     // Consecutive wins
  milestone,  // Games played/won milestones
  special,    // Special conditions (perfect game, etc.)
}
```

### 1.4 Event Architecture

#### Extended Game Events
```dart
// Extend existing GameEventType enum
enum GameEventType {
  // Existing events
  moveExecuted,
  gameWon,
  gameLost,
  cardFlipped,
  stockDrawn,
  invalidMove,
  
  // New achievement-related events
  gameStarted,
  streakUpdated,
  undoUsed,
  hintUsed,
  autoCompleteTriggered,
  perfectGameAchieved,  // No undos, no hints
}
```

#### Achievement Observer Pattern
```dart
class AchievementObserver {
  final AchievementService _achievementService;
  StreamSubscription<GameEvent>? _subscription;
  
  void startObserving(Stream<GameEvent> gameEvents) {
    _subscription = gameEvents.listen(_handleGameEvent);
  }
  
  void _handleGameEvent(GameEvent event) {
    switch (event.type) {
      case GameEventType.gameWon:
        _achievementService.checkWinAchievements(event.data);
        break;
      case GameEventType.moveExecuted:
        _achievementService.incrementMoveCount();
        break;
      // ... handle other events
    }
  }
}
```

### 1.5 Achievement Definitions

Initial achievement set (stored in JSON and loaded at startup):

```json
{
  "achievements": [
    {
      "id": "first_win",
      "title": "First Victory",
      "description": "Win your first game",
      "icon": "assets/badges/first_win.svg",
      "category": "milestone",
      "targetValue": 1,
      "criteria": {"wins": 1}
    },
    {
      "id": "speed_demon",
      "title": "Speed Demon",
      "description": "Win a game in under 2 minutes",
      "icon": "assets/badges/speed.svg",
      "category": "speed",
      "criteria": {"maxTime": 120}
    },
    {
      "id": "efficiency_expert",
      "title": "Efficiency Expert",
      "description": "Win with fewer than 100 moves",
      "icon": "assets/badges/efficiency.svg",
      "category": "efficiency",
      "criteria": {"maxMoves": 100}
    },
    {
      "id": "streak_5",
      "title": "On Fire",
      "description": "Win 5 games in a row",
      "icon": "assets/badges/streak.svg",
      "category": "streak",
      "targetValue": 5
    },
    {
      "id": "perfect_game",
      "title": "Perfectionist",
      "description": "Win without using undo or hints",
      "icon": "assets/badges/perfect.svg",
      "category": "special"
    }
  ]
}
```

---

## 2. Autocomplete Heuristic & UI

### 2.1 Detection Algorithm

The autocomplete system will detect when a game is "effectively won" using these heuristics:

```dart
class AutoCompleteDetector {
  static bool canAutoComplete(GameInterface game) {
    // Check if all tableau cards are face up
    for (final pile in game.tableauPiles) {
      if (pile.cards.any((card) => !card.faceUp)) {
        return false;
      }
    }
    
    // Check if all remaining moves are trivial (to foundations)
    return _allMovesAreToFoundations(game);
  }
  
  static bool _allMovesAreToFoundations(GameInterface game) {
    // Simulate moving all cards to foundations
    // Return true if no conflicts exist
    return _simulateFoundationMoves(game);
  }
}
```

### 2.2 UI Components

#### Auto-Finish Button
```dart
class AutoFinishFAB extends StatelessWidget {
  final VoidCallback onPressed;
  final bool isVisible;
  
  @override
  Widget build(BuildContext context) {
    return AnimatedPositioned(
      duration: Duration(milliseconds: 300),
      bottom: isVisible ? 80 : -100,
      right: 16,
      child: FloatingActionButton.extended(
        onPressed: onPressed,
        icon: Icon(Icons.auto_awesome),
        label: Text('Auto Finish'),
        backgroundColor: AppColors.gold,
      ),
    );
  }
}
```

### 2.3 Integration Points

- Add `canAutoFinish` check to [`GameController._checkGameState()`](lib/services/game_controller.dart:679)
- Show FAB in [`GameScreen`](lib/screens/game_screen.dart) when condition is met
- Trigger rapid card animation sequence when activated

---

## 3. End Game Animation Overhaul

### 3.1 Architecture Changes

Replace the current `CustomPaint` approach with actual [`CardWidget`](lib/widgets/card_widget.dart) instances:

```dart
class WinAnimationV2 extends StatefulWidget {
  final List<Pile> foundationPiles;  // Access to actual cards
  final VoidCallback onComplete;
  
  @override
  State<WinAnimationV2> createState() => _WinAnimationV2State();
}

class _WinAnimationV2State extends State<WinAnimationV2> 
    with TickerProviderStateMixin {
  
  late List<AnimationController> _cardControllers;
  late List<Animation<Offset>> _positionAnimations;
  late List<Animation<double>> _rotationAnimations;
  
  @override
  void initState() {
    super.initState();
    _initializeCardAnimations();
    _startCascade();
  }
  
  void _initializeCardAnimations() {
    // Create staggered animations for each card
    final cards = _extractCardsFromFoundations();
    _cardControllers = [];
    
    for (int i = 0; i < cards.length; i++) {
      final controller = AnimationController(
        duration: Duration(milliseconds: 2000),
        vsync: this,
      );
      
      // Physics-based animation
      _positionAnimations.add(
        Tween<Offset>(
          begin: _getFoundationPosition(i),
          end: _getCascadeEndPosition(i),
        ).animate(CurvedAnimation(
          parent: controller,
          curve: Curves.bounceOut,
        )),
      );
      
      _cardControllers.add(controller);
    }
  }
  
  Widget _buildAnimatedCard(PlayingCard card, int index) {
    return AnimatedBuilder(
      animation: _cardControllers[index],
      builder: (context, child) {
        return Transform.translate(
          offset: _positionAnimations[index].value,
          child: Transform.rotate(
            angle: _rotationAnimations[index].value,
            child: CardWidget(
              card: card,
              width: 80,
              onTap: null,  // Disable interaction during animation
            ),
          ),
        );
      },
    );
  }
}
```

### 3.2 Animation Patterns

Implement multiple cascade patterns:

1. **Fountain Pattern**: Cards arc from foundations with physics simulation
2. **Cascade Pattern**: Cards fall with bounce effect
3. **Spiral Pattern**: Cards spiral outward from center
4. **Fireworks Pattern**: Cards explode outward then fall

### 3.3 Physics Simulation

```dart
class CardPhysics {
  static Path calculateTrajectory({
    required Offset start,
    required Offset end,
    required double gravity,
    required double initialVelocity,
  }) {
    // Calculate parabolic path for realistic motion
    final path = Path();
    path.moveTo(start.dx, start.dy);
    
    // Apply physics equations for projectile motion
    // ...
    
    return path;
  }
}
```

---

## 4. Implementation Plan

### Phase 1: Achievement System Foundation
1. Create Hive models and adapters
2. Implement [`AchievementService`](lib/achievements/services/achievement_service.dart)
3. Set up [`AchievementObserver`](lib/achievements/services/achievement_observer.dart)
4. Create achievement JSON definitions
5. Add achievement screen to settings

### Phase 2: Autocomplete Feature
1. Implement [`AutoCompleteDetector`](lib/services/autocomplete_detector.dart)
2. Add detection to [`GameController`](lib/services/game_controller.dart)
3. Create Auto-Finish FAB widget
4. Implement rapid card movement animation
5. Test with various game states

### Phase 3: Victory Animation
1. Extract cards from foundations
2. Create [`WinAnimationV2`](lib/widgets/win_animation_v2.dart) widget
3. Implement physics-based animations
4. Add multiple pattern variations
5. Replace existing [`WinAnimation`](lib/widgets/win_animation.dart)

### Phase 4: Integration & Testing
1. Wire up achievement unlocks
2. Add achievement notifications
3. Test autocomplete detection accuracy
4. Fine-tune animation timing
5. Performance optimization

---

## 5. Technical Considerations

### Performance
- Use `AnimatedList` for smooth achievement popup animations
- Limit concurrent card animations to prevent frame drops
- Cache achievement badge assets at startup

### State Management
- Achievements use separate `ChangeNotifier` provider
- Auto-complete state managed by existing [`GameController`](lib/services/game_controller.dart)
- Animation state is self-contained within widgets

### Persistence
- Achievements stored in separate Hive box: `achievements`
- Progress tracked in `achievement_progress` box
- Settings for enabling/disabling features in existing settings

### Testing Strategy
- Unit tests for achievement criteria evaluation
- Widget tests for UI components
- Integration tests for event flow
- Manual testing for animation smoothness

---

## 6. Future Enhancements

1. **Social Features**
   - Share achievements
   - Leaderboards
   - Challenge friends

2. **Advanced Achievements**
   - Daily challenges
   - Seasonal events
   - Hidden achievements

3. **Animation Customization**
   - User-selectable patterns
   - Speed controls
   - Disable animations option

4. **Statistics Integration**
   - Achievement completion percentage
   - Time to unlock tracking
   - Rarity indicators

---

## Appendix A: File Modifications Required

### Modified Files
- [`lib/main.dart`](lib/main.dart) - Initialize achievement system
- [`lib/models/game_event.dart`](lib/models/game_event.dart) - Add new event types
- [`lib/services/game_controller.dart`](lib/services/game_controller.dart) - Emit new events, auto-complete detection
- [`lib/screens/game_screen.dart`](lib/screens/game_screen.dart) - Add Auto-Finish FAB
- [`lib/screens/settings_screen.dart`](lib/screens/settings_screen.dart) - Add achievements section
- [`pubspec.yaml`](pubspec.yaml) - Ensure Hive generators are included

### New Files
- `lib/achievements/` - All achievement-related code
- `lib/widgets/win_animation_v2.dart` - New victory animation
- `lib/services/autocomplete_detector.dart` - Auto-complete logic
- `assets/badges/` - Achievement badge assets
- `assets/data/achievements.json` - Achievement definitions

---

## Appendix B: Dependencies

Current dependencies are sufficient. We already have:
- `hive_flutter: ^1.1.0` - For persistence
- `provider: ^6.1.2` - For state management
- Flutter's built-in animation framework

No additional packages required.