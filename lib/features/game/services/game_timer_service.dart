import 'dart:async';

/// Callback type for inactivity timeout
typedef InactivityCallback = void Function();

/// GameTimerService manages inactivity timing for auto-hints.
///
/// This service encapsulates the inactivity detection logic,
/// decoupling it from the GameController for better separation of concerns.
class GameTimerService {
  /// Default inactivity threshold before showing a hint
  static const Duration defaultInactivityThreshold = Duration(seconds: 8);

  Timer? _inactivityTimer;
  final Duration _inactivityThreshold;
  InactivityCallback? _onInactivityTimeout;
  bool _isDisposed = false;
  bool _isEnabled = false;

  /// Creates a GameTimerService with an optional custom threshold.
  GameTimerService({
    Duration? inactivityThreshold,
  }) : _inactivityThreshold = inactivityThreshold ?? defaultInactivityThreshold;

  /// Sets the callback to invoke when inactivity timeout is reached.
  void setInactivityCallback(InactivityCallback callback) {
    _onInactivityTimeout = callback;
  }

  /// Enables inactivity tracking (call when game starts)
  void enable() {
    _isEnabled = true;
  }

  /// Disables inactivity tracking (call when game ends/pauses)
  void disable() {
    _isEnabled = false;
    stop();
  }

  /// Resets the inactivity timer.
  ///
  /// Call this on any user interaction to restart the countdown.
  void resetInactivityTimer() {
    if (_isDisposed) return;

    _inactivityTimer?.cancel();
    _inactivityTimer = null;

    if (_isEnabled) {
      _inactivityTimer = Timer(_inactivityThreshold, _handleTimeout);
    }
  }

  void _handleTimeout() {
    if (_isDisposed || !_isEnabled) return;
    _onInactivityTimeout?.call();
    // Restart timer so hint shows again if still inactive
    resetInactivityTimer();
  }

  /// Stops the inactivity timer without disabling the service.
  void stop() {
    _inactivityTimer?.cancel();
    _inactivityTimer = null;
  }

  /// Disposes of the service and cancels any pending timers.
  void dispose() {
    _isDisposed = true;
    _inactivityTimer?.cancel();
    _inactivityTimer = null;
    _onInactivityTimeout = null;
  }
}
