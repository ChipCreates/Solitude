import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import '../models/card.dart';
import 'package:solitude/core/theme/app_theme.dart';
import 'package:solitude/features/settings/services/settings_provider.dart';
import 'card_gloss_painter.dart';

class CardWidget extends StatefulWidget {
  final PlayingCard card;
  final double width;
  final double height;
  final bool isSelected;
  final bool isHighlighted;
  final bool isHintDestination;
  final bool isHintSource;
  final bool isDragging;
  final bool? overrideFaceUp;
  final VoidCallback? onTap;
  final VoidCallback? onDoubleTap;

  const CardWidget({
    super.key,
    required this.card,
    required this.width,
    this.isSelected = false,
    this.isHighlighted = false,
    this.isHintDestination = false,
    this.isHintSource = false,
    this.isDragging = false,
    this.overrideFaceUp,
    this.onTap,
    this.onDoubleTap,
  }) : height = width / aspectRatio;

  static const double aspectRatio = 2.5 / 3.5;

  static final _baseShadowsNormal = <BoxShadow>[
    BoxShadow(color: Colors.black.withValues(alpha: 0.4), blurRadius: 1, offset: const Offset(0, 1)),
    BoxShadow(color: Colors.black.withValues(alpha: 0.25), blurRadius: 2, offset: const Offset(0, 1.5)),
  ];
  static final _baseShadowsDragging = <BoxShadow>[
    BoxShadow(color: Colors.black.withValues(alpha: 0.4), blurRadius: 1, offset: const Offset(0, 1)),
    BoxShadow(color: Colors.black.withValues(alpha: 0.35), blurRadius: 3, offset: const Offset(0, 3)),
    BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 20, spreadRadius: 2, offset: const Offset(0, 12)),
  ];
  static final _baseShadowsSelected = <BoxShadow>[
    BoxShadow(color: Colors.black.withValues(alpha: 0.4), blurRadius: 1, offset: const Offset(0, 1)),
    BoxShadow(color: Colors.black.withValues(alpha: 0.25), blurRadius: 2, offset: const Offset(0, 1.5)),
    BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 12, spreadRadius: 1, offset: const Offset(0, 6)),
  ];
  static final _selectionGlow = BoxShadow(color: AppColors.gold.withValues(alpha: 0.6), blurRadius: 16, spreadRadius: 3);
  static final _hintGlow = BoxShadow(color: AppColors.gold.withValues(alpha: 0.5), blurRadius: 20, spreadRadius: 4);
  static final _highlightGlow = BoxShadow(color: AppColors.validMove.withValues(alpha: 0.6), blurRadius: 16, spreadRadius: 3);

  @override
  State<CardWidget> createState() => _CardWidgetState();
}

