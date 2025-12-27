# Solitude

A beautiful, open-source solitaire card game built with Flutter.

![License](https://img.shields.io/badge/license-GPL--3.0-blue.svg)
![Platform](https://img.shields.io/badge/platform-Web%20%7C%20Android%20%7C%20iOS%20%7C%20Windows%20%7C%20macOS%20%7C%20Linux-lightgrey.svg)
![Flutter](https://img.shields.io/badge/Flutter-3.0+-02569B.svg)

## Features

- **Cross-Platform**: Runs on Web, Android, iOS, Windows, macOS, and Linux
- **Offline-First**: No internet connection required
- **Accessible**: Large, readable cards optimized for all ages
- **Beautiful**: Custom platform-agnostic UI with elegant card table aesthetic
- **Extensible**: Architecture designed for adding new game types
- **Privacy-Respecting**: All data stored locally, never transmitted

## Screenshots

*Coming soon*

## Installation

### From Source

1. **Prerequisites**
   - Flutter SDK 3.0 or higher
   - Dart SDK 3.0 or higher

2. **Clone the repository**
   ```bash
   git clone https://github.com/plotworx/solitude.git
   cd solitude
   ```

3. **Get dependencies**
   ```bash
   flutter pub get
   ```

4. **Download card assets**
   ```bash
   # Download the SVG cards from htdebeer/SVG-cards
   # Place svg-cards.svg in assets/cards/
   ```

5. **Download Inter font**
   ```bash
   # Download from https://rsms.me/inter/
   # Place font files in assets/fonts/
   ```

6. **Run the app**
   ```bash
   # For web
   flutter run -d chrome
   
   # For desktop
   flutter run -d windows  # or macos, linux
   
   # For mobile
   flutter run -d android  # or ios
   ```

### Pre-built Releases

Download the latest release for your platform from the [Releases](https://github.com/plotworx/solitude/releases) page.

## Game Rules (Klondike)

### Objective
Move all 52 cards to the four foundation piles, building each from Ace to King by suit.

### Layout
- **Stock**: Face-down cards to draw from
- **Waste**: Cards drawn from stock
- **Foundations**: Four piles (one per suit) to build Ace → King
- **Tableau**: Seven columns of cards

### Rules
1. Draw 1 or 3 cards from stock to waste
2. Move cards between tableau columns in descending order, alternating colors
3. Only Kings can be placed on empty tableau columns
4. Move cards from tableau or waste to foundations in ascending order by suit

## Settings

- **Draw Mode**: Draw 1 or 3 cards at a time
- **Auto-Complete**: Automatically complete game when all cards are face-up
- **Theme**: Light or Dark mode

## Statistics Tracked

- Games Played
- Games Won
- Win Percentage
- Current Win Streak
- Best Win Streak
- Best Time
- Fewest Moves

## Building for Distribution

### Web (PWA)
```bash
flutter build web --release
```

### Android
```bash
# APK
flutter build apk --release

# App Bundle (for Play Store)
flutter build appbundle --release
```

### iOS
```bash
flutter build ios --release
```

### Windows
```bash
flutter build windows --release
```

### macOS
```bash
flutter build macos --release
```

### Linux
```bash
flutter build linux --release
```

## Project Structure

```
solitude/
├── lib/
│   ├── main.dart              # App entry point
│   ├── models/                # Data models
│   │   ├── card.dart
│   │   ├── deck.dart
│   │   ├── pile.dart
│   │   └── move.dart
│   ├── games/                 # Game implementations
│   │   ├── game_interface.dart
│   │   └── klondike/
│   ├── widgets/               # Custom UI widgets
│   ├── screens/               # App screens
│   ├── services/              # Business logic
│   └── theme/                 # Theming
├── assets/
│   ├── cards/                 # SVG card graphics
│   └── fonts/                 # Inter font
├── LICENSE                    # GPL v3
├── CREDITS.md                 # Asset attributions
└── README.md
```

## Future Plans

- [ ] Spider Solitaire
- [ ] FreeCell
- [ ] Sound effects (optional)
- [ ] Additional card back designs
- [ ] Landscape optimization improvements
- [ ] Accessibility improvements

## Contributing

Contributions are welcome! Please read our contributing guidelines before submitting pull requests.

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Submit a pull request

## License

This project is licensed under the **GNU General Public License v3.0** - see the [LICENSE](LICENSE) file for details.

### Third-Party Licenses

- **Card Graphics**: [SVG Playing Cards](https://github.com/htdebeer/SVG-cards) by David Bellot / Huub de Beer - LGPL 2.1+
- **Font**: [Inter](https://rsms.me/inter/) by Rasmus Andersson - SIL Open Font License

## Acknowledgments

- David Bellot and Huub de Beer for the beautiful SVG playing cards
- Rasmus Andersson for the Inter typeface
- The Flutter team for an excellent cross-platform framework

---

Made with ♠️ by [Plotworx](https://plotworx.org)
