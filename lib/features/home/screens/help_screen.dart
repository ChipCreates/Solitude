import 'package:flutter/material.dart';
import 'package:solitude/core/theme/app_theme.dart';
import 'package:solitude/features/settings/models/difficulty.dart';
import 'package:solitude/features/game/games/game_factory.dart';

/// Game-aware help screen that displays rules and tips for the current game type.
class HelpScreen extends StatelessWidget {
  /// The game type to display help for. Defaults to Klondike if not specified.
  final GameType gameType;

  const HelpScreen({super.key, this.gameType = GameType.klondike});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor(context),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildIntroSection(context),
                    const SizedBox(height: 32),
                    _buildObjectiveSection(context),
                    const SizedBox(height: 32),
                    _buildGameplaySection(context),
                    const SizedBox(height: 32),
                    // Only show difficulty section for games that support it
                    if (_hasDifficultySettings()) ...[
                      _buildDifficultySection(context),
                      const SizedBox(height: 32),
                    ],
                    // Only show scoring section for Klondike and Canfield
                    if (_hasScoringModes()) ...[
                      _buildScoringSection(context),
                      const SizedBox(height: 32),
                    ],
                    _buildKeyboardShortcutsSection(context),
                    const SizedBox(height: 32),
                    _buildTipsSection(context),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _hasDifficultySettings() {
    return gameType == GameType.klondike || gameType == GameType.spider;
  }

