# Solitude - User Guide

Welcome to **Solitude**, a beautiful cross-platform solitaire game built with Flutter. This guide will help you get started and master all the features.

## Table of Contents

1. [Getting Started](#getting-started)
2. [How to Play](#how-to-play)
3. [Game Rules](#game-rules)
4. [Difficulty Levels](#difficulty-levels)
5. [Scoring Modes](#scoring-modes)
6. [Theme System](#theme-system)
7. [Card Customization](#card-customization)
8. [Audio Settings](#audio-settings)
9. [Gameplay Features](#gameplay-features)
10. [Statistics](#statistics)
11. [Keyboard Shortcuts](#keyboard-shortcuts)
12. [Tips and Strategies](#tips-and-strategies)

---

## Getting Started

### Installation

Solitude is available on multiple platforms:

- **Web**: Visit the web version at your browser
- **Android**: Download from Google Play Store
- **iOS**: Download from App Store
- **Windows/macOS/Linux**: Download the desktop application

### First Launch

When you first launch Solitude, you'll see a loading splash screen while the card graphics are prepared. This ensures smooth gameplay once you start playing.

### Main Screen

The game screen consists of:
- **Game Board**: The playing area with tableau, foundations, stock, and waste piles
- **Top Toolbar**: Access to settings, new game, undo, hints, and autoplay
- **Timer/Score**: Displays your current game progress

---

## How to Play

### Objective

The goal of Klondike Solitaire is to move all cards to the four foundation piles, sorted by suit from Ace to King.

### Moving Cards

**Mouse/Touch Controls:**
- **Tap/Click** a card to select it
- **Tap/Click** a destination to move it
- **Double-tap/Double-click** a card to auto-move it to the best destination (foundations first, then valid tableau positions)
- **Drag and drop** cards between piles

**Keyboard Controls:**
- Press **Tab** or **Shift+Tab** to cycle through piles
- Press **Enter** or **Space** to activate the focused pile
- See [Keyboard Shortcuts](#keyboard-shortcuts) for more

### Card Movement Rules

**Tableau (Main Playing Area):**
- Cards must be placed in descending order (King, Queen, Jack, 10, 9...)
- Colors must alternate (red on black, black on red)
- Only face-up cards can be moved
- You can move groups of cards if they're properly sequenced
- Only Kings can be placed in empty tableau columns

**Foundations (Top Right):**
- Start with Aces
- Build up in the same suit (Ace → 2 → 3... → King)
- Cards moved to foundations are generally not moved back

**Stock (Top Left):**
- Click to draw cards to the waste pile
- In Easy/Medium mode: Draw 1 card at a time
- In Hard mode: Draw 3 cards at a time
- You can cycle through the stock multiple times (unlimited in Easy/Medium, 3 times in Hard)

**Waste (Next to Stock):**
- Shows cards drawn from the stock
- Only the top card can be played
- Click/tap the waste pile to move its top card to a valid destination

---

## Game Rules

### Valid Moves

1. **Tableau to Foundation**: Card must be next in sequence for that suit
2. **Tableau to Tableau**: Card must be one rank lower and opposite color
3. **Waste to Foundation**: Same as tableau to foundation
4. **Waste to Tableau**: Same as tableau to tableau
5. **Foundation to Tableau**: Allowed, but generally not strategic
6. **King to Empty Tableau**: Only Kings can occupy empty tableau columns

### Invalid Moves

The game will prevent or warn you about:
- Placing cards out of sequence
- Placing same-color cards on each other in tableau
- Placing non-Kings in empty tableau columns
- Moving cards that would expose nothing new

---

## Difficulty Levels

Choose your challenge level in Settings → Gameplay:

### Easy
- Draw **1 card** at a time from stock
- **Unlimited** passes through the stock
- Best for learning and relaxed play

### Medium
- Draw **1 card** at a time from stock
- **Unlimited** passes through the stock
- Balanced gameplay (same as Easy but labeled for clarity)

### Hard
- Draw **3 cards** at a time from stock
- **Maximum 3 passes** through the stock
- Traditional Vegas-style rules
- Significantly more challenging

---

## Scoring Modes

### Standard Mode
- **Track**: Best time and fewest moves
- **Goal**: Complete the game as quickly as possible with minimal moves
- **No cost**: Play as many games as you want
- Perfect for practicing and improving your skills

### Vegas Mode
- **Entry fee**: $52 per game (virtual money)
- **Payout**: $5 for each card moved to foundations
- **Profit threshold**: Need 11+ cards in foundations to break even
- **Goal**: Maximize your total winnings
- **Track**: Total winnings and high score per game
- Adds risk/reward excitement to gameplay

Switch between modes anytime in Settings → Gameplay.

---

## Theme System

Solitude features a sophisticated theme system with 8 beautiful built-in themes:

### Built-in Themes

1. **Classic Felt** - Traditional green casino table
2. **Royal Blue** - Navy elegance with silver accents
3. **Burgundy Velvet** - Deep red luxury with sage green
4. **Midnight** - Sleek black sophistication with platinum
5. **Ocean Teal** - Modern calming blues
6. **Sunset Amber** - Warm rustic golden tones
7. **Slate Gray** - Professional high-contrast minimalism
8. **Plum Royale** - Elegant regal purple

### Changing Themes

1. Open **Settings** (gear icon or press **Esc**)
2. Go to **Appearance** tab
3. Browse the theme gallery with live card previews
4. Tap a theme to select it
5. The entire game (table, toolbar, cards) updates instantly

### Theme Features

Each theme includes:
- **Table Color**: The main playing surface background
- **Toolbar Color**: Dynamic toolbar that adapts to the theme
- **Accent Colors**: Up to 5 custom colors for various UI elements
- **Card Face Overlay**: Optional tinted overlay for card faces (see below)

---

## Card Customization

### Card Back Design

Choose between two card back designs:
1. **Classic**: Traditional pattern
2. **Alternate**: Modern alternative design

**How to change:**
- Settings → Appearance → Card Back → Select your preference

### Card Face Overlays

Add a subtle tint to card faces that matches your theme:

**Features:**
- Each theme has its own overlay tint color
- Adjust intensity from 0% (no overlay) to 100% (maximum tint)
- Real-time preview shows exactly how cards will look
- Automatic legibility validation ensures red and black suits remain readable
- Each theme remembers its own intensity setting

**How to customize:**
1. Settings → Appearance → Card Overlays
2. Use the slider to adjust intensity
3. Preview cards update in real-time
4. If contrast becomes too low, you'll see a warning
5. Your setting is saved per-theme

**Legibility Validation:**
The system uses WCAG color contrast standards to ensure:
- Red suits remain distinguishable on red cards
- Black suits remain distinguishable on black cards
- If contrast ratio drops below 3:1, a warning appears
- You can still use low-contrast settings if you prefer

---

## Audio Settings

### Sound Effects

Control individual sound effects:
- **Card Flip**: Sound when cards are turned over
- **Card Place**: Sound when cards are placed on piles
- **Card Shuffle**: Sound when deck is shuffled
- **Error**: Sound for invalid moves
- **Success**: Sound when game is won

Each sound has its own volume slider (0-100%).

### Background Music

- **Enable/Disable**: Toggle background music on/off
- **Volume**: Separate volume control (0-100%)
- **Looping**: Music loops continuously while playing

**How to adjust:**
- Settings → Gameplay → scroll to Audio Settings
- Use toggles and sliders to customize your experience

---

## Gameplay Features

### Hints

Can't find a move? The hint system helps you:

**How to use:**
- Click the **lightbulb icon** in the toolbar
- Press **H** on your keyboard
- Wait 8 seconds of inactivity (auto-hint)

**Hint Priority:**
The hint system suggests moves in this order:
1. **Foundation moves** (always beneficial)
2. **Moves that expose face-down cards** (reveal new options)
3. **Waste to tableau** (brings new cards into play)
4. **Tableau consolidation** (organize your playing area)

### Auto-Complete

When all cards are face-up and the game is essentially won:
- The system detects this state
- If enabled, automatically completes the game
- Moves remaining cards to foundations
- Can be disabled in Settings → Gameplay

### Autoplay Mode

Watch the AI play using the hint system:
- Click the **play icon** in the toolbar
- Press **A** to toggle
- AI uses the same hint logic as the hint feature
- Detects oscillation (repeated moves) and adjusts strategy
- Stops when game is won or lost

**Useful for:**
- Learning strategies
- Testing if a game is winnable
- Entertainment

### Undo

Made a mistake? No problem:
- Click the **undo icon** in the toolbar
- Press **U** or **Ctrl+Z**
- Unlimited undo history
- Goes back one move at a time

### Loss Detection

The game automatically detects when you're stuck:
- Checks if the stock is exhausted
- Verifies no valid moves exist
- Considers only "progressive" moves (not just shuffling Kings)
- Alerts you when the game is truly unwinnable

### New Game

Start fresh anytime:
- Click the **new game icon** in the toolbar
- Press **N** on your keyboard
- Confirms if you want to abandon current game
- New shuffled deck is dealt

---

## Statistics

Track your progress over time in Settings → Statistics:

### Standard Mode Stats
- **Games Played**: Total games started
- **Games Won**: Games completed successfully
- **Games Lost**: Games that became unwinnable
- **Win Percentage**: Your success rate
- **Current Win Streak**: Consecutive wins
- **Best Win Streak**: Your longest winning streak
- **Best Time**: Fastest game completion
- **Fewest Moves**: Most efficient game

### Vegas Mode Stats
- **Total Winnings**: Net profit/loss across all games
- **High Score**: Most profit in a single game
- Plus all standard stats

### Resetting Statistics

You can reset all statistics to zero:
- Settings → Statistics → Reset Statistics button
- Confirmation required
- Cannot be undone

---

## Keyboard Shortcuts

Master these shortcuts for faster gameplay:

| Shortcut | Action |
|----------|--------|
| **Tab** | Cycle focus to next pile |
| **Shift+Tab** | Cycle focus to previous pile |
| **Enter** or **Space** | Activate focused pile (draw stock, flip tableau card, or move to best destination) |
| **U** or **Ctrl+Z** | Undo last move |
| **N** | New game |
| **H** | Show hint |
| **A** | Toggle autoplay |
| **Esc** | Open settings |

**Using Keyboard Focus:**
1. Press **Tab** to highlight a pile (yellow border)
2. Continue pressing **Tab** to cycle through piles
3. Press **Enter** to:
   - Draw from stock
   - Flip tableau cards
   - Move cards to valid destinations
4. Use with hints for completely mouse-free gameplay

---

## Tips and Strategies

### General Strategy

1. **Expose face-down cards first**: Always prioritize moves that flip tableau cards
2. **Build foundations evenly**: Don't rush one suit to completion; keep options open
3. **Empty columns are valuable**: Use them to manipulate long sequences
4. **Kings in empty columns**: Choose wisely which King to place
5. **Aces and twos up quickly**: Low cards are safe to move to foundations immediately

### Using the Stock

1. **Don't rush through the stock**: Think before drawing more cards
2. **In Hard mode (draw 3)**: Keep track of which cards are buried
3. **Plan for multiple passes**: In Easy/Medium mode, you can see all cards eventually

### Advanced Tactics

1. **Color blocking**: Be aware when you need a specific color that might be blocked
2. **Sequence planning**: Think several moves ahead
3. **Foundation timing**: Sometimes it's better to keep cards in tableau for flexibility
4. **Empty column management**: Don't fill empty columns too quickly

### When to Use Hints

- When you're completely stuck
- To verify your planned move is optimal
- When learning (see what the AI suggests and understand why)
- After 8 seconds of inactivity, a hint appears automatically

### Difficulty Selection

- **Start with Easy/Medium**: Learn the mechanics and basic strategy
- **Progress to Hard**: Once you're winning 20%+ of Easy games
- **Vegas Mode**: Adds excitement but uses Hard difficulty rules

---

## Troubleshooting

### Game Performance

**Cards loading slowly?**
- The initial load preloads all graphics for smooth gameplay
- Subsequent games should be instant

**Animations stuttering?**
- Ensure your device meets minimum requirements
- Close other applications to free up resources

### Audio Issues

**No sound?**
- Check that audio is enabled in Settings → Gameplay
- Verify system volume is not muted
- Check individual sound effect volumes

**Background music not looping?**
- This is a known behavior; music should loop automatically
- Check that music volume is above 0%

### Gameplay Questions

**Why can't I move this card?**
- Verify it follows the placement rules (alternating colors, descending ranks)
- Only Kings can go in empty tableau columns
- Foundation cards must be in sequence for the correct suit

**The hint button does nothing:**
- There might be no valid moves (game is lost)
- Check if loss detection has triggered

### Settings Not Saving

**Settings reset after closing?**
- Settings should persist automatically via local storage
- Check that your browser/app has storage permissions
- On web: Ensure cookies/local storage are enabled

---

## Accessibility

Solitude is designed to be accessible:

- **Large cards**: Easy to see and distinguish
- **High contrast themes**: Slate Gray for maximum visibility
- **Keyboard navigation**: Full game playable without mouse
- **Visual feedback**: Clear indicators for valid/invalid moves
- **WCAG compliance**: Overlay validation ensures readability

---

## Privacy

Solitude respects your privacy:

- **No data collection**: Zero telemetry or analytics
- **Local storage only**: All settings and statistics stored on your device
- **No internet required**: Play completely offline
- **No accounts**: No sign-up, no login, no tracking

---

## Support and Feedback

### Getting Help

- **In-game help**: Settings → Help (question mark icon)
- **GitHub Issues**: Report bugs or request features at the project repository
- **Documentation**: See DEVELOPER_GUIDE.md for technical details

### Contributing

Solitude is open source under GPL-3.0. Contributions are welcome! See CONTRIBUTING.md for guidelines.

---

## About

**Solitude** is an open-source project built with Flutter, featuring:
- Beautiful SVG playing cards by htdebeer/SVG-cards (LGPL 2.1+)
- Inter font family by Rasmus Andersson (OFL 1.1)
- Built with Flutter framework by Google (BSD 3-Clause)

See LICENSE_DOCUMENTATION.md for complete license information.

---

**Enjoy playing Solitude!**

Version 1.0.0
