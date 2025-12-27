import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:xml/xml.dart' as xml;
import '../models/card.dart';
import 'package:provider/provider.dart';
import '../services/settings_provider.dart';
import '../services/svg_preload_service.dart';

/// Custom widget that renders individual cards from htdebeer's svg-cards.svg
/// by extracting the specific card element and rendering it standalone.
class SvgCardRenderer extends StatefulWidget {
  final PlayingCard card;
  final double width;
  final String? overrideElementId;
  final String? overrideFillColor;
  
  const SvgCardRenderer({
    super.key,
    required this.card,
    required this.width,
    this.overrideElementId,
    this.overrideFillColor,
  });
  
  @override
  State<SvgCardRenderer> createState() => _SvgCardRendererState();
}

class _SvgCardRendererState extends State<SvgCardRenderer> {
  String? _cardSvgString;
  static final Map<String, String> _perCardSvgCache = {};

  // Use static getters to access preloaded cache from SvgPreloadService
  static String? get _cachedFullSvg => SvgPreloadService.getCachedSvg();
  static xml.XmlDocument? get _cachedSvgDoc => SvgPreloadService.getCachedDoc();
  static Map<String, xml.XmlElement>? get _elementCache => SvgPreloadService.getElementCache();
  
  @override
  void initState() {
    super.initState();
    _loadCardSvg();
    // Listen for settings changes so back color/variant update immediately
    final settings = Provider.of<SettingsProvider>(context, listen: false);
    settings.addListener(_onSettingsChanged);
  }

  void _onSettingsChanged() {
    // Clear per-card cache so back/face changes take effect immediately
    _perCardSvgCache.clear();
    if (mounted) {
      _loadCardSvg();
    }
  }
  
