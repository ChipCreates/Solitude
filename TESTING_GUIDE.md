# Testing Guide for Solitude

## Quick Start

### Run All Tests
```bash
flutter test
```

### Run Tests with Verbose Output
```bash
flutter test --reporter=expanded
```

### Run Tests with Coverage
```bash
flutter test --coverage
```

## Running Specific Test Files

### Model Tests
```bash
# PlayingCard tests
flutter test test/models/card_test.dart

# Deck tests
flutter test test/models/deck_test.dart

# Pile tests
flutter test test/models/pile_test.dart

# Move tests
flutter test test/models/move_test.dart
```

### Game Logic Tests
```bash
# KlondikeGame tests
flutter test test/games/klondike_game_test.dart

# Loss detection tests (existing)
flutter test test/klondike_is_truly_lost_test.dart
```

### Widget Tests
```bash
# Smoke test (existing)
flutter test test/widget_test.dart
```

## Running Specific Test Groups

You can run specific test groups by using the `--name` flag:

```bash
# Run only PlayingCard creation tests
flutter test test/models/card_test.dart --name "PlayingCard Creation"

# Run only move validation tests
flutter test test/games/klondike_game_test.dart --name "Move Validation"

# Run only undo tests
flutter test test/games/klondike_game_test.dart --name "Undo"
```

## Watching Tests (Auto-rerun on Changes)

```bash
flutter test --watch
```

## Generating Coverage Reports

### 1. Run Tests with Coverage
```bash
flutter test --coverage
```

### 2. Generate HTML Report (requires lcov)
```bash
# Install lcov if not already installed
# macOS: brew install lcov
# Ubuntu/Debian: sudo apt-get install lcov

# Generate HTML report
genhtml coverage/lcov.info -o coverage/html
```

### 3. View Report
```bash
# macOS
open coverage/html/index.html

# Linux
xdg-open coverage/html/index.html

# Windows
start coverage/html/index.html
```

## Test File Structure

```
test/
├── models/                      # Model unit tests
│   ├── card_test.dart          # PlayingCard tests (30 tests)
│   ├── deck_test.dart          # Deck tests (19 tests)
│   ├── pile_test.dart          # Pile tests (34 tests)
│   └── move_test.dart          # Move tests (12 tests)
├── games/                       # Game logic tests
│   └── klondike_game_test.dart # KlondikeGame tests (75 tests)
├── klondike_is_truly_lost_test.dart  # Loss detection (3 tests)
└── widget_test.dart            # Widget smoke test (1 test)
```

## Test Categories

### 1. Model Tests (95 tests)
Focus on individual data models and their methods:
- Card properties and validation
- Deck shuffling and drawing
- Pile operations
- Move recording

### 2. Game Logic Tests (75 tests)
Focus on game rules and mechanics:
- Game initialization
- Move validation
- Move execution
- Undo/redo
- Stock handling
- Win/loss detection
- Hint system
- Auto-complete

### 3. Widget Tests (1 test)
Focus on UI components:
- Smoke test for app initialization

## Debugging Failed Tests

### Run Single Test with Debug Output
```bash
flutter test test/models/card_test.dart --name "specific test name" --reporter=expanded
```

### Add Debug Prints in Tests
```dart
test('my test', () {
  final card = PlayingCard(suit: Suit.hearts, rank: Rank.ace);
  print('Card created: $card'); // Add debug output
  expect(card.value, 1);
});
```

### Run Tests in Debug Mode
```bash
flutter test --debug
```

## Test Best Practices

### ✅ DO
- Write descriptive test names that explain what is being tested
- Use `group()` to organize related tests
- Test both positive and negative cases
- Test edge cases (null, empty, boundary values)
- Keep tests independent (no shared state)
- Use clear, specific assertions

### ❌ DON'T
- Share state between tests
- Test implementation details (test behavior, not internals)
- Write tests that depend on execution order
- Use magic numbers without explanation
- Skip edge cases

## Common Test Patterns

### Testing Equality
```dart
test('cards with same suit and rank are equal', () {
  final card1 = PlayingCard(suit: Suit.hearts, rank: Rank.ace);
  final card2 = PlayingCard(suit: Suit.hearts, rank: Rank.ace);

  expect(card1, equals(card2));
});
```

### Testing Exceptions
```dart
test('throws exception for invalid input', () {
  expect(
    () => someFunction(invalidInput),
    throwsA(isA<ArgumentError>()),
  );
});
```

### Testing Lists
```dart
test('list contains expected items', () {
  final list = [1, 2, 3];

  expect(list, hasLength(3));
  expect(list, contains(2));
  expect(list, containsAll([1, 3]));
});
```

### Testing State Changes
```dart
test('move increments counter', () {
  final game = KlondikeGame();
  game.initialize();

  final countBefore = game.moveCount;
  // ... perform move ...
  final countAfter = game.moveCount;

  expect(countAfter, countBefore + 1);
});
```

## Continuous Integration

### GitHub Actions Example
```yaml
name: Tests

on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest

    steps:
    - uses: actions/checkout@v2
    - uses: subosito/flutter-action@v2
      with:
        flutter-version: '3.x'
    - run: flutter pub get
    - run: flutter test --coverage
    - uses: codecov/codecov-action@v2
      with:
        files: ./coverage/lcov.info
```

## Test Coverage Goals

### Current Coverage (TIER 1)
- ✅ PlayingCard: 100%
- ✅ Deck: 100%
- ✅ Pile: 100%
- ✅ Move: 100%
- ✅ KlondikeGame: ~95% (core logic)

### Target Coverage
- Models: 100%
- Game Logic: 95%+
- Services: 90%+
- Widgets: 80%+
- Overall: 85%+

## Troubleshooting

### Tests Fail After Code Changes
1. Run `flutter clean`
2. Run `flutter pub get`
3. Run tests again

### Coverage Report Not Generated
1. Ensure you're using `--coverage` flag
2. Check that `coverage` directory exists
3. Verify lcov is installed for HTML reports

### Tests Run Slowly
1. Use `--concurrency=6` to run more tests in parallel
2. Run specific test files instead of all tests
3. Consider splitting large test files

### Import Errors
1. Verify all dependencies in `pubspec.yaml`
2. Run `flutter pub get`
3. Check that file paths in imports are correct

## Additional Resources

- [Flutter Testing Documentation](https://docs.flutter.dev/testing)
- [Effective Dart: Testing](https://dart.dev/guides/language/effective-dart/testing)
- [Flutter Test Package](https://api.flutter.dev/flutter/flutter_test/flutter_test-library.html)

## Quick Reference

| Command | Description |
|---------|-------------|
| `flutter test` | Run all tests |
| `flutter test <file>` | Run specific test file |
| `flutter test --name <pattern>` | Run tests matching name pattern |
| `flutter test --coverage` | Run tests with coverage |
| `flutter test --reporter=expanded` | Verbose test output |
| `flutter test --watch` | Auto-rerun on changes |
| `flutter test --debug` | Run in debug mode |
| `flutter test --help` | Show all test options |
