import 'dart:io';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:window_manager/window_manager.dart';

/// Service to configure desktop window properties.
/// Only active on desktop platforms (Windows, macOS, Linux).
///
/// This service respects OS-level maximize and snap features by only
/// enforcing aspect ratio when the window is in normal (non-maximized) state.
class DesktopWindowService with WindowListener {
  // Preferred aspect ratio (3:2)
  static const double preferredAspectRatio = 3 / 2;

  // Minimum window dimensions (maintaining 3:2 aspect ratio)
  static const double minWidth = 900.0;
  static const double minHeight = 600.0;

  // Default window dimensions (3:2 aspect ratio)
  static const double defaultWidth = 1350.0;
  static const double defaultHeight = 900.0;

  static DesktopWindowService? _instance;

  DesktopWindowService._();

  /// Check if we're running on a desktop platform
  static bool get isDesktop {
    if (kIsWeb) return false;
    return Platform.isWindows || Platform.isMacOS || Platform.isLinux;
  }

  /// Initialize desktop window with constraints and preferred aspect ratio.
  /// Call this early in app initialization, before runApp.
  static Future<void> initialize() async {
    if (!isDesktop) return;

    await windowManager.ensureInitialized();

    const windowOptions = WindowOptions(
      size: Size(defaultWidth, defaultHeight),
      minimumSize: Size(minWidth, minHeight),
      center: true,
      backgroundColor: Color(0x00000000),
      skipTaskbar: false,
      titleBarStyle: TitleBarStyle.normal,
      title: 'Solitude',
    );

    await windowManager.waitUntilReadyToShow(windowOptions, () async {
      // Set aspect ratio for normal window state
      // This will be temporarily disabled when maximized
      await windowManager.setAspectRatio(preferredAspectRatio);
      await windowManager.show();
      await windowManager.focus();
    });

    // Create instance and listen for window state changes
    _instance = DesktopWindowService._();
    windowManager.addListener(_instance!);
  }

  @override
  void onWindowMaximize() {
    // Remove aspect ratio constraint when maximized to allow full screen usage
    windowManager.setAspectRatio(0.0); // 0.0 = no aspect ratio constraint
    debugPrint(
        'DesktopWindowService: Window maximized - aspect ratio constraint removed');
  }

  @override
  void onWindowUnmaximize() {
    // Restore aspect ratio constraint when returning to normal state
    windowManager.setAspectRatio(preferredAspectRatio);
    debugPrint(
        'DesktopWindowService: Window restored - aspect ratio constraint applied');
  }

  /// Cleanup window listener
  static void dispose() {
    if (_instance != null && isDesktop) {
      windowManager.removeListener(_instance!);
      _instance = null;
    }
  }
}
