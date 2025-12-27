# Solitude - Architecture Documentation

Comprehensive system design and architecture documentation for Solitude.

## Table of Contents

1. [System Overview](#system-overview)
2. [Architecture Principles](#architecture-principles)
3. [Layered Architecture](#layered-architecture)
4. [State Management](#state-management)
5. [Data Flow](#data-flow)
6. [Core Subsystems](#core-subsystems)
7. [Design Patterns](#design-patterns)
8. [Performance Architecture](#performance-architecture)
9. [Security and Privacy](#security-and-privacy)
10. [Scalability and Extensibility](#scalability-and-extensibility)
11. [Technology Decisions](#technology-decisions)

---

## System Overview

### High-Level Architecture

Solitude follows a **layered architecture** with clear separation of concerns:

```
┌─────────────────────────────────────────────────────────────┐
│                      Presentation Layer                      │
│  (Screens, Widgets, UI Components, Theme Management)         │
└───────────────────────────┬─────────────────────────────────┘
                            │
┌───────────────────────────▼─────────────────────────────────┐
│                     Business Logic Layer                     │
│    (Services, Controllers, Game Logic, State Management)     │
└───────────────────────────┬─────────────────────────────────┘
                            │
┌───────────────────────────▼─────────────────────────────────┐
│                         Data Layer                           │
│         (Models, Persistence, Asset Management)              │
└─────────────────────────────────────────────────────────────┘
```

### Key Characteristics

- **Platform-agnostic:** Single codebase for 6+ platforms
- **Offline-first:** No network dependency
- **Privacy-preserving:** All data stored locally
- **Reactive:** UI updates automatically based on state changes
- **Modular:** Loosely coupled components
- **Testable:** Clear boundaries for unit/widget testing

---

## Architecture Principles

### 1. Separation of Concerns

**Definition:** Each module has a single, well-defined responsibility.

**Implementation:**
- **Models:** Data structures only, no business logic
- **Services:** Business logic and state, no UI
- **Widgets:** UI presentation, minimal logic
- **Screens:** Composition of widgets, no business logic

**Example:**
```dart
// ❌ BAD: UI mixed with business logic
class CardWidget extends StatefulWidget {
  @override
  Widget build(BuildContext context) {
    final game = KlondikeGame();  // Business logic in UI
    game.dealCards();
    return ...;
  }
}

// ✅ GOOD: Clear separation
class CardWidget extends StatelessWidget {
  final PlayingCard card;  // Data passed in

  @override
  Widget build(BuildContext context) {
    // UI only, consumes data
    return SvgCardRenderer(card: card);
  }
}
```

### 2. Dependency Inversion

**Definition:** Depend on abstractions, not concretions.

**Implementation:**
- `GameInterface` abstract class for game implementations
- Provider pattern for dependency injection
- Services accessed via interfaces, not direct instantiation

**Example:**
```dart
// Abstract interface
abstract class GameInterface {
  void dealCards();
  bool isValidMove(Move move);
  Move? getHint();
}

// Concrete implementation
class KlondikeGame implements GameInterface {
  @override
  void dealCards() { /* Implementation */ }
  // ...
}

// Usage via dependency injection
final game = context.read<GameController>().game;  // Interface
```

### 3. Single Source of Truth

**Definition:** Each piece of data has exactly one authoritative source.

**Implementation:**
- Game state lives in `GameController`
- Settings live in `SettingsProvider`
- Statistics live in `StatisticsService`
- UI reads from these sources, never maintains its own copies

**Example:**
```dart
// ✅ GOOD: Single source
class GameBoard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final game = context.watch<GameController>().game;  // Read from source
    return TableauWidget(piles: game.tableaus);
  }
}

// ❌ BAD: Duplicate state
class GameBoard extends StatefulWidget {
  List<Pile> _localTableaus;  // Duplicate of game state!
}
```

### 4. Reactive Programming

**Definition:** UI reacts automatically to state changes.

**Implementation:**
- `ChangeNotifier` for observable state
- `context.watch<T>()` for reactive rebuilds
- Granular notifiers to minimize rebuild scope

**Example:**
```dart
class GameController extends ChangeNotifier {
  void executeMove(Move move) {
    game.executeMove(move);
    notifyListeners();  // UI automatically updates
  }
}

// Widget rebuilds automatically
class ScoreDisplay extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final score = context.watch<GameController>().game.score;
    return Text('Score: $score');
  }
}
```

### 5. Immutability Where Possible

**Definition:** Prefer immutable data structures.

**Implementation:**
- `final` fields in models
- `const` constructors for widgets
- Enums for type-safe constants
- Defensive copying when needed

**Example:**
```dart
class PlayingCard {
  final Suit suit;        // Immutable
  final Rank rank;        // Immutable
  bool isFaceUp;          // Mutable only when necessary

  const PlayingCard({
    required this.suit,
    required this.rank,
    this.isFaceUp = false,
  });
}
```

---

## Layered Architecture

### Layer 1: Data Layer

**Responsibilities:**
- Define data structures
- Persistence (SharedPreferences)
- Asset management
- Constants and enums

**Components:**
```
models/
├── card.dart           # PlayingCard, Suit, Rank, CardColor
├── deck.dart           # Deck with shuffling
├── pile.dart           # Pile, PileType
├── move.dart           # Move history
├── difficulty.dart     # Difficulty, ScoringMode enums
└── theme_preset.dart   # ThemePreset definitions
```

**Key Principles:**
- Pure data classes (PODOs - Plain Old Dart Objects)
- No business logic
- No dependencies on upper layers
- Serializable (for persistence)

### Layer 2: Business Logic Layer

**Responsibilities:**
- Game rules and logic
- State management
- Business operations
- External service integration (audio, storage)

**Components:**
```
services/
├── game_controller.dart           # Game state & orchestration
├── settings_provider.dart         # Settings & theme management
├── statistics_service.dart        # Statistics tracking
├── audio_service.dart             # Audio playback
├── svg_preload_service.dart       # Asset preloading
├── animation_state_notifier.dart  # Animation state
└── timer_state_notifier.dart      # Timer state

games/
├── game_interface.dart            # Abstract game contract
└── klondike/
    └── klondike_game.dart         # Klondike implementation
```

**Key Principles:**
- Services are singletons (via Provider)
- Each service has single responsibility
- Services communicate via well-defined APIs
- Stateful (ChangeNotifier)

### Layer 3: Presentation Layer

**Responsibilities:**
- UI rendering
- User interaction handling
- Theme application
- Responsive layout

**Components:**
```
screens/               # Full-screen views
├── game_screen.dart
├── settings_screen.dart
├── loading_splash_screen.dart
└── ...

widgets/               # Reusable components
├── card_widget.dart
├── pile_widget.dart
├── game_board.dart
├── game_toolbar.dart
└── ...

theme/                 # Visual styling
└── app_theme.dart
```

**Key Principles:**
- Stateless widgets preferred
- Minimal logic (presentation only)
- Consume state via `context.watch/read`
- Responsive and accessible

---

## State Management

### Provider Pattern

**Why Provider?**
- Official Flutter recommendation
- Simple to understand and use
- Excellent performance with granular rebuilds
- No boilerplate compared to BLoC/Redux
- Built-in dependency injection

### Provider Hierarchy

```dart
MultiProvider(
  providers: [
    ChangeNotifierProvider(create: (_) => SettingsProvider()),
    ChangeNotifierProvider(create: (_) => StatisticsService()),
    ChangeNotifierProvider(create: (_) => GameController()),
    ChangeNotifierProvider(create: (_) => AnimationStateNotifier()),
    ChangeNotifierProvider(create: (_) => TimerStateNotifier()),
  ],
  child: MyApp(),
)
```

### State Scopes

**Global State:**
- `SettingsProvider`: Theme, preferences, audio settings
- `StatisticsService`: Game statistics across sessions

**Game State:**
- `GameController`: Current game state, moves, score
- `TimerStateNotifier`: Game timer

**Transient State:**
- `AnimationStateNotifier`: Card animations
- Widget-local state (StatefulWidget) for trivial UI state

### Rebuild Optimization

**Problem:** Every state change rebuilds all consumers.

**Solution:** Granular notifiers and selective watching.

```dart
// ❌ BAD: Timer updates rebuild entire game
class GameController extends ChangeNotifier {
  int elapsedSeconds = 0;  // Changes every second!

  void incrementTimer() {
    elapsedSeconds++;
    notifyListeners();  // Everything rebuilds!
  }
}

// ✅ GOOD: Separate notifier for timer
class TimerStateNotifier extends ChangeNotifier {
  int elapsedSeconds = 0;  // Isolated

  void increment() {
    elapsedSeconds++;
    notifyListeners();  // Only timer display rebuilds
  }
}

// Widget selectively watches only what it needs
class TimerDisplay extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final seconds = context.watch<TimerStateNotifier>().elapsedSeconds;
    return Text('Time: $seconds');
  }
}

class GameBoard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Doesn't watch TimerStateNotifier, so doesn't rebuild on timer changes
    final game = context.watch<GameController>().game;
    return ...;
  }
}
```

---

## Data Flow

### Unidirectional Data Flow

```
User Interaction (tap, click, keyboard)
         │
         ▼
    Widget (UI)
         │
         │ calls method
         ▼
  Service/Controller (Business Logic)
         │
         │ updates state
         ▼
    notifyListeners()
         │
         │ triggers rebuild
         ▼
    Widget (UI) rebuilds with new state
```

### Example: Moving a Card

```dart
// 1. User taps card
CardWidget(
  onTap: () {
    // 2. Widget calls controller method
    context.read<GameController>().executeMove(
      fromPileId: 'tableau_0',
      toPileId: 'foundation_0',
      cards: [selectedCard],
    );
  },
)

// 3. Controller updates game state
class GameController extends ChangeNotifier {
  void executeMove(String from, String to, List<PlayingCard> cards) {
    if (game.isValidMove(...)) {
      game.executeMove(...);  // Update model
      _statistics.recordMove();
      notifyListeners();      // Notify UI
    }
  }
}

// 4. UI rebuilds automatically
class GameBoard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final game = context.watch<GameController>().game;  // Rebuilds here
    return PileWidget(pile: game.foundations[0]);
  }
}
```

### Persistence Flow

```
User changes setting
         │
         ▼
  SettingsProvider updates in-memory state
         │
         ├─ notifyListeners() ──→ UI updates immediately
         │
         └─ saveSettings() ──→ SharedPreferences (async)
```

**Read flow:**

```
App startup
         │
         ▼
  SettingsProvider.loadSettings()
         │
         │ read from SharedPreferences
         ▼
  In-memory state populated
         │
         │ notifyListeners()
         ▼
  UI builds with loaded settings
```

---

## Core Subsystems

### 1. Game Engine

**Architecture:**

```
GameController (orchestration)
      │
      ├─ KlondikeGame (rules & logic)
      │     ├─ Piles (stock, waste, foundations, tableaus)
      │     ├─ Deck (card collection)
      │     └─ Move history
      │
      ├─ Hint system
      ├─ Loss detection
      └─ Autoplay AI
```

**Hint System Design:**

```dart
class KlondikeGame {
  Move? getHint() {
    // Priority 1: Foundation moves (always beneficial)
    final foundationMove = _findFoundationMove();
    if (foundationMove != null) return foundationMove;

    // Priority 2: Expose face-down cards
    final exposeMove = _findExposeMove();
    if (exposeMove != null) return exposeMove;

    // Priority 3: Waste to tableau (new cards into play)
    final wasteMove = _findWasteToTableauMove();
    if (wasteMove != null) return wasteMove;

    // Priority 4: Tableau consolidation
    return _findTableauMove();
  }
}
```

**Loss Detection Algorithm:**

```dart
bool isLost() {
  // Stock exhausted?
  if (stock.cards.isNotEmpty) return false;

  // Waste card playable?
  if (waste.cards.isNotEmpty && _isWasteCardPlayable()) {
    return false;
  }

  // Any progressive tableau moves?
  for (var tableau in tableaus) {
    if (_hasProgressiveMove(tableau)) {
      return false;
    }
  }

  // No moves available - game is lost
  return true;
}

bool _hasProgressiveMove(Pile tableau) {
  // Progressive = exposes face-down cards or moves to foundation
  // NOT progressive = shuffling Kings between empty columns

  if (tableau.cards.isEmpty) return false;

  final topSequence = tableau.faceUpCards;
  for (var destination in tableaus) {
    if (_canMoveToTableau(topSequence, destination)) {
      // Check if move is progressive
      if (tableau.cards.length > topSequence.length) {
        // Exposes a face-down card - progressive!
        return true;
      }
    }
  }

  // Check foundation moves
  return _canMoveToFoundation(topSequence.first);
}
```

### 2. Theme System

**Architecture:**

```
ThemePreset (data model)
      │
      ├─ Base colors (table, toolbar)
      ├─ Accent colors (5 custom colors)
      └─ Overlay settings (tint, intensity, blend mode)

SettingsProvider (management)
      │
      ├─ Theme selection
      ├─ Per-theme overlay intensity
      └─ Persistence

UI Components (application)
      │
      ├─ GameBoard (table color)
      ├─ GameToolbar (toolbar color)
      ├─ CardWidget (overlay rendering)
      └─ ThemePreviewCards (preview)
```

**Overlay Rendering Pipeline:**

```
1. CardWidget receives overlay parameters
         │
         ▼
2. SvgCardRenderer extracts card from sprite sheet
         │
         ▼
3. Apply overlay:
   - Create <rect> element with overlay color
   - Set opacity = intensity / 100
   - Set blend mode (modulate/multiply)
   - Append to card SVG
         │
         ▼
4. Validate legibility (WCAG contrast)
         │
         ▼
5. Render to screen
```

**Overlay Validation:**

```dart
class OverlayValidator {
  static bool isLegible({
    required Color baseColor,  // Red or black suit color
    required Color overlayColor,
    required int intensity,
  }) {
    // 1. Simulate color blending
    final blended = _blendColors(baseColor, overlayColor, intensity);

    // 2. Calculate contrast ratio with white background
    final contrast = _contrastRatio(blended, Colors.white);

    // 3. Check against WCAG AA standard (3:1 for large text)
    return contrast >= 3.0;
  }

  static double _contrastRatio(Color c1, Color c2) {
    final l1 = _relativeLuminance(c1);
    final l2 = _relativeLuminance(c2);
    final lighter = max(l1, l2);
    final darker = min(l1, l2);
    return (lighter + 0.05) / (darker + 0.05);
  }
}
```

### 3. SVG Rendering System

**Architecture:**

```
SvgPreloadService (initialization)
      │
      ├─ Load sprite sheet at startup
      ├─ Parse XML document
      └─ Build element cache (O(1) lookup)

SvgCardRenderer (extraction)
      │
      ├─ Find card element by ID
      ├─ Clone and inline referenced elements
      ├─ Apply overlay (if specified)
      └─ Convert to standalone SVG string

Cache Layer (performance)
      │
      └─ Per-card, per-overlay-intensity caching
```

**Element Inlining:**

SVG cards reference shared gradients and patterns:

```xml
<defs>
  <linearGradient id="grad1">...</linearGradient>
</defs>

<g id="heart_ace">
  <rect fill="url(#grad1)"/>  <!-- Reference -->
</g>
```

To create standalone card SVGs, we inline these references:

```dart
XmlElement _inlineReferences(XmlElement cardElement) {
  final cloned = cardElement.copy();

  // Find all url(#id) references
  final references = _findReferences(cloned);

  // For each reference, find the element and inline it
  for (var ref in references) {
    final referencedElement = _elementCache[ref];
    if (referencedElement != null) {
      // Add to card's <defs>
      _addToLocalDefs(cloned, referencedElement);
    }
  }

  return cloned;
}
```

### 4. Audio System

**Architecture:**

```
AudioService (singleton)
      │
      ├─ Sound effects (6 audio files)
      │     ├─ Individual AudioPlayer instances
      │     └─ Volume control per effect
      │
      └─ Background music
            ├─ Dedicated AudioPlayer
            ├─ Looping enabled
            └─ Separate volume control
```

**Lazy Initialization:**

```dart
class AudioService {
  final Map<String, AudioPlayer> _players = {};

  Future<void> playSound(String name, double volume) async {
    // Lazy create player
    _players[name] ??= AudioPlayer();

    final player = _players[name]!;
    await player.setVolume(volume);
    await player.play(AssetSource('audio/$name.mp3'));
  }

  @override
  void dispose() {
    // Clean up all players
    for (var player in _players.values) {
      player.dispose();
    }
  }
}
```

### 5. Statistics System

**Architecture:**

```
StatisticsService (tracking & persistence)
      │
      ├─ In-memory counters
      ├─ Calculation methods (win %, streaks)
      └─ SharedPreferences persistence

GameController (integration)
      │
      └─ Calls statistics methods on game events
            ├─ recordWin(moves, time, score)
            └─ recordLoss()
```

**Dual-mode Tracking:**

```dart
class StatisticsService extends ChangeNotifier {
  // Standard mode
  int standardGamesPlayed = 0;
  int standardGamesWon = 0;
  int? standardBestTime;
  int? standardFewestMoves;

  // Vegas mode
  int vegasGamesPlayed = 0;
  int vegasTotalWinnings = 0;
  int vegasHighScore = 0;

  // Shared stats
  int currentStreak = 0;
  int bestStreak = 0;

  void recordWin({int? moves, Duration? time, int? score}) {
    if (scoringMode == ScoringMode.standard) {
      standardGamesWon++;
      if (time != null && (standardBestTime == null || time < standardBestTime!)) {
        standardBestTime = time;
      }
      // ... update fewest moves
    } else {
      vegasTotalWinnings += score ?? 0;
      vegasHighScore = max(vegasHighScore, score ?? 0);
    }

    currentStreak++;
    bestStreak = max(bestStreak, currentStreak);

    notifyListeners();
    _saveToStorage();
  }
}
```

---

## Design Patterns

### 1. Provider (Dependency Injection)

**Pattern:** Service Locator / Dependency Injection

**Usage:** State management and service access

```dart
// Registration
MultiProvider(
  providers: [
    ChangeNotifierProvider(create: (_) => GameController()),
  ],
  child: App(),
)

// Access
final controller = context.read<GameController>();  // One-time read
final game = context.watch<GameController>().game;  // Reactive watch
```

### 2. Observer (ChangeNotifier)

**Pattern:** Observer

**Usage:** Reactive state updates

```dart
class GameController extends ChangeNotifier {
  void updateState() {
    // Modify state
    notifyListeners();  // Notify observers
  }
}

// Observer
class MyWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    context.watch<GameController>();  // Register as observer
    return ...;  // Rebuilds when notified
  }
}
```

### 3. Strategy (Game Interface)

**Pattern:** Strategy

**Usage:** Pluggable game implementations

```dart
abstract class GameInterface {
  void dealCards();
  bool isValidMove(Move move);
  Move? getHint();
}

class KlondikeGame implements GameInterface { ... }
class SpiderGame implements GameInterface { ... }  // Future

// Usage
GameInterface game = difficulty == spider ? SpiderGame() : KlondikeGame();
```

### 4. Singleton (Services)

**Pattern:** Singleton (via Provider)

**Usage:** Single instance of services

```dart
// Provider ensures single instance
ChangeNotifierProvider(create: (_) => AudioService())

// Accessed anywhere
context.read<AudioService>().playSound('flip');
```

### 5. Factory (Card Creation)

**Pattern:** Factory

**Usage:** Deck initialization

```dart
class Deck {
  static Deck createStandard52() {
    final cards = <PlayingCard>[];
    for (var suit in Suit.values) {
      for (var rank in Rank.values) {
        cards.add(PlayingCard(suit: suit, rank: rank));
      }
    }
    return Deck(cards);
  }
}
```

### 6. Memento (Undo System)

**Pattern:** Memento

**Usage:** Move history and undo

```dart
class Move {
  final String fromPileId;
  final String toPileId;
  final List<PlayingCard> cards;
  final bool flippedCard;

  // Inverse for undo
  Move get inverse => Move(
    fromPileId: toPileId,
    toPileId: fromPileId,
    cards: cards,
    flippedCard: flippedCard,
  );
}

class GameController {
  final List<Move> _moveHistory = [];

  void executeMove(Move move) {
    _moveHistory.add(move);
    // Execute move
  }

  void undo() {
    if (_moveHistory.isEmpty) return;
    final lastMove = _moveHistory.removeLast();
    // Execute inverse
  }
}
```

### 7. Template Method (Game Flow)

**Pattern:** Template Method

**Usage:** Common game lifecycle

```dart
abstract class GameInterface {
  // Template method
  void startNewGame() {
    resetState();
    dealCards();
    startTimer();
  }

  // Abstract steps
  void resetState();
  void dealCards();
  void startTimer();
}
```

---

## Performance Architecture

### 1. SVG Preloading

**Problem:** Parsing 962KB SVG on every render causes jank.

**Solution:** Parse once at startup, cache lookups.

```
Startup:
  ├─ Parse SVG sprite sheet (5 seconds during splash)
  ├─ Build element cache (HashMap: id → XmlElement)
  └─ Mark as preloaded

Runtime:
  ├─ O(1) element lookup
  ├─ Cache extracted SVG strings
  └─ No parsing overhead
```

### 2. Granular Notifiers

**Problem:** Timer updates every second, causing full game rebuild.

**Solution:** Separate notifiers for different update frequencies.

```
GameController (changes rarely)
  └─ Game state, moves, score

TimerStateNotifier (changes every second)
  └─ Elapsed time

AnimationStateNotifier (changes during animations)
  └─ Animating cards
```

**Impact:**
- Timer updates: Only timer display rebuilds
- Game moves: Only game board rebuilds
- Animations: Only animated cards rebuild

### 3. Const Constructors

**Optimization:** Widgets that don't change use `const`.

```dart
const Text('New Game')  // Never rebuilds
const SizedBox(height: 16)  // Reused
const Icon(Icons.settings)  // Cached
```

### 4. Lazy Loading

**Audio files:** Loaded on first play, not at startup
**Settings:** Loaded asynchronously during splash
**SVG per-card cache:** Populated on-demand

### 5. Build Method Optimization

```dart
// ✅ GOOD: Minimal rebuilds
class CardWidget extends StatelessWidget {
  final PlayingCard card;

  @override
  Widget build(BuildContext context) {
    // No context.watch - doesn't rebuild unnecessarily
    return SvgCardRenderer(card: card);
  }
}

// ❌ BAD: Rebuilds on every provider change
class CardWidget extends StatelessWidget {
  final PlayingCard card;

  @override
  Widget build(BuildContext context) {
    context.watch<GameController>();  // Watches entire controller!
    return SvgCardRenderer(card: card);
  }
}
```

---

## Security and Privacy

### Privacy-First Design

**Principles:**
1. **No network access:** Zero telemetry, analytics, or tracking
2. **Local storage only:** All data stays on device
3. **No accounts:** No user identification
4. **No permissions:** No camera, location, contacts, etc.

### Data Storage

**What is stored:**
- Game settings (theme, difficulty, audio preferences)
- Statistics (games played, win rate, etc.)

**Where:**
- `SharedPreferences` (platform-specific local storage)
  - Linux: `~/.local/share/<app>/shared_preferences.json`
  - Windows: Registry
  - macOS: `~/Library/Preferences/<bundle_id>.plist`
  - Android: `/data/data/<package>/shared_prefs/`
  - iOS: `NSUserDefaults`
  - Web: localStorage

**Security:**
- No sensitive data stored
- No passwords or personal information
- All data is non-identifiable

### License Compliance

**GPL-3.0 obligations:**
- Source code available: ✅
- License included: ✅
- Third-party attributions: ✅
- Modification tracking: ✅ (git history)

**Third-party licenses:**
- SVG cards: LGPL-2.1+ (attributed)
- Inter font: OFL-1.1 (attributed)
- Flutter packages: MIT/BSD (attributed)

---

## Scalability and Extensibility

### Adding New Game Modes

**Steps:**

1. **Implement GameInterface:**
   ```dart
   class SpiderGame implements GameInterface {
     @override
     void dealCards() { ... }
     @override
     bool isValidMove(Move move) { ... }
     @override
     Move? getHint() { ... }
   }
   ```

2. **Add to GameController:**
   ```dart
   GameInterface _createGame(GameMode mode) {
     switch (mode) {
       case GameMode.klondike: return KlondikeGame();
       case GameMode.spider: return SpiderGame();
     }
   }
   ```

3. **Update UI:**
   - Add game mode selector
   - Adjust layout if needed

**Impact:** Minimal changes, well-isolated.

### Adding New Themes

**Steps:**

1. **Define ThemePreset:**
   ```dart
   ThemePreset(
     id: 'my_theme',
     name: 'My Theme',
     tableColor: Color(0xFF...),
     // ... other colors
   ),
   ```

2. **Add to built-in list:**
   ```dart
   static final builtInThemes = [
     classicFelt,
     royalBlue,
     myTheme,  // New theme
   ];
   ```

**Impact:** Automatic UI updates, persistence, preview.

### Adding New Statistics

**Steps:**

1. **Add field to StatisticsService:**
   ```dart
   int newStat = 0;
   ```

2. **Update recording methods:**
   ```dart
   void recordWin() {
     newStat++;
     // ...
   }
   ```

3. **Add persistence:**
   ```dart
   Future<void> _save() async {
     await _prefs.setInt('new_stat', newStat);
   }

   Future<void> _load() async {
     newStat = _prefs.getInt('new_stat') ?? 0;
   }
   ```

4. **Display in UI:**
   ```dart
   Text('New Stat: ${stats.newStat}')
   ```

### Plugin Architecture (Future)

**Potential for:**
- Custom themes (JSON import)
- Custom card decks
- Custom rule variations
- Community extensions

---

## Technology Decisions

### Why Flutter?

**Pros:**
- ✅ True cross-platform (6+ platforms, one codebase)
- ✅ Excellent performance (compiled to native)
- ✅ Hot reload (fast development)
- ✅ Rich widget library
- ✅ Strong ecosystem
- ✅ Material 3 support

**Cons:**
- ❌ Large app size (~20MB+ after compression)
- ❌ Learning curve for Dart
- ❌ Web bundle size larger than pure JS

**Verdict:** Benefits outweigh drawbacks for this use case.

### Why Provider Over BLoC/Redux?

**Comparison:**

| Feature | Provider | BLoC | Redux |
|---------|----------|------|-------|
| Learning curve | Low | Medium | High |
| Boilerplate | Minimal | Medium | High |
| Performance | Excellent | Excellent | Good |
| Testing | Easy | Easy | Medium |
| Community | Large | Large | Medium |

**Decision:** Provider is sufficient for this app's complexity.

### Why SVG Over PNG?

**Comparison:**

| Aspect | SVG | PNG |
|--------|-----|-----|
| Scalability | ✅ Perfect at any size | ❌ Pixelated when scaled |
| File size | ✅ 962KB for all cards | ❌ ~3MB+ for multiple resolutions |
| Customization | ✅ Easy overlay tinting | ❌ Requires image processing |
| Performance | ⚠️ Parse overhead | ✅ Fast to decode |

**Decision:** SVG with preloading eliminates parse overhead while maintaining benefits.

### Why SharedPreferences Over SQLite?

**Comparison:**

| Aspect | SharedPreferences | SQLite |
|--------|-------------------|--------|
| Complexity | ✅ Simple key-value | ❌ Schema, queries |
| Data size | ✅ Small (~1KB) | ⚠️ Overkill for small data |
| Cross-platform | ✅ Built-in | ⚠️ Platform differences |
| Performance | ✅ Fast | ✅ Fast |

**Decision:** Settings and stats are simple key-value data, SQLite is overkill.

---

## Diagrams

### System Context Diagram

```
┌─────────────────────────────────────────────────────┐
│                                                     │
│                      Solitude                       │
│                                                     │
│  ┌─────────────┐  ┌─────────────┐  ┌────────────┐ │
│  │   Game      │  │   Theme     │  │  Settings  │ │
│  │   Engine    │  │   System    │  │  Manager   │ │
│  └─────────────┘  └─────────────┘  └────────────┘ │
│                                                     │
│  ┌─────────────┐  ┌─────────────┐  ┌────────────┐ │
│  │  Hint AI    │  │   Audio     │  │ Statistics │ │
│  │             │  │   Player    │  │  Tracker   │ │
│  └─────────────┘  └─────────────┘  └────────────┘ │
│                                                     │
└─────────────────────────────────────────────────────┘
             │                          │
             ▼                          ▼
    ┌────────────────┐         ┌─────────────────┐
    │ Local Storage  │         │  Audio Assets   │
    │ (Preferences)  │         │  (MP3 files)    │
    └────────────────┘         └─────────────────┘
```

### Component Interaction Diagram

```
┌──────────┐     ┌───────────────┐     ┌──────────┐
│   User   │────▶│  UI Widget    │────▶│ Service  │
└──────────┘     └───────────────┘     └──────────┘
                         ▲                    │
                         │                    │
                         │   notifyListeners  │
                         │                    ▼
                         │              ┌──────────┐
                         └──────────────│  Model   │
                                        └──────────┘
```

---

## Conclusion

Solitude's architecture prioritizes:
1. **Simplicity:** Easy to understand and maintain
2. **Performance:** Optimized for smooth 60fps gameplay
3. **Privacy:** All data stays local
4. **Extensibility:** Easy to add features
5. **Testability:** Clear boundaries for testing

The layered architecture with Provider state management provides a solid foundation for current features and future enhancements.

---

**Version 1.0.0**
