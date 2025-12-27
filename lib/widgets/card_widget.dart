import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/card.dart';
import '../theme/app_theme.dart';
import '../services/settings_provider.dart';
import 'svg_card_renderer.dart';
import 'card_gloss_painter.dart';

class CardWidget extends StatelessWidget {
  final PlayingCard card;
  final double width;
  final double height;
  final bool isSelected;
  final bool isHighlighted;
  final bool isHintDestination;
  final bool isDragging;
  final VoidCallback? onTap;
  final VoidCallback? onDoubleTap;

  const CardWidget({
    super.key,
    required this.card,
    required this.width,
    this.isSelected = false,
    this.isHighlighted = false,
    this.isHintDestination = false,
    this.isDragging = false,
    this.onTap,
    this.onDoubleTap,
  }) : height = width / aspectRatio;

  static const double aspectRatio = 2.5 / 3.5;

  // Static shadow configurations for performance
  static final _baseShadowsNormal = <BoxShadow>[
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.4),
      blurRadius: 1,
      spreadRadius: 0,
      offset: const Offset(0, 1),
    ),
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.25),
      blurRadius: 2,
      spreadRadius: 0,
      offset: const Offset(0, 1.5),
    ),
  ];

  static final _baseShadowsDragging = <BoxShadow>[
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.4),
      blurRadius: 1,
      spreadRadius: 0,
      offset: const Offset(0, 1),
    ),
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.35),
      blurRadius: 3,
      spreadRadius: 0,
      offset: const Offset(0, 3),
    ),
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.2),
      blurRadius: 20,
      spreadRadius: 2,
      offset: const Offset(0, 12),
    ),
  ];

  static final _baseShadowsSelected = <BoxShadow>[
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.4),
      blurRadius: 1,
      spreadRadius: 0,
      offset: const Offset(0, 1),
    ),
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.25),
      blurRadius: 2,
      spreadRadius: 0,
      offset: const Offset(0, 1.5),
    ),
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.15),
      blurRadius: 12,
      spreadRadius: 1,
      offset: const Offset(0, 6),
    ),
  ];

  static final _selectionGlow = BoxShadow(
    color: AppColors.gold.withValues(alpha: 0.6),
    blurRadius: 16,
    spreadRadius: 3,
  );

  static final _hintGlow = BoxShadow(
    color: AppColors.gold.withValues(alpha: 0.5),
    blurRadius: 20,
    spreadRadius: 4,
  );

  static final _highlightGlow = BoxShadow(
    color: AppColors.validMove.withValues(alpha: 0.6),
    blurRadius: 16,
    spreadRadius: 3,
  );

  /// Builds the appropriate shadow list based on card state
  /// Returns a cached list when possible to avoid allocation
  List<BoxShadow> _buildShadows() {
    // Fast path: normal state with no glows (most common case)
    if (!isDragging && !isSelected && !isHighlighted && !isHintDestination) {
      return _baseShadowsNormal;
    }

    // Fast path: dragging with no glows
    if (isDragging && !isSelected && !isHighlighted && !isHintDestination) {
      return _baseShadowsDragging;
    }

    // Slow path: need to build custom shadow list with glows
    final shadows = List<BoxShadow>.from(
      isDragging ? _baseShadowsDragging : (isSelected ? _baseShadowsSelected : _baseShadowsNormal),
    );

    if (isSelected) shadows.add(_selectionGlow);
    if (isHintDestination) shadows.add(_hintGlow);
    if (isHighlighted) shadows.add(_highlightGlow);

    return shadows;
  }

  @override
  Widget build(BuildContext context) {
    final borderRadius = BorderRadius.circular(width * 0.06);
    final innerBorderRadius = BorderRadius.circular(width * 0.03);

    // Border/padding size for the white card border (6%)
    final borderSize = width * 0.06;

    // Get optimized shadow list based on card state
    final shadows = _buildShadows();
    
    // Lift transform for selection/drag states
    final verticalOffset = isDragging ? -8.0 : (isSelected ? -4.0 : 0.0);
    
    // Determine highlight border color (inside the dark edge)
    Color? highlightBorderColor;
    double highlightBorderWidth = 0;
    if (isSelected || isHintDestination) {
      highlightBorderColor = AppColors.gold;
      highlightBorderWidth = 2.0;
    } else if (isHighlighted) {
      highlightBorderColor = AppColors.validMove;
      highlightBorderWidth = 2.0;
    }
    
    return RepaintBoundary(
      child: GestureDetector(
        onTap: onTap,
        onDoubleTap: onDoubleTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOutCubic,
          width: width,
          height: height,
          transform: Matrix4.identity()..translateByDouble(0.0, verticalOffset, 0.0, 1.0),
          decoration: BoxDecoration(
            borderRadius: borderRadius,
            boxShadow: shadows,
          ),
          child: Container(
            // Dark outer edge
            decoration: BoxDecoration(
              color: const Color(0xFF2A2A2A),
              borderRadius: borderRadius,
            ),
            padding: const EdgeInsets.all(1.0),
            child: Container(
              // White/cream card border background
              decoration: BoxDecoration(
                color: card.faceUp ? AppColors.cardFace : Colors.white,
                borderRadius: BorderRadius.circular(width * 0.055),
                border: highlightBorderColor != null
                    ? Border.all(color: highlightBorderColor, width: highlightBorderWidth)
                    : null,
              ),
              padding: EdgeInsets.all(borderSize - 1.0),
              child: ClipRRect(
                borderRadius: innerBorderRadius,
                child: _buildCardContent(context),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCardContent(BuildContext context) {
    final settings = Provider.of<SettingsProvider>(context);
    final theme = settings.currentTheme;
    final overlayIntensity = settings.currentOverlayIntensity;

    // Only apply overlay to face-up cards
    // Invert the intensity: 0% intensity = no tint, 100% intensity = full tint
    if (card.faceUp && overlayIntensity > 0.01) {
      return ColorFiltered(
        colorFilter: ColorFilter.mode(
          theme.cardFaceOverlay.withValues(alpha: 1.0 - overlayIntensity),
          theme.overlayBlendMode,
        ),
        child: CustomPaint(
          painter: CardGlossPainter(
            isFaceUp: card.faceUp,
            borderRadius: BorderRadius.circular(width * 0.03),
          ),
          child: SvgCardRenderer(
            card: card,
            width: width - (width * 0.06 * 2) - 2.0,
          ),
        ),
      );
    }

    // No overlay for face-down cards or when intensity is near zero
    return CustomPaint(
      painter: CardGlossPainter(
        isFaceUp: card.faceUp,
        borderRadius: BorderRadius.circular(width * 0.03),
      ),
      child: SvgCardRenderer(
        card: card,
        width: width - (width * 0.06 * 2) - 2.0,
      ),
    );
  }
}
