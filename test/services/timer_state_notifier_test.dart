import 'package:flutter_test/flutter_test.dart';
import 'package:solitude/services/timer_state_notifier.dart';

void main() {
  group('TimerStateNotifier', () {
    test('initializes with zero elapsed time', () {
      final notifier = TimerStateNotifier();

      expect(notifier.elapsed, Duration.zero);
      expect(notifier.isRunning, isFalse);
    });

    test('start() begins timer', () {
      final notifier = TimerStateNotifier();

      notifier.start();

      expect(notifier.isRunning, isTrue);

      notifier.dispose();
    });

    test('start() when already running does not restart', () {
      final notifier = TimerStateNotifier();

      notifier.start();
      final firstStart = notifier.isRunning;

      notifier.start(); // Should not restart

      expect(firstStart, isTrue);
      expect(notifier.isRunning, isTrue);

      notifier.dispose();
    });

    test('stop() halts timer', () {
      final notifier = TimerStateNotifier();

      notifier.start();
      expect(notifier.isRunning, isTrue);

      notifier.stop();

      expect(notifier.isRunning, isFalse);

      notifier.dispose();
    });

    test('reset() clears elapsed time', () async {
      final notifier = TimerStateNotifier();

      notifier.start();

      // Wait a bit for timer to tick
      await Future.delayed(const Duration(milliseconds: 100));

      notifier.stop();
      notifier.reset();

      expect(notifier.elapsed, Duration.zero);
      expect(notifier.isRunning, isFalse);

      notifier.dispose();
    });

    test('reset() notifies listeners', () {
      final notifier = TimerStateNotifier();
      bool notified = false;
      notifier.addListener(() => notified = true);

      notifier.reset();

      expect(notified, isTrue);

      notifier.dispose();
    });

    test('elapsed time updates periodically', () async {
      final notifier = TimerStateNotifier();

      notifier.start();

      // Wait for at least one second tick
      await Future.delayed(const Duration(milliseconds: 1100));

      expect(notifier.elapsed.inSeconds, greaterThanOrEqualTo(1));

      notifier.dispose();
    });

    test('notifies listeners on tick', () async {
      final notifier = TimerStateNotifier();
      int notifyCount = 0;
      notifier.addListener(() => notifyCount++);

      notifier.start();

      // Wait for a couple ticks
      await Future.delayed(const Duration(milliseconds: 2100));

      expect(notifyCount, greaterThanOrEqualTo(2));

      notifier.dispose();
    });

    test('stop() prevents further updates', () async {
      final notifier = TimerStateNotifier();

      notifier.start();
      await Future.delayed(const Duration(milliseconds: 1100));

      final elapsedAtStop = notifier.elapsed;
      notifier.stop();

      // Wait and ensure elapsed doesn't change
      await Future.delayed(const Duration(milliseconds: 1100));

      expect(notifier.elapsed, elapsedAtStop);

      notifier.dispose();
    });

    test('dispose() cancels timer', () async {
      final notifier = TimerStateNotifier();

      notifier.start();

      await Future.delayed(const Duration(milliseconds: 100));

      final elapsedBeforeDispose = notifier.elapsed;
      notifier.dispose();

      // After dispose, timer updates should stop
      await Future.delayed(const Duration(milliseconds: 1100));

      // Elapsed should not have changed significantly after dispose
      // (stopwatch may still be running but timer is cancelled)
      expect(notifier.elapsed, elapsedBeforeDispose);
    });

    test('can start, stop, and restart timer', () async {
      final notifier = TimerStateNotifier();

      // First session
      notifier.start();
      await Future.delayed(const Duration(milliseconds: 1100));
      notifier.stop();

      final elapsed1 = notifier.elapsed;
      expect(elapsed1.inSeconds, greaterThanOrEqualTo(1));

      // Second session - should resume from where it stopped
      notifier.start();
      await Future.delayed(const Duration(milliseconds: 1100));
      notifier.stop();

      expect(notifier.elapsed.inSeconds, greaterThanOrEqualTo(2));

      notifier.dispose();
    });

    test('reset between start/stop cycles', () async {
      final notifier = TimerStateNotifier();

      notifier.start();
      await Future.delayed(const Duration(milliseconds: 1100));
      notifier.stop();

      expect(notifier.elapsed.inSeconds, greaterThanOrEqualTo(1));

      notifier.reset();
      expect(notifier.elapsed, Duration.zero);

      notifier.start();
      await Future.delayed(const Duration(milliseconds: 1100));

      expect(notifier.elapsed.inSeconds, greaterThanOrEqualTo(1));
      expect(notifier.elapsed.inSeconds, lessThan(2));

      notifier.dispose();
    });
  });
}
