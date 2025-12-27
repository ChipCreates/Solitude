# Solitude Test Suite

Comprehensive unit tests for the Solitude solitaire game.

## Test Files

### Models Tests
Located in `test/models/`:

- **card_test.dart** (30 tests) - PlayingCard model tests
  - Card creation, properties, stacking rules, foundation rules

- **deck_test.dart** (19 tests) - Deck model tests
  - Deck creation, shuffling, drawing cards

- **pile_test.dart** (34 tests) - Pile model tests
  - Pile operations, card management, state tracking

- **move_test.dart** (12 tests) - Move model tests
  - Move recording, state tracking

### Game Logic Tests
Located in `test/games/`:

- **klondike_game_test.dart** (75 tests) - KlondikeGame tests
  - Game initialization, move validation, move execution
  - Undo system, stock handling, win/loss detection
  - Hint system, auto-complete

### Existing Tests
- **klondike_is_truly_lost_test.dart** (3 tests) - Loss detection edge cases
- **widget_test.dart** (1 test) - App smoke test

## Running Tests

```bash
# Run all tests
flutter test

# Run with verbose output
flutter test --reporter=expanded

# Run specific file
flutter test test/models/card_test.dart

# Run with coverage
flutter test --coverage
```

See [TESTING_GUIDE.md](../TESTING_GUIDE.md) for detailed testing instructions.

## Test Coverage

### TIER 1: Critical (100% Complete)
- PlayingCard: 30 tests
- Deck: 19 tests
- Pile: 34 tests
- Move: 12 tests
- KlondikeGame: 75 tests

**Total: 170 tests covering all core game logic**

### Future Tiers
- TIER 2: Services & State Management
- TIER 3: Utilities & Helpers
- TIER 4: Widget Tests
- TIER 5: Integration Tests

See [TEST_COVERAGE_SUMMARY.md](../TEST_COVERAGE_SUMMARY.md) for complete details.

## Test Organization

Tests follow Flutter best practices:
- Organized by functionality using `group()`
- Clear, descriptive test names
- Independent tests (no shared state)
- Both positive and negative test cases
- Edge case coverage

## Quick Reference

| File | Tests | Focus |
|------|-------|-------|
| card_test.dart | 30 | Card properties and validation |
| deck_test.dart | 19 | Deck operations |
| pile_test.dart | 34 | Pile management |
| move_test.dart | 12 | Move recording |
| klondike_game_test.dart | 75 | Game logic and rules |

## Contributing

When adding new tests:
1. Follow existing test structure
2. Use descriptive test names
3. Group related tests
4. Test both success and failure cases
5. Include edge cases
6. Keep tests independent

## Documentation

- **TESTING_GUIDE.md** - Comprehensive guide for running and writing tests
- **TEST_COVERAGE_SUMMARY.md** - Detailed test coverage breakdown
- **documents/Unit Test Plan.docx** - Original test plan document
