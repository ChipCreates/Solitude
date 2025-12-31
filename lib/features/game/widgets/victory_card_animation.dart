import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import '../models/card.dart';
import '../models/pile.dart';
import 'card_widget.dart';

/// Victory animation patterns for visual variety
enum VictoryPattern {
  cascade, // Cards fall from foundation piles with physics
  fountain, // Cards shoot up from foundation piles then fall
  scatter, // Explosion from center of screen
  vortex, // Spiral motion around center
}

/// Represents a single animated card in the victory celebration
class FallingCard {
  PlayingCard card;
  double x;
  double y;
  double vx; // horizontal velocity
  double vy; // vertical velocity
  double rotation;
  double rotationalVelocity;
  Color? color; // For debug visualization or special effects
  int pileIndex; // Which foundation pile this card came from
  double t; // Time/lifetime parameter (essential for vortex math)

  FallingCard({
    required this.card,
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.rotation,
    required this.rotationalVelocity,
    this.color,
    required this.pileIndex,
    this.t = 0.0,
  });
}

/// Physics-based card animation for victory celebrations.
/// Provides 4 distinct patterns with realistic motion and gravity.
class VictoryCardAnimation extends StatefulWidget {
  final List<Pile> foundationPiles;
  final VoidCallback? onComplete;
  final VictoryPattern? forcePattern; // For testing/debugging specific patterns

  const VictoryCardAnimation({
    super.key,
    required this.foundationPiles,
    this.onComplete,
    this.forcePattern,
  });

  @override
  State<VictoryCardAnimation> createState() => _VictoryCardAnimationState();
}

