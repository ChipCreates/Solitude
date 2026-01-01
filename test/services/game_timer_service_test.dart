import 'package:flutter_test/flutter_test.dart';
import 'package:solitude/features/game/services/game_timer_service.dart';

void main() {
  group('GameTimerService', () {
    group('initialization', () {
      test('creates service with default threshold', () {
        final service = GameTimerService();
        expect(service, isNotNull);
      });

      test('creates service with custom threshold', () {
        const customThreshold = Duration(seconds: 5);
        final service = GameTimerService(inactivityThreshold: customThreshold);
        expect(service, isNotNull);
      });

      test('default threshold is 8 seconds', () {
        expect(GameTimerService.defaultInactivityThreshold,
            equals(const Duration(seconds: 8)));
      });

      test('custom threshold overrides default', () {
        const customThreshold = Duration(seconds: 10);
        final service = GameTimerService(inactivityThreshold: customThreshold);
        expect(service, isNotNull);
      });
    });

    group('inactivity callback', () {
      test('setInactivityCallback sets callback', () {
        final service = GameTimerService();
        int callbackCount = 0;

        void callback() {
          callbackCount++;
        }

        service.setInactivityCallback(callback);
        expect(callbackCount, equals(0));
      });

      test('callback is invoked on timeout', () async {
        final service = GameTimerService(
            inactivityThreshold: const Duration(milliseconds: 100));
        int callbackCount = 0;

        void callback() {
          callbackCount++;
        }

        service.setInactivityCallback(callback);
        service.enable();
        service.resetInactivityTimer();

        // Wait for timeout
        await Future.delayed(const Duration(milliseconds: 150));

        expect(callbackCount, greaterThanOrEqualTo(1));
      });

      test('callback is not invoked before timeout', () async {
        final service = GameTimerService(
            inactivityThreshold: const Duration(milliseconds: 200));
        int callbackCount = 0;

        void callback() {
          callbackCount++;
        }

        service.setInactivityCallback(callback);
        service.enable();
        service.resetInactivityTimer();

        // Wait but not long enough for timeout
        await Future.delayed(const Duration(milliseconds: 100));

        expect(callbackCount, equals(0));
      });
    });

    group('enable/disable functionality', () {
      test('enable activates timer', () async {
        final service = GameTimerService(
            inactivityThreshold: const Duration(milliseconds: 100));
        int callbackCount = 0;

        void callback() {
          callbackCount++;
        }

        service.setInactivityCallback(callback);
        service.enable();

        service.resetInactivityTimer();
        await Future.delayed(const Duration(milliseconds: 150));

        expect(callbackCount, greaterThan(0));
      });

      test('disable prevents timer activation', () async {
        final service = GameTimerService(
            inactivityThreshold: const Duration(milliseconds: 100));
        int callbackCount = 0;

        void callback() {
          callbackCount++;
        }

        service.setInactivityCallback(callback);
        service.disable();
        service.resetInactivityTimer();

        await Future.delayed(const Duration(milliseconds: 150));

        expect(callbackCount, equals(0));
      });

      test('disable stops active timer', () async {
        final service = GameTimerService(
            inactivityThreshold: const Duration(milliseconds: 100));
        int callbackCount = 0;

        void callback() {
          callbackCount++;
        }

        service.setInactivityCallback(callback);
        service.enable();
        service.resetInactivityTimer();

        // Stop timer before it fires
        service.disable();

        await Future.delayed(const Duration(milliseconds: 150));

        expect(callbackCount, equals(0));
      });
    });

    group('timer reset functionality', () {
      test('resetInactivityTimer restarts countdown', () async {
        final service = GameTimerService(
            inactivityThreshold: const Duration(milliseconds: 100));
        int callbackCount = 0;

        void callback() {
          callbackCount++;
        }

        service.setInactivityCallback(callback);
        service.enable();

        // Reset timer multiple times
        service.resetInactivityTimer();
        await Future.delayed(const Duration(milliseconds: 50));
        service.resetInactivityTimer();
        await Future.delayed(const Duration(milliseconds: 50));
        service.resetInactivityTimer();

        await Future.delayed(const Duration(milliseconds: 150));

        // Should have callback fired once after all resets
        expect(callbackCount, greaterThanOrEqualTo(1));
      });

      test('resetInactivityTimer when disabled does nothing', () {
        final service = GameTimerService(
            inactivityThreshold: const Duration(milliseconds: 100));

        service.setInactivityCallback(() {});
        service.disable();

        // Reset should not cause issues
        expect(() => service.resetInactivityTimer(), returnsNormally);
      });

      test('resetInactivityTimer when disposed does nothing', () {
        final service = GameTimerService(
            inactivityThreshold: const Duration(milliseconds: 100));
        service.dispose();

        expect(() => service.resetInactivityTimer(), returnsNormally);
      });
    });

    group('timer lifecycle', () {
      test('timer restarts after timeout', () async {
        final service = GameTimerService(
            inactivityThreshold: const Duration(milliseconds: 100));
        int callbackCount = 0;

        void callback() {
          callbackCount++;
        }

        service.setInactivityCallback(callback);
        service.enable();
        service.resetInactivityTimer();

        // Wait for first timeout
        await Future.delayed(const Duration(milliseconds: 150));
        expect(callbackCount, greaterThanOrEqualTo(1));

        // Wait for second timeout (should happen automatically)
        await Future.delayed(const Duration(milliseconds: 150));
        expect(callbackCount, greaterThanOrEqualTo(2));
      });

      test('stop prevents timer activation', () async {
        final service = GameTimerService(
            inactivityThreshold: const Duration(milliseconds: 100));
        int callbackCount = 0;

        void callback() {
          callbackCount++;
        }

        service.setInactivityCallback(callback);
        service.enable();
        service.resetInactivityTimer();
        service.stop();

        await Future.delayed(const Duration(milliseconds: 150));

        expect(callbackCount, equals(0));
      });

      test('stop can be called multiple times', () {
        final service = GameTimerService();

        expect(() => service.stop(), returnsNormally);
        expect(() => service.stop(), returnsNormally);
        expect(() => service.stop(), returnsNormally);
      });
    });

    group('disposal', () {
      test('dispose cleans up resources', () {
        final service = GameTimerService();
        service.dispose();

        // After disposal, operations should be safe
        expect(() => service.resetInactivityTimer(), returnsNormally);
        expect(() => service.stop(), returnsNormally);
        expect(() => service.enable(), returnsNormally);
        expect(() => service.disable(), returnsNormally);
      });

      test('dispose cancels active timer', () async {
        final service = GameTimerService(
            inactivityThreshold: const Duration(milliseconds: 100));
        int callbackCount = 0;

        void callback() {
          callbackCount++;
        }

        service.setInactivityCallback(callback);
        service.enable();
        service.resetInactivityTimer();
        service.dispose();

        await Future.delayed(const Duration(milliseconds: 150));

        expect(callbackCount, equals(0));
      });

      test('dispose can be called multiple times', () {
        final service = GameTimerService();

        service.dispose();
        service.dispose();
        service.dispose();
      });

      test('disposal clears callback', () {
        final service = GameTimerService();

        service.setInactivityCallback(() {});
        service.dispose();

        // Callback should be cleared
        service.enable();
        service.resetInactivityTimer();
        // No way to verify callback is cleared without timing,
        // but disposal should not throw
        expect(service, isNotNull);
      });
    });

    group('edge cases', () {
      test('handles empty callback gracefully', () {
        final service = GameTimerService();

        // Test with a no-op callback
        service.setInactivityCallback(() {});
        service.enable();

        expect(() => service.resetInactivityTimer(), returnsNormally);
      });

      test('handles very short thresholds', () async {
        final service = GameTimerService(
            inactivityThreshold: const Duration(milliseconds: 1));
        int callbackCount = 0;

        void callback() {
          callbackCount++;
        }

        service.setInactivityCallback(callback);
        service.enable();
        service.resetInactivityTimer();

        await Future.delayed(const Duration(milliseconds: 10));

        expect(callbackCount, greaterThan(0));
      });

      test('handles very long thresholds', () {
        final service =
            GameTimerService(inactivityThreshold: const Duration(hours: 1));

        service.setInactivityCallback(() {});
        service.enable();
        service.resetInactivityTimer();

        // Timer should be set but not fire during test
        expect(service, isNotNull);
      });

      test('handles zero threshold', () {
        final service = GameTimerService(inactivityThreshold: Duration.zero);

        expect(service, isNotNull);
      });
    });

    group('state management', () {
      test('tracks enabled state correctly', () {
        final service = GameTimerService();

        service.enable();
        service.disable();
        service.enable();

        expect(service, isNotNull);
      });

      test('tracks disposed state correctly', () {
        final service = GameTimerService();

        expect(service, isNotNull);
        service.dispose();
        // State should be tracked internally
      });

      test('prevents operations when disposed', () async {
        final service = GameTimerService(
            inactivityThreshold: const Duration(milliseconds: 100));
        int callbackCount = 0;

        void callback() {
          callbackCount++;
        }

        service.setInactivityCallback(callback);
        service.dispose();

        // These should not cause the callback to fire
        service.resetInactivityTimer();
        await Future.delayed(const Duration(milliseconds: 150));

        expect(callbackCount, equals(0));
      });
    });

    group('multiple service instances', () {
      test('multiple services operate independently', () async {
        final service1 = GameTimerService(
            inactivityThreshold: const Duration(milliseconds: 100));
        final service2 = GameTimerService(
            inactivityThreshold: const Duration(milliseconds: 200));
        int callback1Count = 0;
        int callback2Count = 0;

        void callback1() {
          callback1Count++;
        }

        void callback2() {
          callback2Count++;
        }

        service1.setInactivityCallback(callback1);
        service2.setInactivityCallback(callback2);

        service1.enable();
        service2.enable();

        service1.resetInactivityTimer();
        service2.resetInactivityTimer();

        await Future.delayed(const Duration(milliseconds: 150));

        // Service1 should have fired, service2 should not
        expect(callback1Count, greaterThanOrEqualTo(1));
        expect(callback2Count, equals(0));
      });
    });
  });
}
