import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:xml/xml.dart' as xml;

/// Service to preload SVG assets during app initialization.
/// Eliminates the performance hit when first card is rendered.
///
/// This service is crash-resistant: if assets fail to load, the app
/// will continue with degraded card rendering rather than crashing.
class SvgPreloadService {
  static String? _cachedFullSvg;
  static xml.XmlDocument? _cachedSvgDoc;
  static Map<String, xml.XmlElement>? _elementCache;
  static bool _loadFailed = false;

  /// Whether the SVG has been preloaded successfully
  static bool get isPreloaded => _cachedFullSvg != null;

  /// Whether SVG loading failed (app will use fallback rendering)
  static bool get loadFailed => _loadFailed;

  /// Preload the SVG card file and build the element cache.
  /// Call this during app initialization before showing the game.
  ///
  /// This method is crash-resistant: if loading fails, it logs the error
  /// and allows the app to continue (cards will use fallback rendering).
  static Future<void> preloadCardSvg() async {
    if (_cachedFullSvg != null) {
      return; // Already loaded
    }

    // Try the common locations for the consolidated SVG card file
    final candidates = [
      'assets/cards/svg-cards.svg',
      'assets/cards/SVG-cards/svg-cards.svg',
    ];

    for (final path in candidates) {
      try {
        final svgString = await rootBundle.loadString(path);
        if (svgString.isNotEmpty) {
          _cachedFullSvg = svgString;

          try {
            _cachedSvgDoc = xml.XmlDocument.parse(_cachedFullSvg!);

            // Build element cache for O(1) lookups
            _buildElementCache();

            debugPrint('SvgPreloadService: Successfully loaded $path');
            return;
          } catch (parseError) {
            debugPrint('SvgPreloadService: Failed to parse $path: $parseError');
            // Try next candidate
            continue;
          }
        }
      } catch (e) {
        debugPrint('SvgPreloadService: Failed to load $path: $e');
        // Try next candidate
      }
    }

    // All candidates failed - log error but DON'T crash
    _loadFailed = true;
    debugPrint(
        'SvgPreloadService: WARNING - Could not preload svg-cards.svg from any location. '
        'Checked: ${candidates.join(', ')}. '
        'App will continue with fallback card rendering.');
  }

  /// Build element ID cache for fast lookups
  static void _buildElementCache() {
    if (_cachedSvgDoc == null) return;

    _elementCache = {};

    // Single traversal to build the entire cache
    for (final element
        in _cachedSvgDoc!.descendants.whereType<xml.XmlElement>()) {
      final id = element.getAttribute('id');
      if (id != null && id.isNotEmpty) {
        _elementCache![id] = element;
      }
    }
  }

  /// Get the cached SVG string (for use by SvgCardRenderer)
  static String? getCachedSvg() => _cachedFullSvg;

  /// Get the cached XML document (for use by SvgCardRenderer)
  static xml.XmlDocument? getCachedDoc() => _cachedSvgDoc;

  /// Get the element cache (for use by SvgCardRenderer)
  static Map<String, xml.XmlElement>? getElementCache() => _elementCache;

  /// Clear all caches (for testing or hot reload)
  static void clearCache() {
    _cachedFullSvg = null;
    _cachedSvgDoc = null;
    _elementCache = null;
  }
}
