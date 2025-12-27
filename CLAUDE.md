# Solitude

A cross-platform solitaire game built in Flutter.

## Recent Work
- **Comprehensive theme system** with 7 built-in themes
- **Card face overlays** with per-theme tint intensity and legibility validation
- **Full-screen tabbed settings** (Appearance, Gameplay, Statistics)
- **Material 3 upgrade** for modern UI components
- **Dynamic theming** - table, toolbar, and all UI adapts to selected theme

## Architecture
- `lib/games/klondike/klondike_game.dart` - Game logic, hint system, loss detection
- `lib/services/game_controller.dart` - State management, autoplay loop
- `lib/services/settings_provider.dart` - Settings + theme management
- `lib/models/theme_preset.dart` - 7 theme definitions with overlay settings
- `lib/widgets/svg_card_renderer.dart` - Extracts cards from htdebeer sprite sheet
- `lib/widgets/card_widget.dart` - Card rendering with overlay support
- `lib/widgets/game_board.dart` - Playing board with theme-aware background
- `lib/widgets/game_toolbar.dart` - Toolbar with theme-aware colors
- `lib/screens/settings_screen.dart` - Full-screen tabbed settings UI
- `lib/utils/overlay_validator.dart` - WCAG-based legibility checker

## Theme System
**Built-in Themes:**
- Classic Felt (green), Royal Blue, Burgundy Velvet, Midnight
- Vintage Light/Dark (sepia), Nordic (minimal)

**Features:**
- Per-theme card face overlays (tint color + intensity)
- Legibility validation (ensures red/black suits remain readable)
- Visual theme selector with live previews
- Dynamic table and toolbar colors
- See `THEME_SYSTEM.md` for full documentation

## Current Focus
- Theme system complete and ready for testing
