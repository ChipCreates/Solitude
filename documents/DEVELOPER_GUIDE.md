# Solitude - Developer Guide

Technical documentation for developers working on or extending Solitude.

## Table of Contents

1. [Project Overview](#project-overview)
2. [Technology Stack](#technology-stack)
3. [Getting Started](#getting-started)
4. [Project Structure](#project-structure)
5. [Core Architecture](#core-architecture)
6. [Data Models](#data-models)
7. [Services](#services)
8. [Game Logic](#game-logic)
9. [UI Components](#ui-components)
10. [Theme System](#theme-system)
11. [Audio System](#audio-system)
12. [Performance Optimizations](#performance-optimizations)
13. [Testing](#testing)
14. [Build and Deployment](#build-and-deployment)
15. [Contributing](#contributing)
16. [Code Style](#code-style)

---

## Project Overview

**Solitude** is a cross-platform Klondike solitaire game built with Flutter, designed to run on web, mobile (iOS/Android), and desktop (Windows/macOS/Linux) platforms.

**Key Stats:**
- ~8,492 lines of Dart code
- 39 source files
- Flutter SDK 3.x
- Material 3 design
- GPL-3.0 licensed

**Repository:** https://github.com/plotworx/solitude

---

## Technology Stack

### Core Framework
- **Flutter 3.x**: Cross-platform UI framework
- **Dart 3.x**: Programming language

### Key Dependencies

```yaml
dependencies:
  flutter_svg: ^2.0.9          # SVG rendering
  xml: ^6.5.0                  # SVG parsing and manipulation
  shared_preferences: ^2.2.2   # Local persistent storage
  provider: ^6.1.1             # State management
  collection: ^1.18.0          # Collection utilities
  audioplayers: ^6.1.0         # Audio playback

dev_dependencies:
  flutter_test:                # Testing framework
  flutter_lints: ^5.0.0        # Linting rules
```

### Asset Pipeline
- **SVG Cards**: 962KB single sprite sheet (htdebeer/SVG-cards)
- **Fonts**: Inter font family (48 files)
- **Audio**: 6 audio files (MP3 format)
- **Total Assets**: ~10MB

---

## Getting Started

### Prerequisites

1. **Flutter SDK**: Install from https://flutter.dev/docs/get-started/install
2. **Dart SDK**: Included with Flutter
3. **IDE**: VS Code, Android Studio, or IntelliJ IDEA
4. **Platform-specific tools**:
   - Android: Android Studio, SDK
   - iOS: Xcode, CocoaPods (macOS only)
   - Web: Chrome
   - Desktop: Platform-specific build tools

### Setup

```bash
# Clone the repository
git clone https://github.com/plotworx/solitude.git
cd solitude

# Install dependencies
flutter pub get

# Run on your preferred platform
flutter run -d chrome           # Web
flutter run -d linux            # Linux
flutter run -d android          # Android
flutter run -d ios              # iOS (macOS only)
flutter run -d windows          # Windows
flutter run -d macos            # macOS
```

### Development Mode

```bash
# Hot reload enabled
flutter run

# With specific device
flutter devices                 # List available devices
flutter run -d <device-id>

# Debug mode with verbose logging
flutter run --debug -v
```

---

## Project Structure

```
lib/
├── main.dart                              # App entry point
├── models/                                # Data models
│   ├── card.dart                          # PlayingCard, Suit, Rank
│   ├── deck.dart                          # Deck with shuffling
│   ├── pile.dart                          # Pile types (4 variants)
│   ├── move.dart                          # Move history
│   ├── difficulty.dart                    # Difficulty & ScoringMode enums
│   └── theme_preset.dart                  # Theme definitions
├── games/                                 # Game implementations
│   ├── game_interface.dart                # Abstract game interface
│   └── klondike/
│       └── klondike_game.dart             # Klondike rules & logic
├── services/                              # Business logic layer
│   ├── game_controller.dart               # Game state management
│   ├── settings_provider.dart             # Settings & theme management
│   ├── statistics_service.dart            # Statistics tracking
│   ├── audio_service.dart                 # Audio playback
│   ├── svg_preload_service.dart           # SVG asset preloading
│   ├── animation_state_notifier.dart      # Animation state
│   └── timer_state_notifier.dart          # Game timer
├── widgets/                               # Reusable UI components
│   ├── card_widget.dart                   # Card rendering
│   ├── svg_card_renderer.dart             # SVG extraction
│   ├── pile_widget.dart                   # Pile rendering
│   ├── game_board.dart                    # Main playing board
│   ├── game_toolbar.dart                  # Top toolbar
│   ├── theme_preview_cards.dart           # Theme preview cards
│   ├── win_animation.dart                 # Victory animation
│   ├── game_button.dart                   # Themed buttons
│   ├── game_toggle.dart                   # Toggle switches
│   ├── volume_slider.dart                 # Volume controls
│   ├── animated_card_overlay.dart         # Card animations
│   ├── focused_pile_wrapper.dart          # Keyboard focus
│   ├── pile_indicator.dart                # Pile highlights
│   └── card_gloss_painter.dart            # Visual effects
├── screens/                               # Full-screen views
│   ├── game_screen.dart                   # Main game UI
│   ├── settings_screen.dart               # Tabbed settings
│   ├── statistics_screen.dart             # Statistics display
│   ├── help_screen.dart                   # Help content
│   ├── about_screen.dart                  # License & credits
│   └── loading_splash_screen.dart         # Initial loading
├── utils/                                 # Utility functions
│   ├── overlay_validator.dart             # WCAG contrast validation
│   └── layout_calculator.dart             # Responsive layout
└── theme/
    └── app_theme.dart                     # Material 3 theme config
```

---

## Core Architecture

### State Management Pattern

Solitude uses the **Provider** pattern for state management:

```dart
// Main provider hierarchy (from main.dart)
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

### Key Design Principles

1. **Separation of Concerns**:
   - Models: Pure data classes
   - Services: Business logic and state
   - Widgets: UI presentation
   - Screens: Full-page compositions

2. **Single Responsibility**:
   - Each service handles one domain (settings, statistics, audio, etc.)
   - Specialized notifiers for animation and timer (performance optimization)

3. **Dependency Injection**:
   - Services injected via Provider
   - Access via `context.read<T>()` and `context.watch<T>()`

4. **Immutability Where Possible**:
   - Enums for constants
   - Final fields in models
   - Defensive copying for collections

---

## Data Models

### PlayingCard (`lib/models/card.dart`)

```dart
class PlayingCard {
  final Suit suit;
  final Rank rank;
  bool isFaceUp;

  // Color based on suit
  CardColor get color => (suit == Suit.hearts || suit == Suit.diamonds)
      ? CardColor.red
      : CardColor.black;

  // Unique identifier for each card
  String get id => '${suit.name}_${rank.name}';
}

enum Suit { hearts, diamonds, clubs, spades }
enum Rank { ace, two, three, ..., king }
enum CardColor { red, black }
```

### Pile (`lib/models/pile.dart`)

```dart
class Pile {
  final String id;
  final PileType type;
  final List<PlayingCard> cards;

  // Get only face-up cards
  List<PlayingCard> get faceUpCards;

  // Check if can accept a card
  bool canAcceptCard(PlayingCard card);
  bool canAcceptSequence(List<PlayingCard> cards);
}

enum PileType {
  stock,      // Draw pile
  waste,      // Discards from stock
  foundation, // Build ace to king by suit
  tableau,    // Main playing area (7 columns)
}
```

### Move (`lib/models/move.dart`)

```dart
class Move {
  final String fromPileId;
  final String toPileId;
  final List<PlayingCard> cards;
  final bool flippedCard;      // Did this move flip a card?
  final DateTime timestamp;

  // Reverse this move
  Move get inverse;
}
```

### ThemePreset (`lib/models/theme_preset.dart`)

```dart
class ThemePreset {
  final String id;
  final String name;
  final Color tableColor;
  final Color toolbarColor;
  final List<Color> accentColors;
  final Color? overlayTintColor;   // Optional card overlay
  final int defaultOverlayIntensity;
  final BlendMode overlayBlendMode;

  // 8 built-in themes
  static final List<ThemePreset> builtInThemes;
}
```

---

## Services

### GameController (`lib/services/game_controller.dart`)

**Responsibilities:**
- Game state management
- Move execution and validation
- Undo/redo functionality
- Autoplay loop
- Win/loss detection
- Integration with statistics

**Key Methods:**

```dart
class GameController extends ChangeNotifier {
  KlondikeGame? game;

  // Game lifecycle
  void newGame({Difficulty? difficulty, ScoringMode? mode});
  void resetGame();

  // Move execution
  bool executeMove(String fromPileId, String toPileId, List<PlayingCard> cards);
  void undoLastMove();

  // Autoplay
  void toggleAutoplay();
  Future<void> _autoplayLoop();

  // Helpers
  Move? getHint();
  bool isGameWon();
  bool isGameLost();
  void autoComplete();
}
```

### SettingsProvider (`lib/services/settings_provider.dart`)

**Responsibilities:**
- Settings persistence (SharedPreferences)
- Theme management
- Card customization
- Audio preferences
- Gameplay options

**Key Methods:**

```dart
class SettingsProvider extends ChangeNotifier {
  // Theme
  ThemePreset selectedTheme;
  void selectTheme(ThemePreset theme);

  // Overlay
  int getOverlayIntensity(String themeId);
  void setOverlayIntensity(String themeId, int intensity);

  // Card appearance
  String selectedCardBack;
  void setCardBack(String backType);

  // Gameplay
  Difficulty difficulty;
  ScoringMode scoringMode;
  bool autoCompleteEnabled;
  bool inactivityHintsEnabled;

  // Audio
  bool soundEnabled;
  double soundVolume;
  bool musicEnabled;
  double musicVolume;

  // Persistence
  Future<void> loadSettings();
  Future<void> saveSettings();
}
```

### StatisticsService (`lib/services/statistics_service.dart`)

**Responsibilities:**
- Track game outcomes
- Calculate win rates and streaks
- Persist statistics
- Separate tracking for Standard vs Vegas mode

**Key Methods:**

```dart
class StatisticsService extends ChangeNotifier {
  // Recording outcomes
  void recordWin({int? moves, Duration? time, int? score});
  void recordLoss();

  // Standard mode stats
  int gamesPlayed;
  int gamesWon;
  double get winPercentage;
  int currentStreak;
  int bestStreak;
  int? bestTime;
  int? fewestMoves;

  // Vegas mode stats
  int totalWinnings;
  int highScore;

  // Management
  void resetStatistics();
  Future<void> loadStatistics();
}
```

### AudioService (`lib/services/audio_service.dart`)

**Responsibilities:**
- Play sound effects
- Background music management
- Volume control
- Audio caching

**Key Methods:**

```dart
class AudioService {
  // Sound effects
  Future<void> playCardFlip();
  Future<void> playCardPlace();
  Future<void> playCardShuffle();
  Future<void> playError();
  Future<void> playSuccess();

  // Background music
  Future<void> playBackgroundMusic();
  Future<void> stopBackgroundMusic();

  // Volume
  void setSoundVolume(double volume);
  void setMusicVolume(double volume);

  // Lifecycle
  void dispose();
}
```

### SvgPreloadService (`lib/services/svg_preload_service.dart`)

**Responsibilities:**
- Parse SVG sprite sheet on startup
- Build element cache for O(1) lookups
- Preload all card SVGs
- Eliminate runtime parsing jank

**Key Methods:**

```dart
class SvgPreloadService {
  // Initialization
  static Future<void> preloadSvgCards();

  // Access
  static XmlDocument? get svgDocument;
  static Map<String, XmlElement> get elementCache;

  // Cache status
  static bool get isPreloaded;
}
```

---

## Game Logic

### KlondikeGame (`lib/games/klondike/klondike_game.dart`)

**Core game implementation:**

```dart
class KlondikeGame implements GameInterface {
  // Piles
  Pile stock;
  Pile waste;
  List<Pile> foundations;  // 4 piles (one per suit)
  List<Pile> tableaus;     // 7 piles

  // Configuration
  Difficulty difficulty;
  ScoringMode scoringMode;

  // State
  List<Move> moveHistory;
  int stockRecycles;
  int score;

  // Game logic
  void dealCards();
  bool isValidMove(Pile from, Pile to, List<PlayingCard> cards);
  void executeMove(Move move);
  void undoMove(Move move);

  // Helper methods
  Move? getHint();
  bool isWon();
  bool isLost();
  List<Move> getPossibleMoves();
}
```

### Hint System

**Priority order:**

1. **Foundation moves** (always beneficial):
   ```dart
   // Check waste and tableau cards that can move to foundations
   ```

2. **Expose face-down cards**:
   ```dart
   // Moves that flip tableau cards
   ```

3. **Waste to tableau**:
   ```dart
   // Bring new cards into play
   ```

4. **Tableau consolidation**:
   ```dart
   // Move between tableau piles (prefer non-empty destinations)
   ```

### Loss Detection

**Algorithm:**

```dart
bool isLost() {
  // 1. Stock must be exhausted
  if (stock.cards.isNotEmpty) return false;

  // 2. No waste card can move anywhere
  if (waste.cards.isNotEmpty) {
    if (_canMoveToFoundation(waste.topCard)) return false;
    if (_canMoveToAnyTableau(waste.topCard)) return false;
  }

  // 3. No tableau moves that expose cards
  for (var tableau in tableaus) {
    if (_hasProgressiveMove(tableau)) return false;
  }

  return true;
}
```

### Autoplay Logic

**Flow:**

```dart
Future<void> _autoplayLoop() {
  while (autoplayEnabled && !isGameOver) {
    final hint = game.getHint();

    if (hint == null) {
      // No moves available - game is lost
      break;
    }

    // Execute the hint
    executeMove(hint);

    // Detect oscillation (repeated moves)
    if (_detectOscillation()) {
      _switchStrategy();
    }

    await Future.delayed(Duration(milliseconds: 300));
  }
}
```

---

## UI Components

### CardWidget (`lib/widgets/card_widget.dart`)

**Renders individual playing cards with overlay support:**

```dart
class CardWidget extends StatelessWidget {
  final PlayingCard card;
  final double width;
  final double height;
  final VoidCallback? onTap;

  // Overlay support
  final Color? overlayColor;
  final int overlayIntensity;  // 0-100

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SvgCardRenderer(
        card: card,
        width: width,
        height: height,
        overlayColor: overlayColor,
        overlayIntensity: overlayIntensity,
      ),
    );
  }
}
```

### SvgCardRenderer (`lib/widgets/svg_card_renderer.dart`)

**Extracts and renders cards from sprite sheet:**

```dart
class SvgCardRenderer extends StatelessWidget {
  // SVG extraction logic
  String _extractCardSvg(PlayingCard card) {
    final svgDoc = SvgPreloadService.svgDocument;
    final cache = SvgPreloadService.elementCache;

    // Find card element
    final cardId = _getCardElementId(card);
    final cardElement = cache[cardId];

    // Clone and inline referenced elements (gradients, patterns)
    final inlinedElement = _inlineReferences(cardElement);

    // Apply overlay if specified
    if (overlayColor != null && overlayIntensity > 0) {
      _applyOverlay(inlinedElement);
    }

    return inlinedElement.toXmlString();
  }

  // Cache per-card SVG strings
  static final Map<String, String> _svgCache = {};
}
```

### GameBoard (`lib/widgets/game_board.dart`)

**Main playing surface:**

```dart
class GameBoard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final game = context.watch<GameController>().game;
    final theme = context.watch<SettingsProvider>().selectedTheme;

    return Container(
      color: theme.tableColor,
      child: Column(
        children: [
          // Top row: Stock, Waste, Foundations
          _buildTopRow(),

          // Bottom: 7 Tableau piles
          _buildTableauRow(),
        ],
      ),
    );
  }
}
```

### ThemePreviewCards (`lib/widgets/theme_preview_cards.dart`)

**Live card previews for theme selection:**

```dart
class ThemePreviewCards extends StatelessWidget {
  final ThemePreset theme;
  final int overlayIntensity;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Red card (hearts)
        _buildPreviewCard(Suit.hearts, Rank.king),

        // Black card (spades)
        _buildPreviewCard(Suit.spades, Rank.ace),
      ],
    );
  }
}
```

---

## Theme System

### Theme Architecture

**Components:**

1. **ThemePreset** (model): Defines colors and overlay settings
2. **SettingsProvider** (service): Manages theme selection and overlay intensity
3. **UI Components**: Consume theme from provider and apply dynamically

### Adding a New Theme

```dart
// 1. Define in ThemePreset.builtInThemes
ThemePreset(
  id: 'my_theme',
  name: 'My Theme',
  tableColor: Color(0xFF123456),
  toolbarColor: Color(0xFF654321),
  accentColors: [
    Color(0xFFAABBCC),
    Color(0xFFDDEEFF),
    // ... up to 5 colors
  ],
  overlayTintColor: Color(0x80FFFFFF),  // Optional
  defaultOverlayIntensity: 30,
  overlayBlendMode: BlendMode.modulate,
),

// 2. Add to theme selector UI (settings_screen.dart)
// Preview cards automatically generated

// 3. Theme is now selectable and persisted
```

### Overlay System

**How overlays work:**

1. **Tint Color**: Each theme specifies an overlay color
2. **Intensity**: User adjusts 0-100% opacity
3. **Blend Mode**: `modulate` or `multiply` for different effects
4. **Validation**: WCAG 3:1 contrast ratio enforced
5. **Per-theme Memory**: Each theme remembers its own intensity

**Implementation:**

```dart
// In SvgCardRenderer
if (overlayColor != null && overlayIntensity > 0) {
  final opacity = overlayIntensity / 100.0;
  final overlayRect = XmlElement(XmlName('rect'), [
    XmlAttribute(XmlName('width'), '100%'),
    XmlAttribute(XmlName('height'), '100%'),
    XmlAttribute(XmlName('fill'), _colorToHex(overlayColor)),
    XmlAttribute(XmlName('opacity'), opacity.toString()),
    XmlAttribute(XmlName('style'), 'mix-blend-mode: $blendMode'),
  ]);

  cardElement.children.add(overlayRect);
}
```

### Overlay Validation

**WCAG Contrast Checker:**

```dart
// lib/utils/overlay_validator.dart
class OverlayValidator {
  static const double MIN_CONTRAST_RATIO = 3.0;

  static bool isLegible({
    required Color baseColor,
    required Color overlayColor,
    required int intensity,
  }) {
    // Simulate blending
    final resultColor = _blendColors(baseColor, overlayColor, intensity);

    // Calculate contrast with white (card background)
    final contrast = _calculateContrast(resultColor, Colors.white);

    return contrast >= MIN_CONTRAST_RATIO;
  }

  static int findMaxLegibleIntensity(Color base, Color overlay) {
    // Binary search for highest intensity that maintains legibility
    int low = 0, high = 100;
    int result = 0;

    while (low <= high) {
      int mid = (low + high) ~/ 2;
      if (isLegible(baseColor: base, overlayColor: overlay, intensity: mid)) {
        result = mid;
        low = mid + 1;
      } else {
        high = mid - 1;
      }
    }

    return result;
  }
}
```

---

## Audio System

### Audio Architecture

**Service-based with caching:**

```dart
class AudioService {
  final Map<String, AudioPlayer> _players = {};
  final Map<String, AudioCache> _cache = {};

  // Initialize players
  void _initializePlayers() {
    _players['flip'] = AudioPlayer();
    _players['place'] = AudioPlayer();
    // ... etc
  }

  // Play with volume
  Future<void> playSound(String soundName, double volume) async {
    final player = _players[soundName];
    await player.setVolume(volume);
    await player.play(AssetSource('audio/$soundName.mp3'));
  }
}
```

### Audio Files

Located in `assets/audio/`:
- `card_flip.mp3`: Card turning over
- `card_place.mp3`: Card placement
- `card_shuffle.mp3`: Deck shuffling
- `error.mp3`: Invalid move
- `success.mp3`: Game won
- `background-music.mp3`: Ambient loop (2.4MB)

---

## Performance Optimizations

### SVG Preloading

**Problem**: Parsing large SVG sprite sheet on every card render causes jank.

**Solution**: Preload and cache at startup.

```dart
// During splash screen (5 second minimum)
await SvgPreloadService.preloadSvgCards();

// Result: O(1) element lookups, cached SVG strings
```

### Separate Notifiers

**Problem**: Animation and timer updates cause unnecessary rebuilds of game state consumers.

**Solution**: Split into specialized notifiers.

```dart
// Instead of one large GameController
AnimationStateNotifier  // Only animation consumers rebuild
TimerStateNotifier      // Only timer display rebuilds
GameController          // Only for actual game state changes
```

### SVG Caching

**Per-card SVG cache:**

```dart
static final Map<String, String> _svgCache = {};

String _getCardSvg(PlayingCard card) {
  final cacheKey = '${card.id}_${overlayIntensity}';

  if (_svgCache.containsKey(cacheKey)) {
    return _svgCache[cacheKey]!;
  }

  final svg = _extractAndRenderSvg(card);
  _svgCache[cacheKey] = svg;
  return svg;
}
```

### Layout Calculations

**Responsive sizing:**

```dart
// lib/utils/layout_calculator.dart
class LayoutCalculator {
  static Size calculateCardSize(BoxConstraints constraints) {
    // Dynamic sizing based on screen size
    // Maintains aspect ratio
    // Considers portrait vs landscape
  }

  static EdgeInsets calculateSpacing(Size cardSize) {
    // Proportional spacing
  }
}
```

---

## Testing

### Current Test Coverage

Located in `test/`:
- Limited coverage (2 test files)
- Opportunity for expansion

### Running Tests

```bash
# Run all tests
flutter test

# Run specific test file
flutter test test/models/card_test.dart

# With coverage
flutter test --coverage

# View coverage report
genhtml coverage/lcov.info -o coverage/html
open coverage/html/index.html
```

### Test Structure (Recommended)

```dart
// test/models/card_test.dart
void main() {
  group('PlayingCard', () {
    test('should determine color correctly', () {
      final heartCard = PlayingCard(suit: Suit.hearts, rank: Rank.ace);
      expect(heartCard.color, CardColor.red);

      final spadeCard = PlayingCard(suit: Suit.spades, rank: Rank.king);
      expect(spadeCard.color, CardColor.black);
    });
  });
}

// test/games/klondike_test.dart
void main() {
  group('KlondikeGame', () {
    test('should deal cards correctly', () {
      final game = KlondikeGame();
      game.dealCards();

      expect(game.tableaus.length, 7);
      expect(game.tableaus[0].cards.length, 1);
      expect(game.tableaus[6].cards.length, 7);
    });

    test('should detect wins', () {
      final game = KlondikeGame();
      // ... move all cards to foundations
      expect(game.isWon(), true);
    });
  });
}
```

### Testing Best Practices

1. **Unit tests** for models and game logic
2. **Widget tests** for UI components
3. **Integration tests** for full game flows
4. **Mock** external dependencies (audio, storage)
5. **Test edge cases** (empty piles, invalid moves, etc.)

---

## Build and Deployment

See [BUILDING.md](BUILDING.md) for comprehensive build instructions.

### Quick Reference

```bash
# Development builds
flutter run -d <platform>

# Release builds
flutter build web --release
flutter build apk --release
flutter build appbundle --release
flutter build ios --release
flutter build windows --release
flutter build macos --release
flutter build linux --release

# Analyze code
flutter analyze

# Format code
dart format lib/
```

---

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for contribution guidelines.

### Development Workflow

1. **Fork** the repository
2. **Create** a feature branch: `git checkout -b feature/my-feature`
3. **Make** changes following code style guidelines
4. **Test** your changes thoroughly
5. **Commit** with clear messages: `git commit -m "Add: new feature"`
6. **Push** to your fork: `git push origin feature/my-feature`
7. **Submit** a pull request

### Code Review Checklist

- [ ] Code follows Dart style guidelines
- [ ] No new linting warnings
- [ ] Tests added for new functionality
- [ ] Documentation updated
- [ ] Commit messages are clear
- [ ] No breaking changes (or clearly documented)

---

## Code Style

### Dart Conventions

Follow official Dart style guide: https://dart.dev/guides/language/effective-dart

**Key points:**

```dart
// 1. Use trailing commas for better diffs
Widget build(BuildContext context) {
  return Container(
    child: Text('Hello'),  // <- trailing comma
  );
}

// 2. Prefer const constructors
const Text('Static text');

// 3. Use meaningful names
final selectedTheme = provider.selectedTheme;  // Good
final st = provider.st;                         // Bad

// 4. Document public APIs
/// Calculates the optimal card size for the given constraints.
///
/// Returns a [Size] that maintains the standard playing card aspect
/// ratio (2.5:3.5) while fitting within [constraints].
Size calculateCardSize(BoxConstraints constraints) { ... }

// 5. Use enums for constants
enum Difficulty { easy, medium, hard }  // Good
class Difficulty { static const easy = 0; }  // Bad
```

### File Organization

```dart
// 1. Imports first (Dart style, then package, then relative)
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/card.dart';
import '../services/game_controller.dart';

// 2. Class declaration
class MyWidget extends StatelessWidget {
  // 3. Fields (const, final, then mutable)
  static const double defaultSize = 100.0;
  final String title;

  // 4. Constructor
  const MyWidget({required this.title, Key? key}) : super(key: key);

  // 5. Overrides
  @override
  Widget build(BuildContext context) { ... }

  // 6. Public methods
  void doSomething() { ... }

  // 7. Private methods
  void _helperMethod() { ... }
}
```

### Naming Conventions

- **Classes**: `PascalCase` (e.g., `GameController`, `PlayingCard`)
- **Files**: `snake_case` (e.g., `game_controller.dart`)
- **Variables/Methods**: `camelCase` (e.g., `selectedTheme`, `calculateSize`)
- **Constants**: `lowerCamelCase` (e.g., `defaultWidth`)
- **Private members**: `_leadingUnderscore` (e.g., `_helperMethod`)
- **Enums**: `camelCase` values (e.g., `Difficulty.easy`)

---

## Debugging Tips

### Flutter DevTools

```bash
# Launch DevTools
flutter pub global activate devtools
flutter pub global run devtools

# Run app in debug mode with DevTools
flutter run --debug
```

**Useful panels:**
- **Inspector**: Widget tree visualization
- **Timeline**: Performance profiling
- **Memory**: Heap analysis
- **Network**: HTTP request monitoring (if applicable)

### Common Issues

**Issue: Cards not rendering**
- Check that `SvgPreloadService.preloadSvgCards()` was called
- Verify asset paths in `pubspec.yaml`
- Check console for SVG parsing errors

**Issue: Settings not persisting**
- Ensure `SharedPreferences` has write permissions
- Check that `await` is used on save operations
- Verify no exceptions in console

**Issue: Audio not playing**
- Confirm audio files exist in `assets/audio/`
- Check platform-specific audio permissions
- Verify `audioplayers` plugin is installed

**Issue: Performance lag**
- Profile with DevTools timeline
- Check for excessive rebuilds (use `const` constructors)
- Verify SVG cache is working

### Logging

```dart
// Use debugPrint for development logs
debugPrint('Game state: ${game.isWon()}');

// Conditional logging
assert(() {
  debugPrint('Debug-only log');
  return true;
}());
```

---

## Architecture Decisions

### Why Provider Over Other State Management?

- **Simplicity**: Easy to understand and use
- **Performance**: Granular rebuilds with context.watch/read
- **Flutter Integration**: Official recommendation for simple apps
- **No boilerplate**: Minimal setup compared to BLoC or Redux

### Why SVG Over PNG?

- **Scalability**: Perfect rendering at any resolution
- **File Size**: 962KB for entire deck vs multiple PNGs
- **Single Asset**: One sprite sheet for all cards
- **Customization**: Easy to apply overlays and tints

### Why Separate Animation/Timer Notifiers?

- **Performance**: Prevents game state rebuilds on every tick
- **Separation of Concerns**: Animation state is presentation logic
- **Optimization**: Only animation consumers rebuild

### Why SharedPreferences Over SQLite?

- **Simplicity**: Settings are key-value pairs
- **Performance**: Fast reads/writes for small data
- **Cross-platform**: Works everywhere Flutter runs
- **No Setup**: No schema migrations or queries

---

## Future Development

### Planned Features (from README)

1. **Additional Game Modes**:
   - Spider Solitaire
   - FreeCell

2. **Theme Enhancements**:
   - Custom theme creation
   - Theme import/export (JSON)
   - Community theme gallery
   - Background textures/images
   - Seasonal themes

3. **Accessibility**:
   - Screen reader support
   - High contrast mode improvements
   - Larger touch targets option

4. **Customization**:
   - Font selection
   - Animation speed control
   - More card back designs

### Technical Debt

1. **Test Coverage**: Expand from 2 test files to comprehensive suite
2. **Documentation**: Add more inline comments for complex algorithms
3. **Accessibility**: ARIA labels, semantic markup
4. **Localization**: i18n support for multiple languages

---

## Additional Resources

- **Flutter Documentation**: https://flutter.dev/docs
- **Dart Documentation**: https://dart.dev/guides
- **Provider Package**: https://pub.dev/packages/provider
- **SVG Cards Source**: https://github.com/htdebeer/SVG-cards
- **Material 3 Design**: https://m3.material.io/

---

## Support

For issues, questions, or contributions:

- **GitHub Issues**: https://github.com/plotworx/solitude/issues
- **Discussions**: https://github.com/plotworx/solitude/discussions
- **Pull Requests**: https://github.com/plotworx/solitude/pulls

---

**Happy coding!**

Version 1.0.0
