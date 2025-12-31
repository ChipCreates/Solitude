import 'package:flutter/material.dart';
import '../models/card.dart';
import '../models/pile.dart';
import 'card_widget.dart';

/// Data class for card animation
class CardAnimationData {
  final PlayingCard card;
  final Offset startPosition;
  final Offset endPosition;
  final double cardWidth;
  final Pile? fromPile;

  CardAnimationData({
    required this.card,
    required this.startPosition,
    required this.endPosition,
    required this.cardWidth,
    this.fromPile,
  });
}

/// Overlay widget that displays a card animating from source to destination
class AnimatedCardOverlay extends StatefulWidget {
  final CardAnimationData? animationData;
  final VoidCallback? onComplete;

  const AnimatedCardOverlay({
    super.key,
    this.animationData,
    this.onComplete,
  });

  @override
  State<AnimatedCardOverlay> createState() => _AnimatedCardOverlayState();
}

class _AnimatedCardOverlayState extends State<AnimatedCardOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _positionAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotationAnimation;
  ValueNotifier<PlayingCard>? _cardNotifier;

  @override
  void initState() {
    super.initState();
    _setupAnimation();
  }

  void _setupAnimation() {
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    // Create animation card notifier
    if (widget.animationData != null) {
      final isFromStock = widget.animationData!.fromPile?.type == PileType.stock;
      _cardNotifier = ValueNotifier(widget.animationData!.card.copyWith(faceUp: !isFromStock));
    }

    // Smooth position animation with easeOut for natural deceleration
    _positionAnimation = Tween<Offset>(
      begin: widget.animationData?.startPosition ?? Offset.zero,
      end: widget.animationData?.endPosition ?? Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));

    // Subtle scale up during flight for emphasis
    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 1.05)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 30,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.05, end: 1.0)
            .chain(CurveTween(curve: Curves.easeIn)),
        weight: 70,
      ),
    ]).animate(_controller);

    // Very subtle rotation for natural motion
    _rotationAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.0, end: 0.02)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 50,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.02, end: 0.0)
            .chain(CurveTween(curve: Curves.easeIn)),
        weight: 50,
      ),
    ]).animate(_controller);

    // Add listener to flip card halfway through animation for stock draws
    _controller.addListener(() {
      if (widget.animationData != null && widget.animationData!.fromPile?.type == PileType.stock && _cardNotifier != null) {
        if (_controller.value >= 0.5 && !_cardNotifier!.value.faceUp) {
          _cardNotifier!.value = _cardNotifier!.value.copyWith(faceUp: true);
        }
      }
    });



    if (widget.animationData != null) {
      _controller.forward();
    }
  }

  @override
  void didUpdateWidget(AnimatedCardOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Start new animation if data changed
    if (widget.animationData != oldWidget.animationData &&
        widget.animationData != null) {
      _controller.reset();
      final isFromStock = widget.animationData!.fromPile?.type == PileType.stock;
      if (_cardNotifier == null) {
        _cardNotifier = ValueNotifier(widget.animationData!.card.copyWith(faceUp: !isFromStock));
      } else {
        _cardNotifier!.value = widget.animationData!.card.copyWith(faceUp: !isFromStock);
      }

      _positionAnimation = Tween<Offset>(
        begin: widget.animationData!.startPosition,
        end: widget.animationData!.endPosition,
      ).animate(CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOutCubic,
      ));
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _cardNotifier?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.animationData == null) {
      return const SizedBox.shrink();
    }

    return AnimatedBuilder(
      animation: Listenable.merge([_controller, _cardNotifier]),
      builder: (context, child) {
        return Positioned(
          left: _positionAnimation.value.dx,
          top: _positionAnimation.value.dy,
          child: Transform.scale(
            scale: _scaleAnimation.value,
            child: Transform.rotate(
              angle: _rotationAnimation.value,
              child: CardWidget(
                card: widget.animationData!.card,
                width: widget.animationData!.cardWidth,
                overrideFaceUp: _cardNotifier!.value.faceUp,
                isDragging: true, // Use dragging state for elevated shadow
              ),
            ),
          ),
        );
      },
    );
  }
}
