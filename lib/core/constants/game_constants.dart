/// Game-wide constants for animations, timings, and other configuration values.
///
/// This centralizes magic numbers that were previously scattered throughout
/// the codebase, making them easier to maintain and adjust.
class GameConstants {
  // Private constructor to prevent instantiation
  GameConstants._();

  // ============================================================================
  // ANIMATION DURATIONS
  // ============================================================================

  /// Duration for card flip animation (e.g., stock to waste)
  static const cardFlipDuration = Duration(milliseconds: 300);

  /// Duration for card move animation (e.g., tableau to foundation)
  static const moveAnimationDuration = Duration(milliseconds: 400);

  /// Shorter duration for quick card movements (e.g., double-tap auto-move)
  static const quickMoveAnimationDuration = Duration(milliseconds: 300);

  /// Duration for stock draw animation (includes flip)
  static const stockDrawAnimationDuration = Duration(milliseconds: 350);

  /// Delay before triggering flip during stock draw animation
  static const stockFlipDelay = Duration(milliseconds: 50);

  // ============================================================================
  // HINT & AUTO-COMPLETE TIMINGS
  // ============================================================================

  /// How long to display a hint before it auto-clears
  static const hintDisplayDuration = Duration(seconds: 2);

  /// Delay between auto-complete moves
  static const autoCompleteDelay = Duration(milliseconds: 200);

  /// Delay between auto-play moves (solver playback)
  static const autoPlayMoveDelay = Duration(milliseconds: 200);

  // ============================================================================
  // SOLVER & AI TIMINGS
  // ============================================================================

  /// Debounce delay before starting background solver
  static const solverDebounceDelay = Duration(milliseconds: 500);

  /// Maximum time to spend on solving (timeout)
  static const solverTimeout = Duration(seconds: 30);

  // ============================================================================
  // INACTIVITY DETECTION
  // ============================================================================

  /// Time of inactivity before showing an auto-hint
  static const inactivityTimeout = Duration(seconds: 30);

  // ============================================================================
  // CARD DIMENSIONS & SPACING
  // ============================================================================

  /// Standard card aspect ratio (poker size: 2.5" x 3.5")
  static const double cardAspectRatio = 2.5 / 3.5;

  /// Minimum spacing between piles (in logical pixels)
  static const double minPileSpacing = 8.0;

  /// Default horizontal padding for game board
  static const double boardHorizontalPadding = 8.0;

  /// Default vertical padding for game board
  static const double boardVerticalPadding = 8.0;

  // ============================================================================
  // GAME SCORING
  // ============================================================================

  /// Vegas scoring: cost per card in deck (game buy-in)
  static const int vegasCardCost = 1; // -$1 per card

  /// Vegas scoring: reward per card moved to foundation
  static const int vegasCardValue = 5; // +$5 per card

  // ============================================================================
  // UNDO/REDO
  // ============================================================================

  /// Maximum undo history depth (0 = unlimited)
  static const int maxUndoHistory = 0;

  // ============================================================================
  // PERSISTENCE
  // ============================================================================

  /// Auto-save game state interval (0 = save only on pause/exit)
  static const Duration autoSaveInterval = Duration(seconds: 5);

  /// Key for saved game state in Hive
  static const String savedGameKey = 'current_game';

  // ============================================================================
  // UI FEEDBACK
  // ============================================================================

  /// Duration for error shake animation
  static const errorShakeDuration = Duration(milliseconds: 400);

  /// Duration for success flash/glow effect
  static const successFlashDuration = Duration(milliseconds: 600);

  /// Duration for card selection highlight fade-in
  static const selectionFadeInDuration = Duration(milliseconds: 150);

  // ============================================================================
  // ACCESSIBILITY
  // ============================================================================

  /// Minimum touch target size (44x44 logical pixels per iOS/Material guidelines)
  static const double minTouchTargetSize = 44.0;

  /// Minimum font size for readability
  static const double minFontSize = 12.0;

  // ============================================================================
  // PERFORMANCE
  // ============================================================================

  /// Maximum number of cards to animate simultaneously
  static const int maxSimultaneousAnimations = 1;

  /// Frame rate target for animations (60 FPS)
  static const int targetFrameRate = 60;

  // ============================================================================
  // GAME RULES CONSTANTS
  // ============================================================================

  /// Standard deck size (52 cards)
  static const int standardDeckSize = 52;

  /// Spider deck size (104 cards, 2 decks)
  static const int spiderDeckSize = 104;

  /// Forty Thieves deck size (104 cards, 2 decks)
  static const int fortyThievesDeckSize = 104;

  /// Number of foundation piles in most games
  static const int standardFoundationCount = 4;

  /// Number of tableau piles in Klondike
  static const int klondikeTableauCount = 7;

  /// Number of tableau piles in Spider
  static const int spiderTableauCount = 10;

  /// Number of tableau piles in FreeCell
  static const int freecellTableauCount = 8;

  /// Number of free cells in FreeCell
  static const int freecellFreeCount = 4;
}
