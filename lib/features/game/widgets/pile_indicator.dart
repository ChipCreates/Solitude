import 'package:flutter/material.dart';
import 'package:solitude/core/theme/app_theme.dart';
import '../models/card.dart';
import 'card_widget.dart';

enum PileIndicatorType {
  tableau,
  foundation,
  stock,
  waste,
  cell,
  reserve,
  pyramid
}

class EmptyPileIndicator extends StatelessWidget {
  final double width;
  final PileIndicatorType type;
  final Suit? suit;
  final bool isHighlighted;
  final bool isHintDestination;
  final bool isHintSource;
  final bool isFocused;
  final VoidCallback? onTap;

  const EmptyPileIndicator({
    super.key,
    required this.width,
    required this.type,
    this.suit,
    this.isHighlighted = false,
    this.isHintDestination = false,
    this.isHintSource = false,
    this.isFocused = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final height = width / CardWidget.aspectRatio;
    // Match the card border radius (6% of width, same as CardWidget)
    final borderRadius = BorderRadius.circular(width * 0.06);

    // Different styling based on pile type
    Color backgroundColor;
    Color borderColor;
    double borderWidth;
    Widget? centerWidget;
    List<BoxShadow>? shadows;

    if (isFocused) {
      // Keyboard focus indicator - blue glow
      backgroundColor = Colors.blue.withValues(alpha: 0.15);
      borderColor = Colors.blue;
      borderWidth = 2.5;
      shadows = [
        BoxShadow(
          color: Colors.blue.withValues(alpha: 0.5),
          blurRadius: 12,
          spreadRadius: 2,
        ),
      ];
    } else if (isHintDestination) {
      backgroundColor = AppColors.gold.withValues(alpha: 0.2);
      borderColor = AppColors.gold;
      borderWidth = 2.5;
      shadows = [
        BoxShadow(
          color: AppColors.gold.withValues(alpha: 0.4),
          blurRadius: 16,
          spreadRadius: 3,
        ),
      ];
    } else if (isHintSource) {
      backgroundColor = AppColors.gold.withValues(alpha: 0.2);
      borderColor = AppColors.gold;
      borderWidth = 2.5;
      shadows = [
        BoxShadow(
          color: AppColors.gold.withValues(alpha: 0.4),
          blurRadius: 16,
          spreadRadius: 3,
        ),
      ];
    } else if (isHighlighted) {
      backgroundColor = AppColors.validMove.withValues(alpha: 0.2);
      borderColor = AppColors.validMove.withValues(alpha: 0.8);
      borderWidth = 2.0;
      shadows = [
        BoxShadow(
          color: AppColors.validMove.withValues(alpha: 0.3),
          blurRadius: 12,
          spreadRadius: 2,
        ),
      ];
    } else {
      switch (type) {
        case PileIndicatorType.foundation:
          backgroundColor = Colors.black.withValues(alpha: 0.15);
          borderColor = AppColors.cream.withValues(alpha: 0.15);
          borderWidth = 1.5;
          centerWidget = _buildFoundationSuit(context);
          shadows = [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ];
          break;

        case PileIndicatorType.tableau:
          backgroundColor = Colors.black.withValues(alpha: 0.1);
          borderColor = AppColors.cream.withValues(alpha: 0.1);
          borderWidth = 1.0;
          // Subtle K indicator for King placement
          centerWidget = _buildTableauIndicator(context);
          break;

        case PileIndicatorType.stock:
          backgroundColor = Colors.black.withValues(alpha: 0.2);
          borderColor = AppColors.cream.withValues(alpha: 0.2);
          borderWidth = 1.5;
          centerWidget = _buildStockIndicator(context);
          shadows = [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ];
          break;

        case PileIndicatorType.waste:
          backgroundColor = Colors.black.withValues(alpha: 0.08);
          borderColor = AppColors.cream.withValues(alpha: 0.08);
          borderWidth = 1.0;
          break;

        case PileIndicatorType.cell:
          // FreeCell's empty cell indicator
          backgroundColor = Colors.black.withValues(alpha: 0.15);
          borderColor = AppColors.cream.withValues(alpha: 0.2);
          borderWidth = 1.5;
          centerWidget = _buildCellIndicator(context);
          shadows = [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ];
          break;

        case PileIndicatorType.reserve:
          // Reserve pile indicator (Canfield)
          backgroundColor = Colors.black.withValues(alpha: 0.15);
          borderColor = AppColors.cream.withValues(alpha: 0.15);
          borderWidth = 1.5;
          centerWidget = _buildReserveIndicator(context);
          shadows = [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ];
          break;

        case PileIndicatorType.pyramid:
          // Pyramid/TriPeaks empty card slot
          backgroundColor = Colors.black.withValues(alpha: 0.08);
          borderColor = AppColors.cream.withValues(alpha: 0.08);
          borderWidth = 1.0;
          break;
      }
    }

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: borderRadius,
          border: Border.all(
            color: borderColor,
            width: borderWidth,
          ),
          boxShadow: shadows,
        ),
        child: centerWidget,
      ),
    );
  }

  Widget _buildFoundationSuit(BuildContext context) {
    if (suit == null) return const SizedBox.shrink();

    final isRed = suit == Suit.hearts || suit == Suit.diamonds;
    final color = isRed
        ? Colors.red.withValues(alpha: 0.3)
        : AppColors.cream.withValues(alpha: 0.2);

    return Center(
      child: Text(
        _suitSymbol(suit!),
        style: TextStyle(
          fontSize: width * 0.35,
          color: color,
          fontWeight: FontWeight.w300,
        ),
      ),
    );
  }

  Widget _buildTableauIndicator(BuildContext context) {
    // Subtle rounded rectangle outline suggesting card placement
    return Center(
      child: Container(
        width: width * 0.4,
        height: width * 0.5,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(width * 0.05),
          border: Border.all(
            color: AppColors.cream.withValues(alpha: 0.08),
            width: 1,
          ),
        ),
      ),
    );
  }

  Widget _buildStockIndicator(BuildContext context) {
    // Circular refresh icon to indicate tap to recycle
    return Center(
      child: Icon(
        Icons.refresh_rounded,
        size: width * 0.35,
        color: AppColors.cream.withValues(alpha: 0.25),
      ),
    );
  }

  Widget _buildCellIndicator(BuildContext context) {
    // Subtle indicator for empty FreeCell
    return Center(
      child: Container(
        width: width * 0.5,
        height: width * 0.5,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: AppColors.cream.withValues(alpha: 0.15),
            width: 1.5,
          ),
        ),
      ),
    );
  }

  Widget _buildReserveIndicator(BuildContext context) {
    // Stack-like indicator for reserve pile
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: width * 0.35,
            height: width * 0.08,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(width * 0.02),
              border: Border.all(
                color: AppColors.cream.withValues(alpha: 0.12),
                width: 1,
              ),
            ),
          ),
          const SizedBox(height: 2),
          Container(
            width: width * 0.4,
            height: width * 0.08,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(width * 0.02),
              border: Border.all(
                color: AppColors.cream.withValues(alpha: 0.15),
                width: 1,
              ),
            ),
          ),
          const SizedBox(height: 2),
          Container(
            width: width * 0.45,
            height: width * 0.08,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(width * 0.02),
              border: Border.all(
                color: AppColors.cream.withValues(alpha: 0.18),
                width: 1,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _suitSymbol(Suit suit) {
    switch (suit) {
      case Suit.hearts:
        return '♥';
      case Suit.diamonds:
        return '♦';
      case Suit.clubs:
        return '♣';
      case Suit.spades:
        return '♠';
    }
  }
}
