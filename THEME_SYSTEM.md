# Theme System Implementation

## Overview
Comprehensive theme system for Solitude with card face overlays, visual theme selection, and full-screen tabbed settings.

## New Features

### 1. Theme Presets (`lib/models/theme_preset.dart`)
- **7 Built-in Themes:**
  - Classic Felt (traditional green)
  - Royal Blue (navy with silver accents)
  - Burgundy Velvet (deep red with brass)
  - Midnight (sleek black with platinum)
  - Vintage Light (antique paper aesthetic)
  - Vintage Dark (aged parchment)
  - Nordic (clean Scandinavian minimal)

- **Per-Theme Settings:**
  - Table colors (light/dark)
  - Accent colors
  - Card face overlay color
  - Default overlay intensity
  - Blend mode

### 2. Card Face Overlays
- **Tint entire card uniformly** with theme-specific colors
- **Intensity slider** (0-100%) with per-theme memory
- **Legibility validation** ensures red/black suits remain distinguishable
- **Warning system** alerts when overlay reduces readability
- **Blend modes** (modulate, multiply) for different visual effects

### 3. Full-Screen Tabbed Settings (`lib/screens/settings_screen.dart`)

#### Tab 1: Appearance
- **Visual theme selector** - Grid layout with live preview
- **Card face overlay controls** - Color tint and intensity slider
- **Card back customization** - Style + custom colors
- **Live preview** - Shows 3 sample cards (red, black, back)

#### Tab 2: Gameplay
- Difficulty selection
- Scoring mode
- Light/Dark mode toggle
- Auto-complete
- Autoplay
- Sound effects + volume
- Background music + volume
- Quick access to Help and About screens

#### Tab 3: Statistics
- Games played/won/lost
- Win rate and streaks
- Best time / fewest moves (Standard)
- Total winnings / high score (Vegas)
- Reset statistics button

### 4. Material 3 Upgrade
- Updated from Material 2 to Material 3
- Modern component styling
- Dynamic theming support ready
- Improved elevation and state layers

### 5. Overlay Legibility Validator (`lib/utils/overlay_validator.dart`)
- **WCAG-based contrast checking**
- Tests red suits (#CC3333) vs white background
- Tests black suits (#000000) vs white background
- Tests red vs black distinguishability
- Suggests maximum safe intensity
- Binary search algorithm for optimal values

## Architecture Changes

### Settings Provider
- Added `currentThemeId` (String)
- Added `themeOverlayIntensities` (Map<String, double>)
- Per-theme overlay intensity persistence
- Theme switching with `setCurrentTheme()`
- Overlay adjustment with `setOverlayIntensity()`

### CardWidget
- Added overlay rendering via `ColorFiltered`
- Only applies to face-up cards
- Respects intensity threshold (>0.01)
- Uses theme's blend mode

### AppTheme
- Now accepts optional `ThemePreset` parameter
- Dynamically generates themes from preset colors
- Material 3 enabled

### Main App
- MaterialApp now uses theme preset colors
- Rebuilds when theme changes
- Maintains light/dark mode support

## Files Created
- `lib/models/theme_preset.dart` - Theme definitions
- `lib/utils/overlay_validator.dart` - Legibility checking
- `lib/screens/settings_screen.dart` - New full-screen settings
- `lib/widgets/theme_preview_cards.dart` - Live card previews

## Files Modified
- `lib/services/settings_provider.dart` - Theme management
- `lib/widgets/card_widget.dart` - Overlay rendering
- `lib/theme/app_theme.dart` - Material 3 + dynamic theming
- `lib/screens/game_screen.dart` - Use new SettingsScreen
- `lib/main.dart` - Pass theme preset to MaterialApp

## Files Deprecated
- `lib/screens/settings_panel.dart` - Replaced by settings_screen.dart

## Usage

### Selecting a Theme
1. Open Settings
2. Go to "Appearance" tab
3. Tap any theme in the grid
4. Theme applies immediately to entire app

### Adjusting Card Overlay
1. Select a theme
2. Use "Tint Intensity" slider
3. Preview updates in real-time
4. Warning appears if legibility is compromised
5. Each theme remembers its own intensity setting

### Customizing Card Backs
1. Choose Classic or Alternate back design
2. Enable "Custom Color"
3. Select from 5 preset colors
4. Preview updates immediately

## Technical Details

### Overlay Rendering
```dart
ColorFiltered(
  colorFilter: ColorFilter.mode(
    theme.cardFaceOverlay.withValues(alpha: overlayIntensity),
    theme.overlayBlendMode,
  ),
  child: SvgCardRenderer(...),
)
```

### Theme Persistence
- Current theme ID stored as string
- Overlay intensities stored as JSON map
- Uses SharedPreferences
- Loads on app startup

### Legibility Algorithm
1. Calculate effective overlay color with intensity
2. Simulate blend on red/black/white colors
3. Calculate WCAG contrast ratios
4. Require minimum 3.0:1 for suits vs background
5. Require minimum 2.0:1 for red vs black

## Future Enhancements
- Custom theme creation
- Theme import/export
- Community theme gallery
- Background textures/images
- Font customization
- More overlay blend modes
- Seasonal themes
- Achievement-based theme unlocks
