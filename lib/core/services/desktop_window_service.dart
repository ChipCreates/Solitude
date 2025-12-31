import 'dart:io';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:window_manager/window_manager.dart';

/// Service to configure desktop window properties.
/// Only active on desktop platforms (Windows, macOS, Linux).
class DesktopWindowService {
  // Preferred aspect ratio (3:2)
  static const double preferredAspectRatio = 3 / 2;

  // Minimum window dimensions
  static const double minWidth = 900.0;
  static const double minHeight = 700.0;

  // Default window dimensions (3:2 aspect ratio)
  static const double defaultWidth = 1350.0;
  static const double defaultHeight = 900.0;

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
      // Set aspect ratio immediately when ready, before showing
      await windowManager.setAspectRatio(preferredAspectRatio);
      await windowManager.show();
      await windowManager.focus();
    });
  }
}
