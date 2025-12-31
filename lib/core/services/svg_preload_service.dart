import 'package:flutter/services.dart';
import 'package:xml/xml.dart' as xml;

/// Service to preload SVG assets during app initialization.
/// Eliminates the performance hit when first card is rendered.
class SvgPreloadService {
  static String? _cachedFullSvg;
  static xml.XmlDocument? _cachedSvgDoc;
  static Map<String, xml.XmlElement>? _elementCache;
  
  /// Whether the SVG has been preloaded
  static bool get isPreloaded => _cachedFullSvg != null;
  
  /// Preload the SVG card file and build the element cache.
  /// Call this during app initialization before showing the game.
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
          _cachedSvgDoc = xml.XmlDocument.parse(_cachedFullSvg!);

          // Build element cache for O(1) lookups
          _buildElementCache();

          return;
        }
      } catch (e) {
        // Try next candidate
      }
    }
    
    throw Exception(
      'Could not preload svg-cards.svg from any location. '
      'Checked: ${candidates.join(', ')}'
    );
  }
  
  /// Build element ID cache for fast lookups
  static void _buildElementCache() {
    if (_cachedSvgDoc == null) return;
    
    _elementCache = {};
    
    // Single traversal to build the entire cache
    for (final element in _cachedSvgDoc!.descendants.whereType<xml.XmlElement>()) {
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