  bool _hasScoringModes() {
    return gameType == GameType.klondike || gameType == GameType.canfield;
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: AppTheme.toolbarColor(context),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.arrow_back, color: AppTheme.textColor(context)),
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(width: 8),
          Text('How to Play', style: AppTypography.subheading(context)),
        ],
      ),
    );
  }

  Widget _buildIntroSection(BuildContext context) {
    return Center(
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppTheme.cardBackColor(context).withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                  color: AppTheme.accentColor(context).withValues(alpha: 0.5),
                  width: 2),
            ),
            child: Center(
              child: Icon(
                _getGameIcon(),
                size: 40,
                color: AppTheme.textColor(context),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            gameType.displayName,
            style: AppTypography.heading(context),
          ),
          const SizedBox(height: 8),
          Text(
            _getGameTagline(),
            style: AppTypography.body(context),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  IconData _getGameIcon() {
    switch (gameType) {
      case GameType.klondike:
        return Icons.style;
      case GameType.spider:
        return Icons.pest_control;
      case GameType.freecell:
        return Icons.grid_view;
      case GameType.pyramid:
        return Icons.change_history;
      case GameType.triPeaks:
        return Icons.landscape;
      case GameType.golf:
        return Icons.golf_course;
      case GameType.yukon:
        return Icons.terrain;
      case GameType.fortyThieves:
        return Icons.shield;
      case GameType.canfield:
        return Icons.casino;
      case GameType.scorpion:
        return Icons.flare;
    }
  }

  String _getGameTagline() {
    switch (gameType) {
      case GameType.klondike:
        return 'The classic card game of patience and strategy.';
      case GameType.spider:
        return 'Build complete suits within the tableau.';
      case GameType.freecell:
        return 'Strategic play with four free cells.';
      case GameType.pyramid:
        return 'Match cards that add up to 13.';
      case GameType.triPeaks:
        return 'Clear three overlapping pyramids.';
      case GameType.golf:
        return 'Score the lowest by clearing cards.';
      case GameType.yukon:
        return 'Move any face-up card freely.';
      case GameType.fortyThieves:
        return 'A rigorous two-deck challenge.';
      case GameType.canfield:
        return 'Compact casino-style gameplay.';
      case GameType.scorpion:
        return 'Build King-to-Ace suit sequences.';
    }
  }

  Widget _buildObjectiveSection(BuildContext context) {
    return _buildSection(
      context,
      title: 'Objective',
      children: [
        Text(
          _getObjectiveText(),
          style: AppTypography.body(context),
        ),
        const SizedBox(height: 16),
        _buildHighlightBox(
          context,
          icon: Icons.flag_outlined,
          text: _getWinCondition(),
        ),
      ],
    );
  }

  String _getObjectiveText() {
    switch (gameType) {
      case GameType.klondike:
        return 'Move all 52 cards to the four foundation piles at the top-right, organized by suit from Ace to King.';
      case GameType.spider:
        return 'Build complete same-suit sequences from King to Ace within the tableau. When complete, they are automatically moved to the foundation.';
      case GameType.freecell:
        return 'Move all 52 cards to the four foundation piles, building up by suit from Ace to King. Use the four free cells to temporarily store cards.';
      case GameType.pyramid:
        return 'Remove pairs of cards that add up to 13 from the pyramid. Kings (value 13) can be removed alone.';
      case GameType.triPeaks:
        return 'Clear all cards from the three peaks by playing cards that are one rank higher or lower than the top card of the waste pile.';
      case GameType.golf:
        return 'Move all cards from the tableau to the waste pile by playing cards one rank higher or lower, regardless of suit.';
      case GameType.yukon:
        return 'Move all cards to the four foundation piles, building up by suit from Ace to King. You can move any face-up card along with all cards on top of it.';
      case GameType.fortyThieves:
        return 'Move all 104 cards (two decks) to the eight foundation piles, building up by suit from Ace to King.';
      case GameType.canfield:
        return 'Move all cards to the four foundation piles, building up by suit from the base card (first card dealt to foundation).';
      case GameType.scorpion:
        return 'Build four complete same-suit sequences from King to Ace within the tableau columns.';
    }
  }

  String _getWinCondition() {
    switch (gameType) {
      case GameType.klondike:
        return 'Win by completing all four foundation piles: ♠ ♥ ♣ ♦';
      case GameType.spider:
        return 'Win by building 8 complete King-to-Ace sequences';
      case GameType.freecell:
        return 'Win by moving all cards to the foundations: ♠ ♥ ♣ ♦';
      case GameType.pyramid:
        return 'Win by clearing all cards from the pyramid';
      case GameType.triPeaks:
        return 'Win by clearing all three peaks';
      case GameType.golf:
        return 'Win by clearing all tableau cards to the waste';
      case GameType.yukon:
        return 'Win by completing all four foundation piles: ♠ ♥ ♣ ♦';
      case GameType.fortyThieves:
        return 'Win by completing all eight foundation piles';
      case GameType.canfield:
        return 'Win by completing all four foundation piles';
      case GameType.scorpion:
        return 'Win by building 4 complete King-to-Ace suit sequences';
    }
  }

  Widget _buildGameplaySection(BuildContext context) {
    return _buildSection(
      context,
      title: 'How to Play',
      children: _getGameplayRules(context),
    );
  }

  List<Widget> _getGameplayRules(BuildContext context) {
    switch (gameType) {
      case GameType.klondike:
        return [
          _buildBulletPoint(context,
              title: 'Foundations (Top-Right)',
              description:
                  'Build up from Ace to King in the same suit. Start each foundation with an Ace.'),
          const SizedBox(height: 12),
          _buildBulletPoint(context,
              title: 'Tableau (Bottom Seven Columns)',
              description:
                  'Build down in alternating colors. Only Kings can be placed in empty tableau columns.'),
          const SizedBox(height: 12),
          _buildBulletPoint(context,
              title: 'Stock & Waste (Top-Left)',
              description:
                  'Tap the stock to draw cards. Drawn cards appear in the waste pile and can be played to tableau or foundations.'),
          const SizedBox(height: 12),
          _buildBulletPoint(context,
              title: 'Moving Cards',
              description:
                  'Drag and drop cards or tap to auto-move. You can move sequences of face-up cards in the tableau.'),
        ];

      case GameType.spider:
        return [
          _buildBulletPoint(context,
              title: 'Tableau (10 Columns)',
              description:
                  'Build down regardless of suit for movement. Only same-suit sequences can be moved as a group.'),
          const SizedBox(height: 12),
          _buildBulletPoint(context,
              title: 'Complete Sequences',
              description:
                  'When you build a complete King-to-Ace same-suit sequence, it is automatically removed.'),
          const SizedBox(height: 12),
          _buildBulletPoint(context,
              title: 'Stock (Top-Left)',
              description:
                  'Tap to deal one card to each tableau column. All columns must have at least one card.'),
          const SizedBox(height: 12),
          _buildBulletPoint(context,
              title: 'Empty Columns',
              description:
                  'Any card or sequence can be moved to an empty column.'),
        ];

      case GameType.freecell:
        return [
          _buildBulletPoint(context,
              title: 'Free Cells (Top-Left)',
              description:
                  'Four cells that can each hold one card temporarily. Use them to maneuver cards.'),
          const SizedBox(height: 12),
          _buildBulletPoint(context,
              title: 'Foundations (Top-Right)',
              description: 'Build up by suit from Ace to King.'),
          const SizedBox(height: 12),
          _buildBulletPoint(context,
              title: 'Tableau (8 Columns)',
              description:
                  'Build down in alternating colors. Any card can fill an empty column.'),
          const SizedBox(height: 12),
          _buildBulletPoint(context,
              title: 'Supermove',
              description:
                  'Move multiple cards at once based on available free cells and empty columns.'),
        ];

      case GameType.pyramid:
        return [
          _buildBulletPoint(context,
              title: 'Matching Pairs',
              description:
                  'Remove pairs that add up to 13. A=1, J=11, Q=12, K=13 (removed alone).'),
          const SizedBox(height: 12),
          _buildBulletPoint(context,
              title: 'Exposed Cards',
              description:
                  'Only fully exposed cards (not covered by others) can be matched.'),
          const SizedBox(height: 12),
          _buildBulletPoint(context,
              title: 'Stock & Waste',
              description:
                  'Draw from stock to find matching cards. Waste card can pair with pyramid cards.'),
          const SizedBox(height: 12),
          _buildBulletPoint(context,
              title: 'Card Values',
              description: 'A=1, 2-10=face value, J=11, Q=12, K=13'),
        ];

      case GameType.triPeaks:
        return [
          _buildBulletPoint(context,
              title: 'Three Peaks',
              description:
                  'Clear overlapping pyramid formations by removing one card at a time.'),
          const SizedBox(height: 12),
          _buildBulletPoint(context,
              title: 'Playing Cards',
              description:
                  'Play any exposed card that is one rank higher or lower than the waste pile top card.'),
          const SizedBox(height: 12),
          _buildBulletPoint(context,
              title: 'Wrapping',
              description:
                  'Ace can be placed on 2 or King. King can be placed on Ace or Queen.'),
          const SizedBox(height: 12),
          _buildBulletPoint(context,
              title: 'Stock',
              description: 'Draw from stock when no moves are available.'),
        ];

      case GameType.golf:
        return [
          _buildBulletPoint(context,
              title: 'Tableau (7 Columns)',
              description:
                  'Play any top card that is one rank higher or lower than the waste pile.'),
          const SizedBox(height: 12),
          _buildBulletPoint(context,
              title: 'Waste Pile',
              description:
                  'Build by playing cards ±1 rank regardless of suit.'),
          const SizedBox(height: 12),
          _buildBulletPoint(context,
              title: 'Stock',
              description:
                  'Draw when stuck. Each draw counts against your score.'),
          const SizedBox(height: 12),
          _buildBulletPoint(context,
              title: 'Scoring',
              description:
                  'Lower is better. Cards left in tableau count against you.'),
        ];

      case GameType.yukon:
        return [
          _buildBulletPoint(context,
              title: 'Free Movement',
              description:
                  'Move any face-up card with all cards above it, even if not in sequence.'),
          const SizedBox(height: 12),
          _buildBulletPoint(context,
              title: 'Tableau Building',
              description: 'Build down in alternating colors, like Klondike.'),
          const SizedBox(height: 12),
          _buildBulletPoint(context,
              title: 'Foundations',
              description: 'Build up by suit from Ace to King.'),
          const SizedBox(height: 12),
          _buildBulletPoint(context,
              title: 'Empty Columns',
              description: 'Only Kings can be placed in empty columns.'),
        ];

      case GameType.fortyThieves:
        return [
          _buildBulletPoint(context,
              title: 'Tableau (10 Columns)',
              description:
                  'Build down by suit. Only the top card of each column can be moved.'),
          const SizedBox(height: 12),
          _buildBulletPoint(context,
              title: 'Foundations (8 Piles)',
              description: 'Build up by suit from Ace to King.'),
          const SizedBox(height: 12),
          _buildBulletPoint(context,
              title: 'Stock & Waste',
              description:
                  'Draw one card at a time. Waste top card is available.'),
          const SizedBox(height: 12),
          _buildBulletPoint(context,
              title: 'Empty Columns',
              description: 'Any single card can fill an empty tableau column.'),
        ];

      case GameType.canfield:
        return [
          _buildBulletPoint(context,
              title: 'Reserve (Left)',
              description:
                  'A pile of 13 cards. Top card is always available to play.'),
          const SizedBox(height: 12),
          _buildBulletPoint(context,
              title: 'Foundations',
              description:
                  'Build up by suit, wrapping A after K. Base card determines starting rank.'),
          const SizedBox(height: 12),
          _buildBulletPoint(context,
              title: 'Tableau (4 Columns)',
              description:
                  'Build down in alternating colors, wrapping K to A.'),
          const SizedBox(height: 12),
          _buildBulletPoint(context,
              title: 'Stock',
              description: 'Draw 3 cards at a time to waste pile.'),
        ];

      case GameType.scorpion:
        return [
          _buildBulletPoint(context,
              title: 'Tableau (7 Columns)',
              description:
                  'Build down by the same suit. Move any face-up card with all cards below it.'),
          const SizedBox(height: 12),
          _buildBulletPoint(context,
              title: 'Complete Sequences',
              description:
                  'Build King-to-Ace same-suit sequences. Completed sequences are removed.'),
          const SizedBox(height: 12),
          _buildBulletPoint(context,
              title: 'Stock (3 Cards)',
              description:
                  'Deal 3 reserve cards to the first three columns when stuck.'),
          const SizedBox(height: 12),
          _buildBulletPoint(context,
              title: 'Empty Columns',
              description: 'Only Kings can fill empty columns.'),
        ];
    }
  }

  Widget _buildDifficultySection(BuildContext context) {
    return _buildSection(
      context,
      title: 'Difficulty Levels',
      children: [
        _buildDifficultyCard(context, Difficulty.easy),
        const SizedBox(height: 12),
        _buildDifficultyCard(context, Difficulty.medium),
        const SizedBox(height: 12),
        _buildDifficultyCard(context, Difficulty.hard),
      ],
    );
  }

  Widget _buildScoringSection(BuildContext context) {
    return _buildSection(
      context,
      title: 'Scoring Modes',
      children: [
        _buildScoringCard(context, ScoringMode.standard),
        const SizedBox(height: 12),
        _buildScoringCard(context, ScoringMode.vegas),
      ],
    );
  }

  Widget _buildKeyboardShortcutsSection(BuildContext context) {
    return _buildSection(
      context,
      title: 'Keyboard Shortcuts',
      children: [
        _buildShortcutItem(context, 'Tab', 'Cycle through piles'),
        _buildShortcutItem(
            context, 'Shift+Tab', 'Cycle backwards through piles'),
        _buildShortcutItem(context, 'Enter/Space', 'Select focused pile'),
        _buildShortcutItem(context, 'U or Ctrl+Z', 'Undo last move'),
        _buildShortcutItem(context, 'N', 'Start new game'),
        _buildShortcutItem(context, 'H', 'Show hint'),
        _buildShortcutItem(context, 'A', 'Toggle autoplay (if enabled)'),
        _buildShortcutItem(context, 'Esc', 'Open settings menu'),
      ],
    );
  }

  Widget _buildTipsSection(BuildContext context) {
    return _buildSection(
      context,
      title: 'Tips & Strategies',
      children: _getTips(context),
    );
  }

  List<Widget> _getTips(BuildContext context) {
    switch (gameType) {
      case GameType.klondike:
        return [
          _buildTipItem(
              context, 'Always move Aces and 2s to foundations immediately.'),
          _buildTipItem(
              context, 'Try to expose face-down cards in the tableau first.'),
          _buildTipItem(
              context, 'Keep tableau columns balanced when possible.'),
          _buildTipItem(context,
              'Don\'t rush to move cards to foundations - sometimes it\'s better to keep cards in the tableau for flexibility.'),
          _buildTipItem(context,
              'Empty tableau columns are valuable - use them to reorganize.'),
        ];

      case GameType.spider:
        return [
          _buildTipItem(
              context, 'Try to build same-suit sequences whenever possible.'),
          _buildTipItem(context,
              'Empty columns are extremely valuable - create and protect them.'),
          _buildTipItem(context, 'Avoid mixing suits unless necessary.'),
          _buildTipItem(context, 'Clear columns before dealing from stock.'),
          _buildTipItem(context, 'Plan several moves ahead before committing.'),
        ];

      case GameType.freecell:
        return [
          _buildTipItem(context, 'Keep free cells empty as long as possible.'),
          _buildTipItem(context,
              'Plan your moves - most deals are winnable with good strategy.'),
          _buildTipItem(
              context, 'Empty columns are more valuable than free cells.'),
          _buildTipItem(context, 'Move Aces and 2s to foundations early.'),
          _buildTipItem(context, 'Think several moves ahead before starting.'),
        ];

      case GameType.pyramid:
        return [
          _buildTipItem(
              context, 'Remove Kings immediately - they take up space.'),
          _buildTipItem(context, 'Try to expose cards deeper in the pyramid.'),
          _buildTipItem(
              context, 'Plan which pairs to remove to uncover key cards.'),
          _buildTipItem(context, 'Save stock draws for when truly stuck.'),
        ];

      case GameType.triPeaks:
        return [
          _buildTipItem(
              context, 'Build long runs when possible for bonus points.'),
          _buildTipItem(context, 'Plan which peak to tackle first.'),
          _buildTipItem(context,
              'Sometimes it\'s better to break a run to expose new cards.'),
          _buildTipItem(context, 'Use wildcards (if available) strategically.'),
        ];

      case GameType.golf:
        return [
          _buildTipItem(
              context, 'Build long runs to minimize draws from stock.'),
          _buildTipItem(context, 'Plan your tableau clearance order.'),
          _buildTipItem(context, 'Avoid getting stuck with face cards.'),
          _buildTipItem(
              context, 'Every card left in tableau counts against you.'),
        ];

      case GameType.yukon:
        return [
          _buildTipItem(
              context, 'Expose face-down cards as quickly as possible.'),
          _buildTipItem(
              context, 'Use the free movement rule to dig into stacks.'),
          _buildTipItem(context, 'Empty columns are valuable for Kings.'),
          _buildTipItem(
              context, 'Don\'t move cards just because you can - plan ahead.'),
        ];

      case GameType.fortyThieves:
        return [
          _buildTipItem(
              context, 'This is a difficult game - expect to lose often.'),
          _buildTipItem(
              context, 'Only single cards can move, so plan carefully.'),
          _buildTipItem(
              context, 'Create empty columns early and protect them.'),
          _buildTipItem(context,
              'Build on foundations when safe, but not too aggressively.'),
        ];

      case GameType.canfield:
        return [
          _buildTipItem(
              context, 'Empty the reserve pile as quickly as possible.'),
          _buildTipItem(context,
              'Note the foundation base card - it determines wrapping.'),
          _buildTipItem(
              context, 'Create empty tableau columns for flexibility.'),
          _buildTipItem(context,
              'Draw 3 cards at a time - plan for deep waste pile access.'),
        ];

      case GameType.scorpion:
        return [
          _buildTipItem(context, 'Expose face-down cards as priority.'),
          _buildTipItem(context, 'Build same-suit sequences from King down.'),
          _buildTipItem(
              context, 'Save the 3 reserve cards for when truly stuck.'),
          _buildTipItem(context, 'Empty columns can only hold Kings.'),
        ];
    }
  }

  Widget _buildSection(BuildContext context,
      {required String title, required List<Widget> children}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
                width: 40,
                height: 1,
                color: AppTheme.accentColor(context).withValues(alpha: 0.3)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                title.toUpperCase(),
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.5,
                  color: AppTheme.accentColor(context).withValues(alpha: 0.8),
                ),
              ),
            ),
            Expanded(
                child: Container(
                    height: 1,
                    color:
                        AppTheme.accentColor(context).withValues(alpha: 0.3))),
          ],
        ),
        const SizedBox(height: 16),
        ...children,
      ],
    );
  }

  Widget _buildBulletPoint(BuildContext context,
      {required String title, required String description}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: AppColors.gold.withValues(alpha: 0.6),
              shape: BoxShape.circle,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTypography.label(context),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: AppTypography.body(context).copyWith(
                  color: AppColors.cream.withValues(alpha: 0.8),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHighlightBox(BuildContext context,
      {required IconData icon, required String text}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.accentColor(context).withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
            color: AppTheme.accentColor(context).withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.accentColor(context), size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: AppTypography.body(context).copyWith(
                color: AppTheme.textColor(context),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDifficultyCard(BuildContext context, Difficulty difficulty) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.buttonColor(context).withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
            color: AppTheme.buttonBorderColor(context).withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.accentColor(context).withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                      color: AppTheme.accentColor(context)
                          .withValues(alpha: 0.28)),
                ),
                child: Text(
                  difficulty.shortName,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                    color: AppTheme.textColor(context),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(difficulty.displayName, style: AppTypography.label(context)),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            difficulty.fullDescriptionFor(gameType),
            style: AppTypography.body(context),
          ),
        ],
      ),
    );
  }

  Widget _buildScoringCard(BuildContext context, ScoringMode mode) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.buttonColor(context).withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
            color: AppTheme.buttonBorderColor(context).withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                mode == ScoringMode.vegas
                    ? Icons.attach_money
                    : Icons.timer_outlined,
                color: AppTheme.accentColor(context).withValues(alpha: 0.9),
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(mode.displayName, style: AppTypography.label(context)),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            mode.fullDescription,
            style: AppTypography.body(context),
          ),
        ],
      ),
    );
  }

  Widget _buildTipItem(BuildContext context, String tip) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '💡 ',
            style: TextStyle(fontSize: 16),
          ),
          Expanded(
            child: Text(
              tip,
              style: AppTypography.body(context).copyWith(
                color: AppColors.cream.withValues(alpha: 0.8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShortcutItem(
      BuildContext context, String key, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppTheme.buttonColor(context).withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                  color: AppTheme.accentColor(context).withValues(alpha: 0.3)),
            ),
            child: Text(
              key,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppTheme.accentColor(context).withValues(alpha: 0.95),
                letterSpacing: 0.5,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              description,
              style: AppTypography.body(context).copyWith(
                color: AppTheme.textColor(context),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
