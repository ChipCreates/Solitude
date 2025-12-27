import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/difficulty.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

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
                    _buildDifficultySection(context),
                    const SizedBox(height: 32),
                    _buildScoringSection(context),
                    const SizedBox(height: 32),
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

  Widget _buildHeader(BuildContext context) {
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: AppTheme.toolbarColor(context),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha:0.2),
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
              border: Border.all(color: AppTheme.accentColor(context).withValues(alpha:0.5), width: 2),
            ),
            child: Center(
              child: Icon(
                Icons.help_outline_rounded,
                size: 40,
                color: AppTheme.textColor(context),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Klondike Solitaire',
            style: AppTypography.heading(context),
          ),
          const SizedBox(height: 8),
          Text(
            'The classic card game of patience and strategy.',
            style: AppTypography.body(context),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildObjectiveSection(BuildContext context) {
    return _buildSection(
      context,
      title: 'Objective',
      children: [
        Text(
          'Move all 52 cards to the four foundation piles at the top-right, organized by suit from Ace to King.',
          style: AppTypography.body(context),
        ),
        const SizedBox(height: 16),
        _buildHighlightBox(
          context,
          icon: Icons.flag_outlined,
          text: 'Win by completing all four foundation piles: ♠ ♥ ♣ ♦',
        ),
      ],
    );
  }

  Widget _buildGameplaySection(BuildContext context) {
    return _buildSection(
      context,
      title: 'How to Play',
      children: [
        _buildBulletPoint(
          context,
          title: 'Foundations (Top-Right)',
          description: 'Build up from Ace to King in the same suit. Start each foundation with an Ace.',
        ),
        const SizedBox(height: 12),
        _buildBulletPoint(
          context,
          title: 'Tableau (Bottom Seven Columns)',
          description: 'Build down in alternating colors. Only Kings can be placed in empty tableau columns.',
        ),
        const SizedBox(height: 12),
        _buildBulletPoint(
          context,
          title: 'Stock & Waste (Top-Left)',
          description: 'Tap the stock to draw cards. Drawn cards appear in the waste pile and can be played to tableau or foundations.',
        ),
        const SizedBox(height: 12),
        _buildBulletPoint(
          context,
          title: 'Moving Cards',
          description: 'Drag and drop cards or tap to auto-move. You can move sequences of face-up cards in the tableau.',
        ),
      ],
    );
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
        _buildShortcutItem(context, 'Shift+Tab', 'Cycle backwards through piles'),
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
      children: [
        _buildTipItem(context, 'Always move Aces and 2s to foundations immediately.'),
        _buildTipItem(context, 'Try to expose face-down cards in the tableau first.'),
        _buildTipItem(context, 'Keep tableau columns balanced when possible.'),
        _buildTipItem(context, 'Don\'t rush to move cards to foundations - sometimes it\'s better to keep cards in the tableau for flexibility.'),
        _buildTipItem(context, 'Empty tableau columns are valuable - try to create them to reorganize your cards.'),
        _buildTipItem(context, 'Use the hint button (💡) when stuck to see available moves.'),
      ],
    );
  }

  Widget _buildSection(BuildContext context, {required String title, required List<Widget> children}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(width: 40, height: 1, color: AppTheme.accentColor(context).withValues(alpha:0.3)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                title.toUpperCase(),
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.5,
                  color: AppTheme.accentColor(context).withValues(alpha:0.8),
                ),
              ),
            ),
            Expanded(child: Container(height: 1, color: AppTheme.accentColor(context).withValues(alpha:0.3))),
          ],
        ),
        const SizedBox(height: 16),
        ...children,
      ],
    );
  }

  Widget _buildBulletPoint(BuildContext context, {required String title, required String description}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: AppColors.gold.withValues(alpha:0.6),
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
                  color: AppColors.cream.withValues(alpha:0.8),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHighlightBox(BuildContext context, {required IconData icon, required String text}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.accentColor(context).withValues(alpha:0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.accentColor(context).withValues(alpha:0.2)),
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
        color: AppTheme.buttonColor(context).withValues(alpha:0.3),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.buttonBorderColor(context).withValues(alpha:0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.accentColor(context).withValues(alpha:0.18),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: AppTheme.accentColor(context).withValues(alpha:0.28)),
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
            difficulty.fullDescription,
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
        color: AppTheme.buttonColor(context).withValues(alpha:0.3),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.buttonBorderColor(context).withValues(alpha:0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                mode == ScoringMode.vegas ? Icons.attach_money : Icons.timer_outlined,
                color: AppTheme.accentColor(context).withValues(alpha:0.9),
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
                color: AppColors.cream.withValues(alpha:0.8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShortcutItem(BuildContext context, String key, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppTheme.buttonColor(context).withValues(alpha:0.5),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: AppTheme.accentColor(context).withValues(alpha:0.3)),
            ),
            child: Text(
              key,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppTheme.accentColor(context).withValues(alpha:0.95),
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

  // Difficulty colors are now theme-driven; helper removed.
  // Left here in case specialized coloring is needed later.
}
