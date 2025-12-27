/// Draw mode for stock-based solitaire games
enum DrawMode {
  /// Draw 1 card at a time from stock
  one,

  /// Draw 3 cards at a time from stock
  three;

  /// Number of cards drawn per stock tap
  int get drawCount {
    switch (this) {
      case DrawMode.one:
        return 1;
      case DrawMode.three:
        return 3;
    }
  }
}
