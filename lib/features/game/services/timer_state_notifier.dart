import 'dart:async';
import 'package:flutter/material.dart';

/// Manages game timer state separately from game logic
/// to prevent unnecessary rebuilds when timer ticks
class TimerStateNotifier extends ChangeNotifier {
  final Stopwatch _stopwatch = Stopwatch();
  Timer? _timer;
  Duration _elapsed = Duration.zero;

  Duration get elapsed => _elapsed;
  bool get isRunning => _stopwatch.isRunning;

  void start() {
    if (!_stopwatch.isRunning) {
      _stopwatch.start();
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        _elapsed = _stopwatch.elapsed;
        notifyListeners(); // Only TimerStateNotifier listeners rebuild
      });
    }
  }

  void stop() {
    _stopwatch.stop();
    _timer?.cancel();
    _timer = null;
  }

  void reset() {
    _stopwatch.reset();
    _elapsed = Duration.zero;
    notifyListeners();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
