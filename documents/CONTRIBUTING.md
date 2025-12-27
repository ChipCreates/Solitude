# Contributing to Solitude

Thank you for considering contributing to Solitude! This document provides guidelines and information for contributors.

## Table of Contents

1. [Code of Conduct](#code-of-conduct)
2. [How Can I Contribute?](#how-can-i-contribute)
3. [Getting Started](#getting-started)
4. [Development Workflow](#development-workflow)
5. [Coding Standards](#coding-standards)
6. [Commit Message Guidelines](#commit-message-guidelines)
7. [Pull Request Process](#pull-request-process)
8. [Testing Guidelines](#testing-guidelines)
9. [Documentation](#documentation)
10. [Community](#community)

---

## Code of Conduct

### Our Pledge

We are committed to providing a welcoming and inclusive environment for everyone, regardless of:
- Experience level
- Gender identity and expression
- Sexual orientation
- Disability
- Personal appearance
- Body size
- Race or ethnicity
- Age
- Religion
- Nationality

### Our Standards

**Positive behavior includes:**
- Using welcoming and inclusive language
- Respecting differing viewpoints and experiences
- Gracefully accepting constructive criticism
- Focusing on what is best for the community
- Showing empathy towards others

**Unacceptable behavior includes:**
- Harassment, trolling, or discriminatory comments
- Personal or political attacks
- Publishing others' private information
- Other conduct inappropriate in a professional setting

### Enforcement

Project maintainers have the right to remove, edit, or reject comments, commits, code, issues, and other contributions that do not align with this Code of Conduct.

---

## How Can I Contribute?

### Reporting Bugs

**Before submitting a bug report:**
1. Check the [existing issues](https://github.com/plotworx/solitude/issues) to avoid duplicates
2. Verify you're using the latest version
3. Try to reproduce the bug consistently

**Bug report should include:**
- Clear, descriptive title
- Steps to reproduce the issue
- Expected behavior vs actual behavior
- Screenshots (if applicable)
- Environment details:
  - Platform (Web, Android, iOS, Windows, macOS, Linux)
  - Device/browser information
  - App version
- Error messages or console logs

**Example bug report:**
```markdown
### Bug: Cards not rendering on Firefox 120

**Description:**
Cards appear as blank white rectangles on Firefox 120.0 (Linux).

**Steps to reproduce:**
1. Open Solitude in Firefox 120.0
2. Start a new game
3. Observe the game board

**Expected:** Cards display with proper graphics
**Actual:** All cards are blank white rectangles

**Environment:**
- Platform: Web
- Browser: Firefox 120.0
- OS: Ubuntu 22.04
- Version: 1.0.0

**Console errors:**
```
Error parsing SVG: ...
```

**Screenshots:** [attached]
```

### Suggesting Features

**Before suggesting a feature:**
1. Check if it's already in the [planned features](../README.md#future-enhancements)
2. Search existing feature requests
3. Consider if it aligns with the project's goals

**Feature request should include:**
- Clear, descriptive title
- Detailed description of the feature
- Use cases and benefits
- Potential implementation approach (optional)
- Mockups or examples (optional)

**Example feature request:**
```markdown
### Feature: Undo All button

**Description:**
Add a button to undo all moves and return to the initial deal.

**Use case:**
Players often want to restart with the same deal to try different
strategies without starting a completely new game.

**Proposed implementation:**
- Add "Undo All" button next to existing "Undo" button
- Keep track of initial game state
- Reset to initial state when clicked

**Alternatives considered:**
- "Restart Deal" menu option
- Keyboard shortcut (Ctrl+Shift+Z)
```

### Improving Documentation

Documentation improvements are always welcome:
- Fix typos, grammar, or clarity
- Add missing information
- Improve examples
- Translate to other languages (future)
- Add screenshots or diagrams

### Contributing Code

See [Development Workflow](#development-workflow) below.

---

## Getting Started

### Prerequisites

1. **Install Flutter:**
   - Follow [official Flutter installation guide](https://flutter.dev/docs/get-started/install)
   - Verify: `flutter doctor`

2. **Install Git:**
   - Download from [git-scm.com](https://git-scm.com/)
   - Configure: `git config --global user.name "Your Name"`
   - Configure: `git config --global user.email "your.email@example.com"`

3. **Choose an IDE:**
   - VS Code (recommended): Install Flutter extension
   - Android Studio: Install Flutter plugin
   - IntelliJ IDEA: Install Flutter plugin

### Fork and Clone

1. **Fork the repository:**
   - Go to https://github.com/plotworx/solitude
   - Click "Fork" button
   - Select your account

2. **Clone your fork:**
   ```bash
   git clone https://github.com/YOUR_USERNAME/solitude.git
   cd solitude
   ```

3. **Add upstream remote:**
   ```bash
   git remote add upstream https://github.com/plotworx/solitude.git
   git remote -v  # Verify remotes
   ```

4. **Install dependencies:**
   ```bash
   flutter pub get
   ```

5. **Verify setup:**
   ```bash
   flutter run -d chrome
   ```

---

## Development Workflow

### Creating a Feature Branch

```bash
# Update your fork
git checkout main
git fetch upstream
git merge upstream/main
git push origin main

# Create feature branch
git checkout -b feature/your-feature-name
```

**Branch naming conventions:**
- `feature/description` - New features
- `fix/description` - Bug fixes
- `docs/description` - Documentation changes
- `refactor/description` - Code refactoring
- `test/description` - Test additions/changes
- `chore/description` - Maintenance tasks

### Making Changes

1. **Write code** following [Coding Standards](#coding-standards)
2. **Test thoroughly** on relevant platforms
3. **Add/update tests** for new functionality
4. **Update documentation** if behavior changes
5. **Commit changes** following [Commit Message Guidelines](#commit-message-guidelines)

### Syncing with Upstream

Keep your branch up-to-date:

```bash
git fetch upstream
git rebase upstream/main
```

If conflicts occur:
```bash
# Fix conflicts in files
git add <resolved-files>
git rebase --continue
```

### Running Tests

```bash
# Run all tests
flutter test

# Run specific test file
flutter test test/models/card_test.dart

# Run with coverage
flutter test --coverage

# View coverage report
genhtml coverage/lcov.info -o coverage/html
open coverage/html/index.html
```

### Code Analysis

```bash
# Analyze code for issues
flutter analyze

# Format code
dart format lib/

# Check formatting without changes
dart format --output=none --set-exit-if-changed lib/
```

---

## Coding Standards

### Dart Style Guide

Follow the [official Dart style guide](https://dart.dev/guides/language/effective-dart).

**Key principles:**

#### 1. Naming Conventions

```dart
// Classes: PascalCase
class GameController extends ChangeNotifier { }

// Files: snake_case
// game_controller.dart

// Variables and methods: camelCase
final selectedTheme = provider.selectedTheme;
void calculateCardSize() { }

// Constants: lowerCamelCase
const double defaultCardWidth = 100.0;

// Private members: _leadingUnderscore
void _helperMethod() { }
final _privateField = 'value';

// Enums: camelCase values
enum Difficulty { easy, medium, hard }
```

#### 2. Code Formatting

```dart
// Use trailing commas for better diffs
Widget build(BuildContext context) {
  return Container(
    padding: EdgeInsets.all(8.0),
    child: Text('Hello'),  // <- Trailing comma
  );
}

// Prefer const constructors
const Text('Static text');
const SizedBox(height: 16);

// Avoid unnecessary braces for single expressions
if (isValid) return true;  // Good
if (isValid) {             // Unnecessary
  return true;
}

// Use => for simple functions
bool get isWon => foundations.every((f) => f.cards.length == 13);
```

#### 3. Documentation

```dart
/// Calculates the optimal card size for the given constraints.
///
/// This method maintains the standard playing card aspect ratio (2.5:3.5)
/// while ensuring the cards fit within the provided [constraints].
///
/// Returns a [Size] representing the card dimensions in logical pixels.
///
/// Example:
/// ```dart
/// final size = calculateCardSize(constraints);
/// final card = CardWidget(width: size.width, height: size.height);
/// ```
Size calculateCardSize(BoxConstraints constraints) {
  // Implementation
}

// Use /// for public APIs
// Use // for implementation comments
// Use /* */ for multi-line explanations
```

#### 4. Code Organization

```dart
// File structure
import 'dart:async';  // Dart imports first

import 'package:flutter/material.dart';  // Flutter/package imports
import 'package:provider/provider.dart';

import '../models/card.dart';  // Relative imports last
import '../services/game_controller.dart';

// Class structure
class MyWidget extends StatelessWidget {
  // 1. Static constants
  static const double defaultSize = 100.0;

  // 2. Final fields
  final String title;
  final VoidCallback? onTap;

  // 3. Constructor
  const MyWidget({
    required this.title,
    this.onTap,
    Key? key,
  }) : super(key: key);

  // 4. Overrides
  @override
  Widget build(BuildContext context) { }

  // 5. Public methods
  void doSomething() { }

  // 6. Private methods
  void _helper() { }
}
```

#### 5. Best Practices

```dart
// Prefer final over var
final name = 'Alice';  // Good
var name = 'Alice';    // Avoid if not reassigned

// Use type annotations for clarity when not obvious
final String userName = getUserName();  // Good when clarity helps
final userName = getUserName();         // OK if type is obvious

// Avoid unnecessary nullable types
String getName() => 'Alice';     // Good
String? getName() => 'Alice';    // Unnecessary ?

// Use null-aware operators
final length = name?.length ?? 0;  // Good
final length = name != null ? name.length : 0;  // Verbose

// Prefer async/await over futures
Future<void> loadData() async {
  final data = await fetchData();  // Good
}

Future<void> loadData() {
  return fetchData().then((data) { });  // Less readable
}

// Use collection if for conditional elements
final items = [
  'Always',
  if (showExtra) 'Extra',  // Good
];

final items = [
  'Always',
  ...(showExtra ? ['Extra'] : []),  // Verbose
];
```

---

## Commit Message Guidelines

### Format

```
<type>(<scope>): <subject>

<body>

<footer>
```

### Type

- **feat**: New feature
- **fix**: Bug fix
- **docs**: Documentation changes
- **style**: Formatting, missing semicolons, etc. (no code change)
- **refactor**: Code change that neither fixes a bug nor adds a feature
- **perf**: Performance improvement
- **test**: Adding or updating tests
- **chore**: Maintenance tasks, dependency updates

### Scope (optional)

Component affected: `game`, `ui`, `theme`, `audio`, `settings`, etc.

### Subject

- Use imperative mood: "Add feature" not "Added feature"
- Don't capitalize first letter
- No period at the end
- Limit to 50 characters

### Body (optional)

- Explain what and why, not how
- Wrap at 72 characters
- Separate from subject with blank line

### Footer (optional)

- Reference issues: `Closes #123`
- Breaking changes: `BREAKING CHANGE: description`

### Examples

**Simple:**
```
fix(game): prevent null error when undoing first move
```

**With body:**
```
feat(theme): add Plum Royale theme

Add elegant purple theme with gold accents. Includes custom
overlay tint color and WCAG-validated intensity settings.

Closes #45
```

**Breaking change:**
```
refactor(settings)!: change theme API structure

BREAKING CHANGE: ThemePreset now requires overlayBlendMode.
Update any custom themes to include this field.

Migration:
- Add `overlayBlendMode: BlendMode.modulate` to theme definitions
```

---

## Pull Request Process

### Before Submitting

**Checklist:**
- [ ] Code follows style guidelines
- [ ] All tests pass (`flutter test`)
- [ ] No linting errors (`flutter analyze`)
- [ ] Code is formatted (`dart format lib/`)
- [ ] New tests added for new features
- [ ] Documentation updated
- [ ] Commit messages follow guidelines
- [ ] Branch is up-to-date with main

### Creating a Pull Request

1. **Push to your fork:**
   ```bash
   git push origin feature/your-feature-name
   ```

2. **Open PR on GitHub:**
   - Go to your fork on GitHub
   - Click "Pull Request" button
   - Select base: `main` ← compare: `feature/your-feature-name`
   - Fill out PR template

3. **PR Title:**
   Use same format as commit messages:
   ```
   feat(theme): add Plum Royale theme
   ```

4. **PR Description:**
   ```markdown
   ## Summary
   Brief description of changes.

   ## Motivation
   Why is this change needed?

   ## Changes
   - Added new theme preset
   - Updated theme selector UI
   - Added WCAG validation for new colors

   ## Testing
   - [ ] Tested on Web
   - [ ] Tested on Android
   - [ ] Tested on iOS
   - [ ] All existing tests pass
   - [ ] Added new tests

   ## Screenshots
   [If applicable]

   ## Related Issues
   Closes #45
   ```

### Review Process

1. **Automated checks:**
   - CI tests run automatically
   - Linting and formatting verified
   - Must pass before review

2. **Code review:**
   - Maintainers review code
   - May request changes
   - Discussion happens in PR comments

3. **Making changes:**
   ```bash
   # Make requested changes
   git add .
   git commit -m "refactor: address review feedback"
   git push origin feature/your-feature-name
   # PR updates automatically
   ```

4. **Approval and merge:**
   - Once approved, maintainers merge
   - Squash merge typically used
   - Your contribution is live!

### After Merge

1. **Update your fork:**
   ```bash
   git checkout main
   git pull upstream main
   git push origin main
   ```

2. **Delete feature branch:**
   ```bash
   git branch -d feature/your-feature-name
   git push origin --delete feature/your-feature-name
   ```

---

## Testing Guidelines

### Test Coverage Goals

- **Critical paths:** 90%+ coverage
- **Game logic:** 100% coverage
- **UI components:** 70%+ coverage
- **Utilities:** 100% coverage

### Writing Tests

**Unit tests** for pure logic:

```dart
// test/models/card_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:solitude/models/card.dart';

void main() {
  group('PlayingCard', () {
    test('should determine color correctly', () {
      final heartCard = PlayingCard(suit: Suit.hearts, rank: Rank.ace);
      expect(heartCard.color, CardColor.red);

      final spadeCard = PlayingCard(suit: Suit.spades, rank: Rank.king);
      expect(spadeCard.color, CardColor.black);
    });

    test('should generate unique IDs', () {
      final card1 = PlayingCard(suit: Suit.hearts, rank: Rank.ace);
      final card2 = PlayingCard(suit: Suit.hearts, rank: Rank.ace);
      final card3 = PlayingCard(suit: Suit.spades, rank: Rank.ace);

      expect(card1.id, card2.id);
      expect(card1.id, isNot(card3.id));
    });
  });
}
```

**Widget tests** for UI:

```dart
// test/widgets/card_widget_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:solitude/widgets/card_widget.dart';
import 'package:solitude/models/card.dart';

void main() {
  group('CardWidget', () {
    testWidgets('should display card', (tester) async {
      final card = PlayingCard(suit: Suit.hearts, rank: Rank.ace);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CardWidget(
              card: card,
              width: 100,
              height: 140,
            ),
          ),
        ),
      );

      expect(find.byType(CardWidget), findsOneWidget);
    });

    testWidgets('should handle tap', (tester) async {
      var tapped = false;
      final card = PlayingCard(suit: Suit.hearts, rank: Rank.ace);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CardWidget(
              card: card,
              width: 100,
              height: 140,
              onTap: () => tapped = true,
            ),
          ),
        ),
      );

      await tester.tap(find.byType(CardWidget));
      expect(tapped, true);
    });
  });
}
```

**Integration tests** for flows:

```dart
// test/integration/game_flow_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:solitude/main.dart';

void main() {
  testWidgets('complete game flow', (tester) async {
    await tester.pumpWidget(const SolitaireApp());
    await tester.pumpAndSettle();

    // Start game
    expect(find.text('New Game'), findsOneWidget);

    // Make moves
    // ... simulate gameplay

    // Verify win
    // ... check win condition
  });
}
```

### Running Tests

```bash
# All tests
flutter test

# Specific file
flutter test test/models/card_test.dart

# With coverage
flutter test --coverage

# Watch mode (rerun on changes)
flutter test --watch
```

---

## Documentation

### Code Documentation

**Public APIs** must have doc comments:

```dart
/// Validates whether the given overlay intensity maintains legibility.
///
/// Uses WCAG 2.1 guidelines to ensure a minimum contrast ratio of 3:1
/// between card suits and the card background after overlay is applied.
///
/// Parameters:
///   - [baseColor]: The original suit color (red or black)
///   - [overlayColor]: The theme's overlay tint color
///   - [intensity]: Overlay opacity from 0 to 100
///
/// Returns `true` if the contrast ratio is acceptable, `false` otherwise.
///
/// Example:
/// ```dart
/// final isValid = OverlayValidator.isLegible(
///   baseColor: Colors.red,
///   overlayColor: Color(0xFF123456),
///   intensity: 50,
/// );
/// ```
static bool isLegible({
  required Color baseColor,
  required Color overlayColor,
  required int intensity,
}) {
  // Implementation
}
```

**Private methods** use regular comments:

```dart
// Calculates the blended color by combining base and overlay
// using the specified intensity as alpha.
Color _blendColors(Color base, Color overlay, int intensity) {
  // Implementation
}
```

### User Documentation

Update relevant documentation files:
- `documents/USER_GUIDE.md` - User-facing features
- `documents/DEVELOPER_GUIDE.md` - Technical changes
- `README.md` - High-level overview

### Inline Comments

```dart
// Use comments to explain WHY, not WHAT
// The code itself explains WHAT

// Good:
// Use binary search because linear search would be O(n) for 100 values
final result = binarySearch(values, target);

// Bad:
// Search for the target in values
final result = binarySearch(values, target);
```

---

## Community

### Communication Channels

- **GitHub Issues:** Bug reports, feature requests
- **GitHub Discussions:** General questions, ideas (if enabled)
- **Pull Requests:** Code review and collaboration

### Getting Help

**Stuck on something?**
1. Check [DEVELOPER_GUIDE.md](DEVELOPER_GUIDE.md)
2. Search existing issues
3. Ask in a new issue with "Question" label

### Recognition

Contributors are recognized:
- Listed in release notes
- Mentioned in commit history
- Added to contributors list (if significant contributions)

---

## License

By contributing to Solitude, you agree that your contributions will be licensed under the GNU General Public License v3.0 (GPL-3.0).

See [LICENSE_DOCUMENTATION.md](LICENSE_DOCUMENTATION.md) for details.

**Important:**
- You retain copyright on your contributions
- You grant a GPL-3.0 license to the project
- Your contributions become part of the GPL-3.0 codebase
- You can dual-license your own code if desired

---

## Questions?

If you have questions about contributing, please:
1. Check this guide thoroughly
2. Review [DEVELOPER_GUIDE.md](DEVELOPER_GUIDE.md)
3. Search existing issues
4. Open a new issue with the "Question" label

---

**Thank you for contributing to Solitude!**

Every contribution, no matter how small, helps make Solitude better for everyone.
