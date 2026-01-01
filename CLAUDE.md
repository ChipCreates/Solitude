# Solitude

A cross-platform solitaire game built in Flutter supporting 10 solitaire variants.

## Recent Work
- **10 Solitaire Variants** - Klondike, Spider, Pyramid, Golf, FreeCell, TriPeaks, Yukon, Forty Thieves, Canfield, Scorpion
- **Comprehensive theme system** with 7 built-in themes
- **Card face overlays** with per-theme tint intensity and legibility validation
- **Full-screen tabbed settings** (Theme, Cards, Gameplay, Sound)
- **Context-aware settings** - game-specific options based on current variant
- **Material 3 upgrade** for modern UI components
- **Dynamic theming** - table, toolbar, and all UI adapts to selected theme

## Architecture (Feature-First Structure)

### Core
- `lib/core/theme/app_theme.dart` - Theme definitions and styling
- `lib/core/utils/overlay_validator.dart` - WCAG-based legibility checker
- `lib/core/widgets/` - Shared UI components (GameButton, etc.)
- `lib/core/services/audio_service.dart` - Audio playback service

### Game Feature (`lib/features/game/`)
- `lib/features/game/games/game_interface.dart` - Abstract game interface + GameType enum
- `lib/features/game/games/game_factory.dart` - Factory for creating game instances
- `lib/features/game/games/klondike/` - Klondike solitaire implementation
- `lib/features/game/games/spider/` - Spider solitaire implementation
- `lib/features/game/games/pyramid/` - Pyramid solitaire implementation
- `lib/features/game/games/freecell/` - FreeCell implementation
- `lib/features/game/games/golf/` - Golf solitaire implementation
- `lib/features/game/games/tripeaks/` - TriPeaks solitaire implementation
- `lib/features/game/games/yukon/` - Yukon solitaire implementation
- `lib/features/game/games/fortythieves/` - Forty Thieves implementation
- `lib/features/game/games/canfield/` - Canfield solitaire implementation
- `lib/features/game/games/scorpion/` - Scorpion solitaire implementation
- `lib/features/game/services/game_controller.dart` - State management, autoplay loop
- `lib/features/game/layouts/` - Game-specific layout strategies
- `lib/features/game/widgets/card_widget.dart` - Card rendering with overlay support
- `lib/features/game/widgets/game_board.dart` - Playing board with theme-aware background
- `lib/features/game/widgets/game_toolbar.dart` - Toolbar with theme-aware colors
- `lib/features/game/screens/game_chooser_screen.dart` - Game variant selection UI
- `lib/features/game/screens/game_screen.dart` - Main game screen

### Settings Feature (`lib/features/settings/`)
- `lib/features/settings/services/settings_provider.dart` - Settings + theme management
- `lib/features/settings/screens/settings_screen.dart` - Full-screen tabbed settings UI
- `lib/features/settings/models/difficulty.dart` - Difficulty enum
- `lib/features/settings/models/theme_preset.dart` - Theme definitions with overlay settings

### Statistics Feature (`lib/features/statistics/`)
- `lib/features/statistics/services/statistics_service.dart` - Game statistics tracking

### Home Feature (`lib/features/home/`)
- `lib/features/home/screens/about_screen.dart` - About screen
- `lib/features/home/screens/help_screen.dart` - Help/instructions screen

## Game-Specific Settings
- **Draw Mode (1/3)** - Klondike, Canfield only
- **Scoring Mode (Standard/Vegas)** - Klondike only
- **Suit Count (1/2/4)** - Spider (maps to Easy/Medium/Hard difficulty)

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
- All 10 game variants wired up and playable
- Context-aware settings panel complete
