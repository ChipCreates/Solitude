import 'package:flutter_test/flutter_test.dart';
import 'package:solitude/core/services/svg_preload_service.dart';

void main() {
  group('SvgPreloadService', () {
    setUp(() {
      // Clear cache before each test to ensure clean state
      SvgPreloadService.clearCache();
    });

    tearDown(() {
      // Clean up after each test
      SvgPreloadService.clearCache();
    });

    test('initializes with null cache', () {
      expect(SvgPreloadService.isPreloaded, isFalse);
      expect(SvgPreloadService.getCachedSvg(), isNull);
      expect(SvgPreloadService.getCachedDoc(), isNull);
      expect(SvgPreloadService.getElementCache(), isNull);
    });

    test('clearCache() clears all cached data', () {
      // First verify cache is empty
      expect(SvgPreloadService.isPreloaded, isFalse);

      // Note: We can't actually load SVG in unit tests without mock assets,
      // but we can verify clearCache doesn't throw
      expect(() => SvgPreloadService.clearCache(), returnsNormally);

      // Verify still empty after clear
      expect(SvgPreloadService.isPreloaded, isFalse);
      expect(SvgPreloadService.getCachedSvg(), isNull);
      expect(SvgPreloadService.getCachedDoc(), isNull);
      expect(SvgPreloadService.getElementCache(), isNull);
    });

    test('multiple clearCache() calls are safe', () {
      SvgPreloadService.clearCache();
      SvgPreloadService.clearCache();
      SvgPreloadService.clearCache();

      expect(SvgPreloadService.isPreloaded, isFalse);
    });

    test('getCachedSvg() returns null when not preloaded', () {
      expect(SvgPreloadService.getCachedSvg(), isNull);
    });

    test('getCachedDoc() returns null when not preloaded', () {
      expect(SvgPreloadService.getCachedDoc(), isNull);
    });

    test('getElementCache() returns null when not preloaded', () {
      expect(SvgPreloadService.getElementCache(), isNull);
    });

    test('isPreloaded returns false initially', () {
      expect(SvgPreloadService.isPreloaded, isFalse);
    });

    test('clearCache() can be called multiple times safely', () {
      for (int i = 0; i < 5; i++) {
        expect(() => SvgPreloadService.clearCache(), returnsNormally);
        expect(SvgPreloadService.isPreloaded, isFalse);
      }
    });

    test('all getters return consistent null state when cache is empty', () {
      SvgPreloadService.clearCache();

      final svg = SvgPreloadService.getCachedSvg();
      final doc = SvgPreloadService.getCachedDoc();
      final cache = SvgPreloadService.getElementCache();
      final preloaded = SvgPreloadService.isPreloaded;

      expect(svg, isNull);
      expect(doc, isNull);
      expect(cache, isNull);
      expect(preloaded, isFalse);
    });

    // Note: preloadCardSvg() cannot be properly tested in a unit test environment
    // because it requires:
    // 1. Flutter's rootBundle to be initialized with actual asset files
    // 2. The SVG card asset to exist at the expected path
    // 3. Full Flutter framework initialization (not just TestWidgetsFlutterBinding)
    //
    // This method should be tested in integration tests or widget tests with
    // properly configured test assets. Unit tests focus on the cache management
    // APIs that don't require asset loading.
  });
}