  @override
  void didUpdateWidget(SvgCardRenderer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.card != widget.card ||
        oldWidget.overrideElementId != widget.overrideElementId ||
        oldWidget.overrideFillColor != widget.overrideFillColor) {
      _loadCardSvg();
    }
  }

  @override
  void dispose() {
    // remove settings listener
    try {
      final settings = Provider.of<SettingsProvider>(context, listen: false);
      settings.removeListener(_onSettingsChanged);
    } catch (_) {}
    super.dispose();
  }
  
  Future<void> _loadCardSvg() async {
    try {
      // CRITICAL: Read settings synchronously BEFORE any await to avoid using BuildContext after dispose
      if (!mounted) return;
      final settings = Provider.of<SettingsProvider>(context, listen: false);

      // Check if SVG has been preloaded
      if (_cachedFullSvg == null || _cachedSvgDoc == null) {
        // SVG should have been preloaded in main(), but fallback to loading if needed
        await SvgPreloadService.preloadCardSvg();
        if (!mounted) return;
      }

      // Determine element id: override takes precedence
      String elementId = widget.overrideElementId ?? _getCardElementId();
      if (!widget.card.faceUp && widget.overrideElementId == null) {
        if (settings.cardBackVariant == 'alternate') {
          elementId = 'alternate-back';
        } else {
          elementId = 'back';
        }
      }
      var extractedSvg = _extractCardElement(elementId, selectedColor: widget.overrideFillColor ?? ( (!widget.card.faceUp && settings.cardBackColored) ? settings.cardBackColor : null ));

      // If face-down and user selected colored back, set the SVG root fill
      // so internal elements that use `fill:inherit` pick up the color.
      // Fill color override precedence: explicit widget.overrideFillColor -> settings.cardBackColor
      final selectedColor = widget.overrideFillColor ?? ( (!widget.card.faceUp && settings.cardBackColored) ? settings.cardBackColor : null );
      if (selectedColor != null) {
        final color = selectedColor;
        // Find opening <svg ...> tag and inject a fill attribute
        // ignore: deprecated_member_use
        final svgOpenMatch = RegExp(r'<svg[^>]*>').firstMatch(extractedSvg);
        if (svgOpenMatch != null) {
          final svgOpen = svgOpenMatch.group(0)!;
          if (!svgOpen.contains(' fill=')) {
            // ignore: deprecated_member_use
            final replaced = svgOpen.replaceFirst(RegExp(r'<svg'), '<svg fill="$color"');
            extractedSvg = extractedSvg.replaceFirst(svgOpen, replaced);
          }
        }
        // Also replace any `fill:inherit` occurrences so elements using style inherit
        // ignore: deprecated_member_use
        extractedSvg = extractedSvg.replaceAll(RegExp(r'fill\s*:\s*inherit'), 'fill:$color');
      }

      if (mounted) {
        setState(() {
          _cardSvgString = extractedSvg;
        });
      }
    } catch (e) {
      // Provide a simple fallback SVG showing rank and suit so the UI
      // remains usable even if the full SVG asset isn't available.
      final fallbackSvg = '''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 169 245">
  <rect width="100%" height="100%" rx="6" ry="6" fill="#FFFFFF" stroke="#333" />
  <text x="8" y="28" font-family="Inter, sans-serif" font-size="28" fill="#000">${widget.card.displayRank}</text>
  <text x="8" y="56" font-family="Inter, sans-serif" font-size="28" fill="${widget.card.isRed ? '#C33' : '#000'}">${widget.card.displaySuit}</text>
</svg>
''';

      if (mounted) {
        setState(() {
          _cardSvgString = fallbackSvg;
        });
      }
    }
  }
  
  /// Converts our card model to htdebeer SVG-cards element ID
  String _getCardElementId() {
    if (!widget.card.faceUp) {
      return 'alternate-back';
    }
    
    final suitName = widget.card.suit.name.toLowerCase();
    final String suitPrefix = suitName.endsWith('s') 
      ? suitName.substring(0, suitName.length - 1)
      : suitName;
    
    String rankSuffix;
    switch (widget.card.rank) {
      case Rank.ace:
        rankSuffix = '1';
        break;
      case Rank.jack:
        rankSuffix = 'jack';
        break;
      case Rank.queen:
        rankSuffix = 'queen';
        break;
      case Rank.king:
        rankSuffix = 'king';
        break;
      default:
        rankSuffix = widget.card.rankName;
    }
    
    return '${suitPrefix}_$rankSuffix';
  }

  /// Extracts a specific card element from the full SVG and wraps it
  /// in a standalone SVG document
  String _extractCardElement(String elementId, {String? selectedColor}) {
    if (_cachedSvgDoc == null) {
      throw Exception('SVG document not loaded');
    }

    // Return cached per-card SVG if available
    final cacheKey = selectedColor == null ? elementId : '$elementId|$selectedColor';
    if (_perCardSvgCache.containsKey(cacheKey)) {
      return _perCardSvgCache[cacheKey]!;
    }

    // Find the element with the specified ID using cache (O(1) lookup)
    final element = _elementCache?[elementId];
    if (element == null) {
      throw Exception('Card element not found: $elementId');
    }

    // htdebeer cards are 169.075 x 244.64 (poker size in points)
    const cardWidth = 169.075;
    const cardHeight = 244.64;

    // Deep-copy the element
    final clonedElement = element.copy();

    // Collect referenced ids (from xlink:href or href attributes) recursively
    final Set<String> referencedIds = {};

    void collectRefs(xml.XmlNode node) {
      if (node is xml.XmlElement) {
        for (final attr in node.attributes) {
          final name = attr.name.local.toLowerCase();
          if (name == 'xlink:href' || name == 'href') {
            final val = attr.value;
            if (val.contains('#')) {
              final refId = val.split('#').last;
              if (refId.isNotEmpty) referencedIds.add(refId);
            }
          }
        }
        for (final child in node.children) {
          collectRefs(child);
        }
      }
    }

    collectRefs(clonedElement);

    // Resolve referenced elements from the full document and copy them
    final List<xml.XmlElement> defsToInline = [];
    final seen = <String>{};

    void resolveRef(String id) {
      if (seen.contains(id)) {
        return;
      }
      seen.add(id);

      // Use cache for O(1) lookup instead of O(n) traversal
      final def = _elementCache?[id];
      if (def != null) {
        final xml.XmlElement defCopy = def.copy();
        defsToInline.add(defCopy);

        // recursively collect refs from this definition
        final Set<String> nested = {};
        void collectNested(xml.XmlNode node) {
          if (node is xml.XmlElement) {
            for (final attr in node.attributes) {
              final name = attr.name.local.toLowerCase();
              if (name == 'xlink:href' || name == 'href') {
                final val = attr.value;
                if (val.contains('#')) {
                  final refId = val.split('#').last;
                  if (refId.isNotEmpty) nested.add(refId);
                }
              }
            }
            for (final child in node.children) {
              collectNested(child);
            }
          }
        }
        collectNested(defCopy);
        for (final nid in nested) {
          resolveRef(nid);
        }
      }
    }

    for (final id in referencedIds) {
      resolveRef(id);
    }

    // Build a minimal SVG wrapper with inlined definitions followed by the card
    final defsBuffer = StringBuffer();
    for (final d in defsToInline) {
      defsBuffer.writeln(d.toXmlString());
    }

    final svgString = '''
<svg xmlns="http://www.w3.org/2000/svg" 
     xmlns:xlink="http://www.w3.org/1999/xlink"
     viewBox="0 0 $cardWidth $cardHeight"
     width="$cardWidth"
     height="$cardHeight">
  ${defsBuffer.toString()}
  ${clonedElement.toXmlString()}
</svg>
''';

    _perCardSvgCache[cacheKey] = svgString;
    return svgString;
  }
  
  @override
  Widget build(BuildContext context) {
    if (_cardSvgString == null) {
      // Loading or error state
      return Container(
        width: widget.width,
        height: widget.width * (244.64 / 169.075),
        color: Colors.grey[300],
        child: const Center(
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }
    
    return SvgPicture.string(
      _cardSvgString!,
      width: widget.width,
      fit: BoxFit.contain,
    );
  }
}