class _VictoryCardAnimationState extends State<VictoryCardAnimation>
    with TickerProviderStateMixin {
  late Ticker _ticker;
  final List<FallingCard> _fallingCards = [];
  final List<PlayingCard> _remainingCards = [];
  final Random _random = Random();
  late VictoryPattern _currentPattern;

  // Animation constants
  static const double gravity = 0.5;
  static const double bounceDamping = 0.7; // Lose 30% energy on bounce
  static const double friction = 0.98; // Velocity decay for scatter pattern
  static const int spawnIntervalMs =
      100; // Spawn every ~100ms for cascade/fountain
  static const double cardWidth = 70;
  static const double cardHeight = cardWidth / CardWidget.aspectRatio;

  // Vortex constants
  static const double vortexSpeed = 2.0;
  static const double vortexRotationSpeed = 0.1;
  static const double initialVortexRadius = 200.0;

  Timer? _spawnTimer;
  int _spawnIndex = 0;

  @override
  void initState() {
    super.initState();

    // Select animation pattern
    _currentPattern = widget.forcePattern ??
        VictoryPattern.values[_random.nextInt(VictoryPattern.values.length)];

    // Collect all cards from foundation piles
    for (int pileIndex = 0;
        pileIndex < widget.foundationPiles.length;
        pileIndex++) {
      final pile = widget.foundationPiles[pileIndex];
      for (final card in pile.cards) {
        _remainingCards.add(card);
      }
    }

    // Start the physics ticker
    _ticker = createTicker(_onTick);
    _ticker.start();

    // Start spawning cards based on pattern
    _startSpawning();
  }

  void _startSpawning() {
    switch (_currentPattern) {
      case VictoryPattern.cascade:
      case VictoryPattern.fountain:
        // Spawn sequentially from foundation piles
        _spawnTimer = Timer.periodic(
          const Duration(milliseconds: spawnIntervalMs),
          (_) => _spawnCard(),
        );
        break;
      case VictoryPattern.scatter:
        // Spawn all cards at once from center
        _spawnAllCardsAtOnce();
        break;
      case VictoryPattern.vortex:
        // Spawn sequentially but position differently
        _spawnTimer = Timer.periodic(
          const Duration(milliseconds: spawnIntervalMs),
          (_) => _spawnCard(),
        );
        break;
    }
  }

  void _spawnCard() {
    if (_spawnIndex >= _remainingCards.length) {
      _spawnTimer?.cancel();
      return;
    }

    final card = _remainingCards[_spawnIndex++];
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final pileIndex = (_spawnIndex - 1) ~/ 13; // 13 cards per foundation pile

    switch (_currentPattern) {
      case VictoryPattern.cascade:
        _spawnCascadeCard(card, screenWidth, screenHeight, pileIndex);
        break;
      case VictoryPattern.fountain:
        _spawnFountainCard(card, screenWidth, screenHeight, pileIndex);
        break;
      case VictoryPattern.scatter:
        // Handled in _spawnAllCardsAtOnce
        break;
      case VictoryPattern.vortex:
        _spawnVortexCard(
            card, screenWidth, screenHeight, pileIndex, _spawnIndex - 1);
        break;
    }
  }

  void _spawnCascadeCard(PlayingCard card, double screenWidth,
      double screenHeight, int pileIndex) {
    // Start from foundation pile positions
    final pileX =
        (pileIndex + 1) * (screenWidth / 5); // Distribute across screen
    final startX = pileX + _random.nextDouble() * 60 - 30; // Some randomness
    final startY = screenHeight * 0.65; // Foundation area

    final vx = _random.nextDouble() * 4 - 2; // Gentle horizontal drift
    final vy = _random.nextDouble() * 2 + 1; // Downward initial velocity

    _fallingCards.add(FallingCard(
      card: card,
      x: startX,
      y: startY,
      vx: vx,
      vy: vy,
      rotation: _random.nextDouble() * 2 * pi,
      rotationalVelocity: (_random.nextDouble() - 0.5) * 0.1,
      pileIndex: pileIndex,
    ));
  }

  void _spawnFountainCard(PlayingCard card, double screenWidth,
      double screenHeight, int pileIndex) {
    // Shoot up from foundation piles
    final pileX = (pileIndex + 1) * (screenWidth / 5);
    final startX = pileX + _random.nextDouble() * 40 - 20;
    final startY = screenHeight * 0.65;

    final vx = _random.nextDouble() * 6 - 3; // Wider horizontal spread
    final vy = -(_random.nextDouble() * 8 + 4); // Strong upward velocity

    _fallingCards.add(FallingCard(
      card: card,
      x: startX,
      y: startY,
      vx: vx,
      vy: vy,
      rotation: _random.nextDouble() * 2 * pi,
      rotationalVelocity: (_random.nextDouble() - 0.5) * 0.15,
      pileIndex: pileIndex,
    ));
  }

  void _spawnAllCardsAtOnce() {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    for (int i = 0; i < _remainingCards.length; i++) {
      final card = _remainingCards[i];
      final pileIndex = i ~/ 13;

      // Explosion from center
      final angle = _random.nextDouble() * 2 * pi;
      final speed = _random.nextDouble() * 8 + 4;

      _fallingCards.add(FallingCard(
        card: card,
        x: screenWidth / 2,
        y: screenHeight / 2,
        vx: cos(angle) * speed,
        vy: sin(angle) * speed,
        rotation: _random.nextDouble() * 2 * pi,
        rotationalVelocity: (_random.nextDouble() - 0.5) * 0.2,
        pileIndex: pileIndex,
      ));
    }
  }

  void _spawnVortexCard(PlayingCard card, double screenWidth,
      double screenHeight, int pileIndex, int globalIndex) {
    // Start from edges moving toward center
    // Start from random edge
    final edge = _random.nextInt(4);
    late double startX, startY;
    switch (edge) {
      case 0: // Top
        startX = _random.nextDouble() * screenWidth;
        startY = -cardHeight;
        break;
      case 1: // Right
        startX = screenWidth + cardWidth;
        startY = _random.nextDouble() * screenHeight;
        break;
      case 2: // Bottom
        startX = _random.nextDouble() * screenWidth;
        startY = screenHeight + cardHeight;
        break;
      case 3: // Left
        startX = -cardWidth;
        startY = _random.nextDouble() * screenHeight;
        break;
    }

    _fallingCards.add(FallingCard(
      card: card,
      x: startX,
      y: startY,
      vx: 0, // Not used in vortex
      vy: 0, // Not used in vortex
      rotation: _random.nextDouble() * 2 * pi,
      rotationalVelocity: vortexRotationSpeed + _random.nextDouble() * 0.05,
      pileIndex: pileIndex,
      t: globalIndex * 0.1, // Staggered start times
    ));
  }

  void _onTick(Duration elapsed) {
    if (!mounted) return;

    setState(() {
      switch (_currentPattern) {
        case VictoryPattern.cascade:
        case VictoryPattern.fountain:
          _updateStandardPhysics();
          break;
        case VictoryPattern.scatter:
          _updateScatterPhysics();
          break;
        case VictoryPattern.vortex:
          _updateVortexPhysics();
          break;
      }

      // Prune cards that have flown off screen (except vortex which handles its own bounds)
      if (_currentPattern != VictoryPattern.vortex) {
        _fallingCards.removeWhere((card) {
          final screenWidth = MediaQuery.of(context).size.width;
          final screenHeight = MediaQuery.of(context).size.height;
          return card.x < -cardWidth * 2 ||
              card.x > screenWidth + cardWidth * 2 ||
              card.y < -cardHeight * 2 ||
              card.y > screenHeight + cardHeight * 2;
        });
      }

      // Check if animation is complete
      final isSpawningComplete = _spawnIndex >= _remainingCards.length;
      final isAnimationComplete = _fallingCards.isEmpty ||
          (_currentPattern == VictoryPattern.vortex &&
              _fallingCards.every((card) => card.t > 10.0));

      if (isSpawningComplete && isAnimationComplete) {
        _ticker.stop();
        widget.onComplete?.call();
      }
    });
  }

  void _updateStandardPhysics() {
    final screenHeight = MediaQuery.of(context).size.height;

    for (final fallingCard in _fallingCards) {
      // Apply gravity
      fallingCard.vy += gravity;

      // Update position
      fallingCard.x += fallingCard.vx;
      fallingCard.y += fallingCard.vy;

      // Bounce off bottom
      if (fallingCard.y > screenHeight - cardHeight) {
        fallingCard.y = screenHeight - cardHeight;
        fallingCard.vy = -fallingCard.vy * bounceDamping;
        // Add some horizontal friction on bounce
        fallingCard.vx *= 0.9;
      }

      // Update rotation
      fallingCard.rotation += fallingCard.rotationalVelocity;
    }
  }

  void _updateScatterPhysics() {
    for (final fallingCard in _fallingCards) {
      // Apply minimal gravity
      fallingCard.vy += gravity * 0.3;

      // Update position
      fallingCard.x += fallingCard.vx;
      fallingCard.y += fallingCard.vy;

      // Apply friction
      fallingCard.vx *= friction;
      fallingCard.vy *= friction;

      // Update rotation
      fallingCard.rotation += fallingCard.rotationalVelocity;
    }
  }

  void _updateVortexPhysics() {
    final centerX = MediaQuery.of(context).size.width / 2;
    final centerY = MediaQuery.of(context).size.height / 2;

    for (final fallingCard in _fallingCards) {
      // Increment time
      fallingCard.t += 0.02; // Adjust speed as needed

      // Calculate spiral position
      final radius = initialVortexRadius - (vortexSpeed * fallingCard.t);
      if (radius <= 0) continue; // Card has spiraled into center

      final angle =
          fallingCard.t * vortexRotationSpeed + (fallingCard.pileIndex * 0.5);

      fallingCard.x = centerX + radius * cos(angle);
      fallingCard.y = centerY + radius * sin(angle);

      // Update rotation
      fallingCard.rotation += fallingCard.rotationalVelocity;
    }
  }

  @override
  void dispose() {
    _ticker.dispose();
    _spawnTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: _fallingCards.map((fallingCard) {
        return Positioned(
          left:
              fallingCard.x - cardWidth / 2, // Center the card on its position
          top: fallingCard.y - cardHeight / 2,
          child: RepaintBoundary(
            child: Transform.rotate(
              angle: fallingCard.rotation,
              child: CardWidget(
                card: fallingCard.card,
                width: cardWidth,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
