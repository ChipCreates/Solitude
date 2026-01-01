import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:solitude/core/theme/app_theme.dart';
import 'package:solitude/core/widgets/game_button.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

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
                    _buildAppInfo(context),
                    const SizedBox(height: 32),
                    _buildLicenseSection(context),
                    const SizedBox(height: 32),
                    _buildCreditsSection(context),
                    const SizedBox(height: 32),
                    _buildSourceSection(context),
                    const SizedBox(height: 32),
                    _buildPrivacySection(context),
                    const SizedBox(height: 16),
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
          Text('About', style: AppTypography.subheading(context)),
        ],
      ),
    );
  }

  Widget _buildAppInfo(BuildContext context) {
    return Center(
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.feltMedium,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                  color: AppColors.gold.withValues(alpha: 0.5), width: 2),
            ),
            child: const Center(
              child: Text(
                '♠',
                style: TextStyle(fontSize: 40, color: AppColors.cream),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Solitude',
            style: AppTypography.heading(context),
          ),
          const SizedBox(height: 4),
          Text(
            'Version 1.0.0',
            style: AppTypography.stat(context),
          ),
          const SizedBox(height: 8),
          Text(
            'A beautiful, open-source solitaire game.',
            style: AppTypography.body(context),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildLicenseSection(BuildContext context) {
    return _buildSection(
      context,
      title: 'License',
      children: [
        Text(
          'Solitude is free software licensed under the GNU General Public License v3.0 (GPL-3.0).',
          style: AppTypography.body(context),
        ),
        const SizedBox(height: 16),
        Text(
          'You are free to:',
          style: AppTypography.label(context),
        ),
        const SizedBox(height: 8),
        _buildBulletPoint(context, 'Use this software for any purpose'),
        _buildBulletPoint(context, 'Study how it works and modify it'),
        _buildBulletPoint(context, 'Distribute copies'),
        _buildBulletPoint(context, 'Distribute your modified versions'),
        const SizedBox(height: 16),
        Text(
          'Under the condition that you preserve the same freedoms for others.',
          style: AppTypography.body(context).copyWith(
            fontStyle: FontStyle.italic,
            color: AppColors.cream.withValues(alpha: 0.8),
          ),
        ),
        const SizedBox(height: 16),
        Center(
          child: GameButton(
            label: 'View Full License',
            onPressed: () => _showLicenseText(context),
          ),
        ),
      ],
    );
  }

  Widget _buildCreditsSection(BuildContext context) {
    return _buildSection(
      context,
      title: 'Credits',
      children: [
        _buildCreditItem(
          context,
          title: 'Card Graphics',
          description:
              'SVG Playing Cards by David Bellot, maintained by Huub de Beer',
          license: 'Licensed under LGPL 2.1+',
          url: 'github.com/htdebeer/SVG-cards',
        ),
        const SizedBox(height: 16),
        _buildCreditItem(
          context,
          title: 'Font',
          description: 'Inter by Rasmus Andersson',
          license: 'Licensed under SIL Open Font License',
          url: 'rsms.me/inter',
        ),
      ],
    );
  }

  Widget _buildSourceSection(BuildContext context) {
    return _buildSection(
      context,
      title: 'Source Code',
      children: [
        Text(
          'The complete source code for Solitude is available on GitHub.',
          style: AppTypography.body(context),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.feltDarkest.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.cream.withValues(alpha: 0.1)),
          ),
          child: Row(
            children: [
              Icon(Icons.code,
                  color: AppColors.cream.withValues(alpha: 0.7), size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'github.com/plotworx/solitude',
                  style: AppTypography.body(context).copyWith(
                    fontFamily: 'monospace',
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPrivacySection(BuildContext context) {
    return _buildSection(
      context,
      title: 'Privacy & Data',
      children: [
        Text(
          'Solitude respects your privacy. All game data is stored locally on your device.',
          style: AppTypography.body(context),
        ),
        const SizedBox(height: 12),
        _buildBulletPoint(context, 'No personal information is collected'),
        _buildBulletPoint(context, 'No data is sent to external servers'),
        _buildBulletPoint(context, 'No analytics or tracking'),
        _buildBulletPoint(
            context, 'Game stats and progress stay on your device'),
        const SizedBox(height: 16),
        Center(
          child: TextButton.icon(
            onPressed: () => _launchPrivacyPolicy(context),
            icon: const Icon(Icons.privacy_tip_outlined, color: AppColors.gold),
            label: Text(
              'Privacy Policy',
              style:
                  AppTypography.label(context).copyWith(color: AppColors.gold),
            ),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: BorderSide(color: AppColors.gold.withValues(alpha: 0.3)),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _launchPrivacyPolicy(BuildContext context) async {
    const url = 'https://github.com/plotworx/solitude/blob/main/PRIVACY.md';
    final uri = Uri.parse(url);

    try {
      final canLaunch = await canLaunchUrl(uri);
      if (canLaunch) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Privacy Policy: $url'),
              duration: const Duration(seconds: 5),
              action: SnackBarAction(
                label: 'Copy',
                onPressed: () {
                  // Could implement clipboard copy here
                },
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not open Privacy Policy. Visit: $url'),
            duration: Duration(seconds: 5),
          ),
        );
      }
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
                color: AppColors.cream.withValues(alpha: 0.2)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(title, style: AppTypography.subheading(context)),
            ),
            Expanded(
                child: Container(
                    height: 1, color: AppColors.cream.withValues(alpha: 0.2))),
          ],
        ),
        const SizedBox(height: 16),
        ...children,
      ],
    );
  }

  Widget _buildBulletPoint(BuildContext context, String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('• ', style: AppTypography.body(context)),
          Expanded(child: Text(text, style: AppTypography.body(context))),
        ],
      ),
    );
  }

  Widget _buildCreditItem(
    BuildContext context, {
    required String title,
    required String description,
    required String license,
    required String url,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.feltDarkest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.cream.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTypography.label(context)),
          const SizedBox(height: 4),
          Text(description, style: AppTypography.body(context)),
          const SizedBox(height: 4),
          Text(
            license,
            style: AppTypography.stat(context)
                .copyWith(fontStyle: FontStyle.italic),
          ),
          const SizedBox(height: 4),
          Text(
            url,
            style: AppTypography.body(context).copyWith(color: AppColors.gold),
          ),
        ],
      ),
    );
  }

  void _showLicenseText(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 600, maxHeight: 500),
          decoration: BoxDecoration(
            color: AppColors.feltDarkest.withValues(alpha: 0.98),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.gold.withValues(alpha: 0.3)),
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('GNU GPL v3.0',
                        style: AppTypography.subheading(context)),
                    IconButton(
                      icon: const Icon(Icons.close, color: AppColors.cream),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    _gplSummary,
                    style: AppTypography.body(context).copyWith(height: 1.6),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

const _gplSummary = '''
GNU GENERAL PUBLIC LICENSE
Version 3, 29 June 2007

Copyright © 2007 Free Software Foundation, Inc.

Everyone is permitted to copy and distribute verbatim copies of this license document, but changing it is not allowed.

PREAMBLE

The GNU General Public License is a free, copyleft license for software and other kinds of works.

The licenses for most software and other practical works are designed to take away your freedom to share and change the works. By contrast, the GNU General Public License is intended to guarantee your freedom to share and change all versions of a program--to make sure it remains free software for all its users.

When we speak of free software, we are referring to freedom, not price. Our General Public Licenses are designed to make sure that you have the freedom to distribute copies of free software (and charge for them if you wish), that you receive source code or can get it if you want it, that you can change the software or use pieces of it in new free programs, and that you know you can do these things.

To protect your rights, we need to prevent others from denying you these rights or asking you to surrender the rights. Therefore, you have certain responsibilities if you distribute copies of the software, or if you modify it: responsibilities to respect the freedom of others.

For the complete license text, visit:
https://www.gnu.org/licenses/gpl-3.0.html
''';
