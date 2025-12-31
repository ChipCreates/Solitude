/// Hint system modes for AI assistance in gameplay
enum HintMode {
  smart, // AI Solver for optimal hints (high battery usage)
  fast, // Greedy Heuristic for quick hints
  off, // No hints
}

extension HintModeExtension on HintMode {
  String get label {
    switch (this) {
      case HintMode.smart:
        return 'Smart (AI)';
      case HintMode.fast:
        return 'Fast';
      case HintMode.off:
        return 'Off';
    }
  }
}
