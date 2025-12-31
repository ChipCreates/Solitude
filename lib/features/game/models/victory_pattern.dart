/// Victory animation patterns for visual variety in game celebrations
enum VictoryPattern {
  random,
  cascade, // Cards fall from foundation piles with physics
  fountain, // Cards shoot up from foundation piles then fall
  scatter, // Explosion from center of screen
  vortex, // Spiral motion around center
}

extension VictoryPatternExtension on VictoryPattern {
  String get label {
    switch (this) {
      case VictoryPattern.random:
        return 'Random';
      case VictoryPattern.cascade:
        return 'Cascade';
      case VictoryPattern.fountain:
        return 'Fountain';
      case VictoryPattern.scatter:
        return 'Scatter';
      case VictoryPattern.vortex:
        return 'Vortex';
    }
  }
}
