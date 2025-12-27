import 'package:flutter/material.dart';
import '../widgets/card_widget.dart';

class LayoutConfig {
  final double cardWidth;
  final double cardHeight;
  final double tableauStackOffset;
  final double pileSpacing;
  final EdgeInsets padding;
  final bool isLandscape;
  
  const LayoutConfig({
    required this.cardWidth,
    required this.cardHeight,
    required this.tableauStackOffset,
    required this.pileSpacing,
    required this.padding,
    required this.isLandscape,
  });
}

class LayoutCalculator {
  static const double minCardWidth = 55.0;
  static const double maxCardWidth = 100.0;
  static const double idealCardWidth = 75.0;
  
  static const int tableauCount = 7;
  static const int foundationCount = 4;
  
  static LayoutConfig calculate(Size screenSize, EdgeInsets safeArea) {
    final isLandscape = screenSize.width > screenSize.height;
    
    // Available space
    final availableWidth = screenSize.width - safeArea.left - safeArea.right;
    final availableHeight = screenSize.height - safeArea.top - safeArea.bottom;
    
    // Calculate padding
    final horizontalPadding = availableWidth * 0.02;
    final verticalPadding = availableHeight * 0.01;
    final padding = EdgeInsets.symmetric(
      horizontal: horizontalPadding.clamp(8.0, 20.0),
      vertical: verticalPadding.clamp(8.0, 16.0),
    );
    
    // Usable width after padding
    final usableWidth = availableWidth - padding.horizontal;
    
    // Calculate card width to fit 7 tableau piles with spacing
    const gapCount = tableauCount - 1;
    const minGapWidth = 4.0;
    
    // First pass: calculate ideal card width
    double cardWidth = (usableWidth - gapCount * minGapWidth) / tableauCount;
    
    // Clamp to acceptable range
    cardWidth = cardWidth.clamp(minCardWidth, maxCardWidth);
    
    // Recalculate spacing based on final card width
    final totalCardWidth = cardWidth * tableauCount;
    final remainingSpace = usableWidth - totalCardWidth;
    final pileSpacing = (remainingSpace / gapCount).clamp(4.0, 20.0);
    
    // Calculate card height from aspect ratio
    final cardHeight = cardWidth / CardWidget.aspectRatio;
    
    // Calculate stack offset for tableau piles
    const toolbarHeight = 60.0;
    final topRowHeight = cardHeight;
    const gapBetweenRows = 16.0;
    
    final tableauAvailableHeight = availableHeight - 
        safeArea.top - 
        toolbarHeight - 
        topRowHeight - 
        gapBetweenRows - 
        padding.vertical - 
        cardHeight;
    
    const maxStackedCards = 15;
    
    final idealOffset = cardHeight * 0.18;
    final minOffset = cardHeight * 0.12;
    
    final maxOffset = tableauAvailableHeight / maxStackedCards;
    
    final tableauStackOffset = maxOffset.clamp(minOffset, idealOffset);
    
    return LayoutConfig(
      cardWidth: cardWidth,
      cardHeight: cardHeight,
      tableauStackOffset: tableauStackOffset,
      pileSpacing: pileSpacing,
      padding: padding,
      isLandscape: isLandscape,
    );
  }
  
  static double calculateMaxTableauHeight(LayoutConfig config, int maxCards) {
    return config.cardHeight + (maxCards - 1) * config.tableauStackOffset;
  }
}
