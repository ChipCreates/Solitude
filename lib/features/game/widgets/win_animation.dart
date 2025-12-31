import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/card.dart';
import 'package:solitude/core/theme/app_theme.dart';
import 'package:solitude/features/settings/services/settings_provider.dart';

enum WinPattern { spiral, starburst, circles, wave, fountain, scatter, vortex }

class WinAnimation extends StatefulWidget {
  final VoidCallback onComplete;
  final VoidCallback onNewGame;
  final Duration elapsed;
  final int moves;
  
  const WinAnimation({
    super.key,
    required this.onComplete,
    required this.onNewGame,
    required this.elapsed,
    required this.moves,
  });

  @override
  State<WinAnimation> createState() => _WinAnimationState();
}

class _WinAnimationState extends State<WinAnimation> with TickerProviderStateMixin {
  late AnimationController _patternController;
  late AnimationController _fadeController;
  late WinPattern _pattern;
  late List<_AnimatedCard> _cards;
  final Random _random = Random();
  
  @override
  void initState() {
    super.initState();
    
    _pattern = WinPattern.values[_random.nextInt(WinPattern.values.length)];
    _initializeCards();
    
    _patternController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );
    
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    
    _patternController.forward();
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) _fadeController.forward();
    });
  }
  
  void _initializeCards() {
    _cards = [];
    for (final suit in Suit.values) {
      for (final rank in Rank.values) {
        _cards.add(_AnimatedCard(
          card: PlayingCard(suit: suit, rank: rank, faceUp: true),
          startOffset: _getRandomStartOffset(),
          delay: _random.nextDouble() * 0.5,
        ));
      }
    }
  }
  
  Offset _getRandomStartOffset() {
    return Offset(
      _random.nextDouble() * 300 - 150,
      -100 - _random.nextDouble() * 200,
    );
  }
  
  @override
  void dispose() {
    _patternController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Animated cards background
        AnimatedBuilder(
          animation: _patternController,
          builder: (context, _) {
            return CustomPaint(
              size: Size.infinite,
              painter: _WinPatternPainter(
                pattern: _pattern,
                progress: _patternController.value,
                cards: _cards,
              ),
            );
          },
        ),
        
        // Victory overlay
        FadeTransition(
          opacity: _fadeController,
          child: Center(
            child: Container(
              margin: const EdgeInsets.all(32),
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: () {
                  final settings = Provider.of<SettingsProvider>(context, listen: false);
                  final theme = settings.currentTheme;
                  final isDark = Theme.of(context).brightness == Brightness.dark;
                  final tableColor = isDark ? theme.tableColorDark : theme.tableColorLight;
                  return tableColor.withValues(alpha: 0.95);
                }(),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.gold.withValues(alpha:0.5),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha:0.5),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'You Won!',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: AppColors.gold,
                    ),
                  ),
                  const SizedBox(height: 24),
                  _buildStatRow('Time', _formatDuration(widget.elapsed)),
                  const SizedBox(height: 8),
                  _buildStatRow('Moves', '${widget.moves}'),
                  const SizedBox(height: 32),
                  GestureDetector(
                    onTap: widget.onNewGame,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.gold.withValues(alpha:0.3),
                            AppColors.gold.withValues(alpha:0.2),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: AppColors.gold.withValues(alpha:0.5),
                        ),
                      ),
                      child: const Text(
                        'Play Again',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.cream,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
  
  Widget _buildStatRow(String label, String value) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '$label: ',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 18,
            color: AppColors.cream.withValues(alpha:0.7),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.cream,
          ),
        ),
      ],
    );
  }
  
  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
}

class _AnimatedCard {
  final PlayingCard card;
  final Offset startOffset;
  final double delay;
  
  _AnimatedCard({
    required this.card,
    required this.startOffset,
    required this.delay,
  });
}

class _WinPatternPainter extends CustomPainter {
  final WinPattern pattern;
  final double progress;
  final List<_AnimatedCard> cards;
  
  _WinPatternPainter({
    required this.pattern,
    required this.progress,
    required this.cards,
  });
  
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    
    for (int i = 0; i < cards.length; i++) {
      final card = cards[i];
      final adjustedProgress = (progress - card.delay).clamp(0.0, 1.0);
      if (adjustedProgress <= 0) continue;
      
      final position = _getPosition(
        pattern,
        i,
        cards.length,
        adjustedProgress,
        center,
        size,
      );
      
      final rotation = _getRotation(pattern, i, adjustedProgress);
      final opacity = (1.0 - adjustedProgress * 0.3).clamp(0.3, 1.0);
      
      canvas.save();
      canvas.translate(position.dx, position.dy);
      canvas.rotate(rotation);
      
      // Draw simplified card representation
      final cardRect = Rect.fromCenter(
        center: Offset.zero,
        width: 50,
        height: 70,
      );
      
      final paint = Paint()
        ..color = AppColors.cardFace.withValues(alpha:opacity);
      
      canvas.drawRRect(
        RRect.fromRectAndRadius(cardRect, const Radius.circular(4)),
        paint,
      );
      
      final borderPaint = Paint()
        ..color = (card.card.isRed ? Colors.red : Colors.black).withValues(alpha:opacity * 0.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;
      
      canvas.drawRRect(
        RRect.fromRectAndRadius(cardRect, const Radius.circular(4)),
        borderPaint,
      );
      
      canvas.restore();
    }
  }
  
  Offset _getPosition(WinPattern pattern, int index, int total, double progress, Offset center, Size size) {
    switch (pattern) {
      case WinPattern.spiral:
        final angle = progress * 4 * pi + (index / total) * 2 * pi;
        final radius = progress * size.width * 0.4;
        return center + Offset(cos(angle) * radius, sin(angle) * radius);
        
      case WinPattern.starburst:
        final angle = (index / total) * 2 * pi;
        final radius = progress * size.width * 0.6;
        return center + Offset(cos(angle) * radius, sin(angle) * radius);
        
      case WinPattern.circles:
        final ring = index ~/ 13;
        final posInRing = index % 13;
        final angle = (posInRing / 13) * 2 * pi + progress * pi;
        final radius = (ring + 1) * 80 * progress;
        return center + Offset(cos(angle) * radius, sin(angle) * radius);
        
      case WinPattern.wave:
        final x = (index / total) * size.width;
        final y = center.dy + sin(progress * 4 * pi + index * 0.3) * 100;
        return Offset(x, y + progress * 50);
        
      case WinPattern.fountain:
        final angle = (index / total - 0.5) * pi;
        final height = sin(progress * pi) * size.height * 0.5;
        final spread = progress * size.width * 0.3;
        return Offset(
          center.dx + cos(angle) * spread,
          size.height - height,
        );
        
      case WinPattern.scatter:
        final targetX = (index % 7) / 6 * size.width;
        final targetY = (index ~/ 7) / 7 * size.height;
        return Offset(
          center.dx + (targetX - center.dx) * progress,
          center.dy + (targetY - center.dy) * progress,
        );
        
      case WinPattern.vortex:
        final angle = progress * 6 * pi + (index / total) * 2 * pi;
        final radius = (1 - progress) * size.width * 0.4;
        return center + Offset(cos(angle) * radius, sin(angle) * radius);
    }
  }
  
  double _getRotation(WinPattern pattern, int index, double progress) {
    switch (pattern) {
      case WinPattern.spiral:
      case WinPattern.vortex:
        return progress * 4 * pi;
      case WinPattern.starburst:
        return index * 0.2 + progress * pi;
      default:
        return progress * pi * 0.5;
    }
  }
  
  @override
  bool shouldRepaint(covariant _WinPatternPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