class _CardWidgetState extends State<CardWidget> with TickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 300));
    final effectiveFaceUp = widget.overrideFaceUp ?? widget.card.faceUp;
    _controller.value = effectiveFaceUp ? 1.0 : 0.0;
  }

  @override
  void didUpdateWidget(covariant CardWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    final oldEffective = oldWidget.overrideFaceUp ?? oldWidget.card.faceUp;
    final newEffective = widget.overrideFaceUp ?? widget.card.faceUp;
    if (newEffective != oldEffective) {
      if (newEffective) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final borderRadius = BorderRadius.circular(widget.width * 0.06);
    final innerBorderRadius = BorderRadius.circular(widget.width * 0.03);
    final borderSize = widget.width * 0.06;
    final shadows = _buildShadows();
    final verticalOffset = widget.isDragging ? -8.0 : (widget.isSelected ? -4.0 : 0.0);

    Color? highlightBorderColor;
    double highlightBorderWidth = 0;
    if (widget.isSelected || widget.isHintDestination || widget.isHintSource) {
      highlightBorderColor = AppColors.gold;
      highlightBorderWidth = 2.0;
    } else if (widget.isHighlighted) {
      highlightBorderColor = AppColors.validMove;
      highlightBorderWidth = 2.0;
    }

    return RepaintBoundary(
      child: GestureDetector(
        onTap: widget.onTap,
        onDoubleTap: widget.onDoubleTap,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            final angle = _controller.value * math.pi;
            final isShowingFront = angle >= (math.pi / 2);
            return Transform(
              transform: Matrix4.identity()
                ..setEntry(3, 2, 0.001)
                ..rotateY(angle)
                ..multiply(Matrix4.translationValues(0.0, verticalOffset, 0.0)),
              alignment: Alignment.center,
              child: Container(
                width: widget.width,
                height: widget.height,
                decoration: BoxDecoration(borderRadius: borderRadius, boxShadow: shadows),
                child: Container(
                  decoration: BoxDecoration(color: const Color(0xFF2A2A2A), borderRadius: borderRadius),
                  padding: const EdgeInsets.all(1.0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: isShowingFront ? AppColors.cardFace : Colors.white,
                      borderRadius: BorderRadius.circular(widget.width * 0.055),
                      border: highlightBorderColor != null
                          ? Border.all(color: highlightBorderColor, width: highlightBorderWidth)
                          : null,
                    ),
                    padding: EdgeInsets.all(borderSize - 1.0),
                    child: ClipRRect(
                      borderRadius: innerBorderRadius,
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          Widget content = _buildCardContent(context, constraints, isShowingFront);
                          if (isShowingFront) {
                            content = Transform(
                              transform: Matrix4.rotationY(math.pi),
                              alignment: Alignment.center,
                              child: content,
                            );
                          }
                          return content;
                        },
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  List<BoxShadow> _buildShadows() {
    if (!widget.isDragging && !widget.isSelected && !widget.isHighlighted && !widget.isHintDestination) return CardWidget._baseShadowsNormal;
    if (widget.isDragging && !widget.isSelected && !widget.isHighlighted && !widget.isHintDestination) return CardWidget._baseShadowsDragging;
    final shadows = List<BoxShadow>.from(widget.isDragging ? CardWidget._baseShadowsDragging : (widget.isSelected ? CardWidget._baseShadowsSelected : CardWidget._baseShadowsNormal));
    if (widget.isSelected) shadows.add(CardWidget._selectionGlow);
    if (widget.isHintDestination || widget.isHintSource) shadows.add(CardWidget._hintGlow);
    if (widget.isHighlighted) shadows.add(CardWidget._highlightGlow);
    return shadows;
  }

  Widget _buildCardContent(BuildContext context, BoxConstraints constraints, bool overrideFaceUp) {
    final settings = Provider.of<SettingsProvider>(context);
    final theme = settings.currentTheme;
    final overlayIntensity = settings.currentOverlayIntensity;

    Widget content;
    if (!overrideFaceUp) {
      final String variant = settings.cardBackVariant;
      String pattern;
      if (variant == 'back') {
        pattern = 'diamond';
      } else if (variant == 'alternate') {
        pattern = 'crosshatch';
      } else {
        pattern = variant;
      }

      final Color? backColor = settings.cardBackColored ? _hexToColor(settings.cardBackColor) : null;
      content = _buildCardBack(constraints, pattern, backColor);
    } else if (widget.card.rank == Rank.jack || widget.card.rank == Rank.queen || widget.card.rank == Rank.king) {
      content = _buildFaceCard(constraints);
    } else {
      content = _buildNumberCard(constraints);
    }

    content = CustomPaint(
      painter: CardGlossPainter(isFaceUp: overrideFaceUp, borderRadius: BorderRadius.circular(widget.width * 0.03)),
      child: content,
    );

    if (overrideFaceUp && overlayIntensity > 0.01) {
      content = ColorFiltered(
        colorFilter: ColorFilter.mode(
          theme.cardFaceOverlay.withValues(alpha: 1.0 - overlayIntensity),
          theme.overlayBlendMode,
        ),
        child: content,
      );
    }
    return content;
  }

  Widget _buildCardBack(BoxConstraints constraints, String pattern, Color? color) {
    // 1. Base Painter
    Widget backLayer;
    if (pattern == 'art_deco') {
      backLayer = CustomPaint(
        size: Size(constraints.maxWidth, constraints.maxHeight),
        painter: ArtDecoCardBackPainter(primaryColor: color ?? Colors.orange),
      );
    } else {
      backLayer = CustomPaint(
        size: Size(constraints.maxWidth, constraints.maxHeight),
        painter: CardBackPainter(primaryColor: color ?? Colors.blue, pattern: pattern),
      );
    }

    // 2. SVG Overlay
    // 'spade' = Single Large Center Spade
    if (pattern == 'spade') {
      final double emblemSize = constraints.maxWidth * 0.70;
      return Stack(
        children: [
          backLayer,
          Center(
            child: Transform.translate(
              offset: Offset(0, -emblemSize * 0.05), // Optical adjustment
              child: SvgPicture.asset(
                'assets/cards/spade.svg',
                width: emblemSize,
                height: emblemSize,
                colorFilter: ColorFilter.mode((color ?? Colors.blue).withValues(alpha: 0.5), BlendMode.srcATop),
              ),
            ),
          ),
        ],
      );
    }

    // 'double' = Two Centered Spades
    if (pattern == 'double') {
      final double emblemSize = constraints.maxWidth * 0.45;
      return Stack(
        children: [
          backLayer,
          // Top Spade
          Positioned(
            left: (constraints.maxWidth - emblemSize) / 2,
            top: (constraints.maxHeight * 0.30) - (emblemSize / 2),
            child: SvgPicture.asset(
              'assets/cards/spade.svg',
              width: emblemSize,
              height: emblemSize,
              colorFilter: ColorFilter.mode((color ?? Colors.blue).withValues(alpha: 0.5), BlendMode.srcATop),
            ),
          ),
          // Bottom Spade
          Positioned(
            left: (constraints.maxWidth - emblemSize) / 2,
            top: (constraints.maxHeight * 0.70) - (emblemSize / 2),
            child: Transform.rotate(
              angle: math.pi,
              child: SvgPicture.asset(
                'assets/cards/spade.svg',
                width: emblemSize,
                height: emblemSize,
                colorFilter: ColorFilter.mode((color ?? Colors.blue).withValues(alpha: 0.5), BlendMode.srcATop),
              ),
            ),
          ),
        ],
      );
    }

    return backLayer;
  }

  Widget _buildFaceCard(BoxConstraints constraints) {
    final suitColor = widget.card.isRed ? Colors.red : Colors.black;
    final rankText = widget.card.displayRank;
    String assetName;
    switch (widget.card.rank) {
      case Rank.king: assetName = 'king.svg'; break;
      case Rank.queen: assetName = 'queen.svg'; break;
      case Rank.jack: assetName = 'jack.svg'; break;
      default: assetName = 'joker.svg'; break;
    }

    return Stack(
      children: [
        // 1. SVG Face Image
        // Aligned Bottom-Left, 75% width
        Align(
          alignment: Alignment.bottomLeft,
          child: Padding(
            padding: EdgeInsets.zero,
            child: SvgPicture.asset(
              'assets/cards/$assetName',
              fit: BoxFit.contain,
              width: constraints.maxWidth * 0.75, 
              height: constraints.maxHeight * 0.85, 
              alignment: Alignment.bottomLeft,
              placeholderBuilder: (context) => Center(child: CircularProgressIndicator(color: suitColor)),
            ),
          ),
        ),
        // 2. Corners
        _buildCornerRank(top: true, rankText: rankText, suitText: widget.card.displaySuit, suitColor: suitColor),
        _buildCornerRank(top: false, rankText: rankText, suitText: widget.card.displaySuit, suitColor: suitColor),
      ],
    );
  }

  Widget _buildNumberCard(BoxConstraints constraints) {
    final isCompact = constraints.maxWidth < 60;
    final suitColor = widget.card.isRed ? Colors.red : Colors.black;
    final rankText = widget.card.displayRank;
    final suitText = widget.card.displaySuit;

    // Ace of Spades Special
    if (!isCompact && widget.card.rank == Rank.ace && widget.card.suit == Suit.spades) {
       return Stack(
        children: [
          _buildCornerRank(top: true, rankText: rankText, suitText: suitText, suitColor: suitColor),
          _buildCornerRank(top: false, rankText: rankText, suitText: suitText, suitColor: suitColor),
          Center(
            child: SvgPicture.asset(
              'assets/cards/spade.svg',
              width: constraints.maxWidth * 0.6,
              height: constraints.maxWidth * 0.6,
              // If your new spade.svg has a white bg, you might not want this filter.
              // However, typically the Ace pip on the face is just the black ink.
              // If your SVG has a white block background, remove this line:
              colorFilter: const ColorFilter.mode(Colors.black, BlendMode.srcIn),
            ),
          ),
        ],
      );
    }

    if (isCompact) {
      return Stack(
        children: [
          _buildCornerRank(top: true, rankText: rankText, suitText: suitText, suitColor: suitColor),
          _buildCornerRank(top: false, rankText: rankText, suitText: suitText, suitColor: suitColor),
          Center(child: Text(suitText, style: TextStyle(color: suitColor, fontSize: constraints.maxWidth * 0.4))),
        ],
      );
    } else {
      return Stack(
        children: [
          _buildCornerRank(top: true, rankText: rankText, suitText: suitText, suitColor: suitColor),
          _buildCornerRank(top: false, rankText: rankText, suitText: suitText, suitColor: suitColor),
          ..._buildPips(constraints, suitColor),
        ],
      );
    }
  }

  Widget _buildCornerRank({required bool top, required String rankText, required String suitText, required Color suitColor}) {
    return Positioned(
      top: top ? 4 : null, left: top ? 4 : null,
      bottom: !top ? 4 : null, right: !top ? 4 : null,
      child: Transform.rotate(
        angle: top ? 0 : math.pi,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(rankText, style: TextStyle(color: suitColor, fontSize: top ? 16 : 12, fontFamily: 'Cinzel', fontWeight: FontWeight.bold)),
            Text(suitText, style: TextStyle(color: suitColor, fontSize: top ? 16 : 12)),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildPips(BoxConstraints constraints, Color suitColor) {
    final rank = widget.card.rank;
    final suitText = widget.card.displaySuit;
    final w = constraints.maxWidth;
    final pipSize = w * 0.22;
    final positions = _getPipPositions(rank, constraints);
    return positions.map((pos) => Positioned(
      left: pos.dx, top: pos.dy,
      width: pipSize, height: pipSize,
      child: Center(
        child: Text(suitText, style: TextStyle(color: suitColor, fontSize: pipSize, height: 1.0)),
      ),
    )).toList();
  }

  Color _hexToColor(String hex) {
    hex = hex.replaceFirst('#', '');
    if (hex.length == 3) hex = hex.split('').map((c) => '$c$c').join();
    return Color(int.parse('FF$hex', radix: 16));
  }

  List<Offset> _getPipPositions(Rank rank, BoxConstraints constraints) {
    final w = constraints.maxWidth;
    final h = constraints.maxHeight;
    final centerX = w / 2;
    final centerY = h / 2;
    final hp = (w * 0.22) / 2;
    final xLeft = w * 0.25; final xRight = w * 0.75; final xMid = centerX;
    final ySpreadTop = centerY - h * 0.35; final ySpreadBottom = centerY + h * 0.35;
    final ySideStep = (ySpreadBottom - ySpreadTop) / 3;
    final ySide2 = ySpreadTop + ySideStep; final ySide3 = ySpreadTop + 2 * ySideStep;
    final yStandardTop = h * 0.25; final yStandardBottom = h * 0.75;

    switch (rank) {
      case Rank.ace: return [Offset(xMid - hp, centerY - hp)];
      case Rank.two: return [Offset(xMid - hp, h * 0.2 - hp), Offset(xMid - hp, h * 0.8 - hp)];
      case Rank.three: return [Offset(xMid - hp, h * 0.2 - hp), Offset(xMid - hp, centerY - hp), Offset(xMid - hp, h * 0.8 - hp)];
      case Rank.four: return [Offset(xLeft - hp, yStandardTop - hp), Offset(xRight - hp, yStandardTop - hp), Offset(xLeft - hp, yStandardBottom - hp), Offset(xRight - hp, yStandardBottom - hp)];
      case Rank.five: return [Offset(xLeft - hp, yStandardTop - hp), Offset(xRight - hp, yStandardTop - hp), Offset(xMid - hp, centerY - hp), Offset(xLeft - hp, yStandardBottom - hp), Offset(xRight - hp, yStandardBottom - hp)];
      case Rank.six: return [Offset(xLeft - hp, yStandardTop - hp), Offset(xRight - hp, yStandardTop - hp), Offset(xLeft - hp, centerY - hp), Offset(xRight - hp, centerY - hp), Offset(xLeft - hp, yStandardBottom - hp), Offset(xRight - hp, yStandardBottom - hp)];
      case Rank.seven: return [Offset(xLeft - hp, ySpreadTop - hp), Offset(xRight - hp, ySpreadTop - hp), Offset(xLeft - hp, centerY - hp), Offset(xRight - hp, centerY - hp), Offset(xLeft - hp, ySpreadBottom - hp), Offset(xRight - hp, ySpreadBottom - hp), Offset(xMid - hp, (ySpreadTop + centerY) / 2 - hp)];
      case Rank.eight: return [Offset(xLeft - hp, ySpreadTop - hp), Offset(xRight - hp, ySpreadTop - hp), Offset(xLeft - hp, centerY - hp), Offset(xRight - hp, centerY - hp), Offset(xLeft - hp, ySpreadBottom - hp), Offset(xRight - hp, ySpreadBottom - hp), Offset(xMid - hp, (ySpreadTop + centerY) / 2 - hp), Offset(xMid - hp, (ySpreadBottom + centerY) / 2 - hp)];
      case Rank.nine: return [Offset(xLeft - hp, ySpreadTop - hp), Offset(xRight - hp, ySpreadTop - hp), Offset(xLeft - hp, ySide2 - hp), Offset(xRight - hp, ySide2 - hp), Offset(xLeft - hp, ySide3 - hp), Offset(xRight - hp, ySide3 - hp), Offset(xLeft - hp, ySpreadBottom - hp), Offset(xRight - hp, ySpreadBottom - hp), Offset(xMid - hp, centerY - hp)];
      case Rank.ten: return [Offset(xLeft - hp, ySpreadTop - hp), Offset(xRight - hp, ySpreadTop - hp), Offset(xLeft - hp, ySide2 - hp), Offset(xRight - hp, ySide2 - hp), Offset(xLeft - hp, ySide3 - hp), Offset(xRight - hp, ySide3 - hp), Offset(xLeft - hp, ySpreadBottom - hp), Offset(xRight - hp, ySpreadBottom - hp), Offset(xMid - hp, (ySpreadTop + ySide2) / 2 - hp), Offset(xMid - hp, (ySpreadBottom + ySide3) / 2 - hp)];
      default: return [];
    }
  }
}

// --- PAINTERS ---

class CardBackPainter extends CustomPainter {
  final Color primaryColor;
  final String pattern;

  CardBackPainter({this.primaryColor = Colors.blue, this.pattern = 'diamond'});

  @override
  void paint(Canvas canvas, Size size) {
    double margin;
    switch (pattern) {
      case 'diamond': margin = 1.0; break;
      case 'crosshatch': margin = 12.0; break;
      case 'dots':
      case 'waves':
      case 'double':
      default: margin = 5.0; break;
    }

    final whitePaint = Paint()..color = Colors.white;
    canvas.drawRect(Offset.zero & size, whitePaint);

    final step = size.width / 32;
    final patternPaint = Paint()..color = primaryColor..isAntiAlias = true;

    final clipRRect = RRect.fromRectAndRadius(Rect.fromLTWH(margin, margin, size.width - 2 * margin, size.height - 2 * margin), const Radius.circular(2.0));
    canvas.save();
    canvas.clipRRect(clipRRect);

    switch (pattern) {
      case 'crosshatch':
        patternPaint.style = PaintingStyle.stroke;
        patternPaint.strokeWidth = step / 4;
        for (double i = -size.height; i < size.width; i += step) { canvas.drawLine(Offset(i, 0), Offset(i + size.height, size.height), patternPaint); }
        for (double i = 0; i < size.width + size.height; i += step) { canvas.drawLine(Offset(i, 0), Offset(i - size.height, size.height), patternPaint); }
        break;
      case 'dots':
        patternPaint.style = PaintingStyle.fill;
        final radius = step * 0.22;
        for (double y = -step; y < size.height + step; y += step / 2) {
          final bool isEvenRow = (y / (step / 2)).round() % 2 == 0;
          final double offsetX = isEvenRow ? 0 : step / 2;
          for (double x = -step; x < size.width + step; x += step) { canvas.drawCircle(Offset(x + offsetX, y), radius, patternPaint); }
        }
        break;
      case 'waves':
        patternPaint.style = PaintingStyle.stroke;
        patternPaint.strokeWidth = step / 4;
        final double arcRadius = step;
        for (double y = 0; y < size.height + arcRadius; y += arcRadius) {
          final bool isEvenRow = (y / arcRadius).round() % 2 == 0;
          final double offsetX = isEvenRow ? 0 : arcRadius;
          for (double x = -arcRadius * 2; x < size.width + arcRadius; x += arcRadius * 2) {
            final double cx = x + offsetX; final cy = y;
            for (int i = 0; i < 3; i++) {
              final r = arcRadius * (1.0 - i * 0.35); if (r <= 0) continue;
              canvas.drawArc(Rect.fromCircle(center: Offset(cx, cy), radius: r), math.pi, math.pi, false, patternPaint);
            }
          }
        }
        break;
      case 'diamond':
      default:
        patternPaint.style = PaintingStyle.fill;
        final diamondSize = step * 0.9;
        for (double y = -step; y < size.height + step; y += step / 2) {
          final bool isEvenRow = (y / (step / 2)).round() % 2 == 0;
          final double offsetX = isEvenRow ? 0 : step / 2;
          for (double x = -step; x < size.width + step; x += step) {
            final cx = x + offsetX; final cy = y;
            final path = Path()..moveTo(cx, cy - diamondSize / 2)..lineTo(cx + diamondSize / 2, cy)..lineTo(cx, cy + diamondSize / 2)..lineTo(cx - diamondSize / 2, cy)..close();
            canvas.drawPath(path, patternPaint);
          }
        }
        break;
    }
    canvas.restore();

    if (pattern == 'crosshatch') {
      canvas.drawRRect(clipRRect, Paint()..color = primaryColor..style = PaintingStyle.stroke..strokeWidth = 1.0);
    }
  }



  @override
  bool shouldRepaint(covariant CardBackPainter oldDelegate) => oldDelegate.primaryColor != primaryColor || oldDelegate.pattern != pattern;
}

// ... (ArtDecoCardBackPainter remains unchanged) ...
class ArtDecoCardBackPainter extends CustomPainter {
  final Color primaryColor;
  ArtDecoCardBackPainter({this.primaryColor = Colors.orange});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(rect, Paint()..color = const Color(0xFF121212));

    const goldColor = Color(0xFFD4AF37);
    final goldStroke = Paint()..color = goldColor..style = PaintingStyle.stroke..strokeWidth = 2.0..isAntiAlias = true;
    final goldFill = Paint()..color = goldColor..style = PaintingStyle.fill..isAntiAlias = true;
    final darkGoldStroke = Paint()..color = const Color(0xFFAA8C2C)..style = PaintingStyle.stroke..strokeWidth = 1.0..isAntiAlias = true;

    final cx = size.width / 2; final cy = size.height / 2;
    final w = size.width; final h = size.height;
    final m = w * 0.08;

    canvas.drawRect(Rect.fromLTWH(m, m, w - 2 * m, h - 2 * m), goldStroke);
    canvas.drawRect(Rect.fromLTWH(m + 4, m + 4, w - 2 * m - 8, h - 2 * m - 8), darkGoldStroke);

    canvas.save();
    canvas.clipRect(Rect.fromLTWH(m, m, w - 2 * m, h - 2 * m));
    final fanRadius = w * 0.25;
    final corners = [Offset(m, m), Offset(w - m, m), Offset(m, h - m), Offset(w - m, h - m)];
    for (var corner in corners) {
      canvas.drawCircle(corner, fanRadius, goldFill..color = goldColor.withValues(alpha: 0.2));
      canvas.drawCircle(corner, fanRadius * 0.7, goldStroke);
      canvas.drawCircle(corner, fanRadius * 0.4, goldFill..color = goldColor);
    }
    canvas.restore();

    final dw = w * 0.55; final dh = h * 0.42;
    final diamondPath = Path()..moveTo(cx, cy - dh)..lineTo(cx + dw, cy)..lineTo(cx, cy + dh)..lineTo(cx - dw, cy)..close();
    canvas.drawPath(diamondPath, Paint()..color = const Color(0xFF121212));
    canvas.drawPath(diamondPath, goldStroke..strokeWidth = 3.0);
    
    final idw = dw * 0.85; final idh = dh * 0.85;
    final innerDiamond = Path()..moveTo(cx, cy - idh)..lineTo(cx + idw, cy)..lineTo(cx, cy + idh)..lineTo(cx - idw, cy)..close();
    canvas.drawPath(innerDiamond, darkGoldStroke);

    canvas.save();
    canvas.clipPath(diamondPath);
    final stripePaint = Paint()..color = goldColor.withValues(alpha: 0.15)..strokeWidth = 1.0;
    for (double x = cx - dw; x < cx + dw; x += 6) { canvas.drawLine(Offset(x, cy - dh), Offset(x, cy + dh), stripePaint); }
    canvas.restore();

    canvas.drawCircle(Offset(cx, cy), w * 0.18, Paint()..color = const Color(0xFF121212));
    canvas.drawCircle(Offset(cx, cy), w * 0.18, goldStroke);
    
    final star = Path(); final ir = w * 0.25 * 0.25; final r = w * 0.25;
    star.moveTo(cx, cy - r); star.lineTo(cx + ir, cy - ir); star.lineTo(cx + r, cy); star.lineTo(cx + ir, cy + ir); star.lineTo(cx, cy + r); star.lineTo(cx - ir, cy + ir); star.lineTo(cx - r, cy); star.lineTo(cx - ir, cy - ir); star.close();
    canvas.drawPath(star, goldFill..color = goldColor);
    canvas.drawCircle(Offset(cx, cy), r * 0.05, Paint()..color = const Color(0xFF121212));
  }

  @override
  bool shouldRepaint(covariant ArtDecoCardBackPainter oldDelegate) => false;
}