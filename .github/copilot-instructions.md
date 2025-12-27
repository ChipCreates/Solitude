# Copilot instructions for Solitude (brief)

This file gives targeted, actionable guidance to AI coding agents working on Solitude.

+High-level architecture
+ App entry: `lib/main.dart` — services are initialized and registered with Provider (`SettingsProvider`, `StatisticsService`, `GameController`).
+ UI: Compose from `lib/screens/` and `lib/widgets/` (visual components live in `lib/widgets/`).
+ Business logic: `lib/services/` holds ChangeNotifier services (game state, settings, statistics, audio). See `lib/services/game_controller.dart` for the core game flow.
+ Models: Pure data types live in `lib/models/` (cards, piles, moves).
+ Games: Game implementations are under `lib/games/` (Klondike is the reference implementation in `lib/games/klondike/`).

Key conventions and patterns (project-specific)
- State management: `provider` with `ChangeNotifier`. Services are passed into `GameController` at app startup — avoid changing provider registration shape unless necessary. Example: providers are configured in `main()`.
- Service responsibilities: keep UI code free of game rules — put move validation, auto-complete, timer, and statistics in `GameController` / game classes.
- Assets: SVG card art and fonts are stored under `assets/cards/` and `assets/fonts/`. New assets must be referenced in `pubspec.yaml` (`flutter.assets` and `flutter.fonts`).
- Audio: an `AudioService` abstraction exists; `GameController` defaults to `SilentAudioService`. Use the service interface when adding audio; don't hardcode playback in widgets.
- Settings persistence: `SettingsProvider` uses `shared_preferences`. Load/save operations are async — follow the established async patterns used in `SettingsProvider`.

Build, run, and debug commands (from repo README)
- Fetch deps: `flutter pub get`
- Run (web): `flutter run -d chrome`
- Run (desktop): `flutter run -d linux` (or `windows`, `macos`)
- Build release: `flutter build web --release` (or `flutter build apk --release`, etc.)

Change guidance for AI agents
- Small, focused PRs: change one file or one small feature at a time. Keep public APIs stable.
- Tests: repository has no tests; if you add tests, place them under `test/` and use `flutter test`.
- Assets & pubspec: when adding assets, update `pubspec.yaml` and ensure paths match `assets/` entries.
- Provider changes: if altering providers, update both `main.dart` and any code that calls `Provider.of` or consumes the type.
- UI changes: prefer changes in `lib/widgets/*` and `lib/screens/*`. Avoid large refactors that touch many widgets in a single PR.

Files to consult for examples
- App setup and providers: `lib/main.dart`
- Core game logic and patterns: `lib/services/game_controller.dart`
- Settings persistence: `lib/services/settings_provider.dart`
- Game implementation example: `lib/games/klondike/klondike_game.dart`
- SVG card rendering: `lib/widgets/svg_card_renderer.dart`

What NOT to do (quick list)
- Do not add remote telemetry or network calls — the project is offline-first and privacy-respecting.
- Do not assume platform-specific assets exist; add them to `assets/` and `pubspec.yaml` first.
- Avoid global mutable state outside `ChangeNotifier` services — follow the existing provider pattern.

If anything is unclear, ask the maintainer which platform targets to prioritize, whether to add CI, or where to place integration tests.

— End of instructions —
