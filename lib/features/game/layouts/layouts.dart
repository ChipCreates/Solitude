/// Layout strategy system for game-agnostic card positioning.
///
/// This module provides the abstraction layer between game logic and rendering,
/// allowing different games to define their own layout strategies without
/// modifying the core engine.
///
/// Architecture (Option B - Raw Constraints):
/// - [LayoutStrategy] - Abstract base class receiving raw [BoxConstraints]
/// - [GridLayoutMixin] - Mixin for grid-based games (shared calculations)
/// - [GridLayoutMetrics] - Internal metrics for grid layouts
/// - [CardPosition] - Absolute positioning for stack-based layouts
/// - [LayoutStrategyFactory] - Creates strategies based on GameType
///
/// Key Design Decisions:
/// - Each strategy owns ALL layout decisions
/// - GameBoard only provides the felt background
/// - Strategies receive raw constraints and calculate what they need
/// - Grid strategies share logic via mixin; non-grid strategies are independent
///
/// Concrete Strategies:
/// - [KlondikeLayoutStrategy] - Grid layout for Klondike (7 columns)
/// - [SpiderLayoutStrategy] - Grid layout for Spider (10 columns)
///
/// Future strategies can implement:
/// - Stack-based layouts for Pyramid, TriPeaks, Golf
/// - Custom layouts for specialized games
library;

export 'layout_strategy.dart';
export 'layout_strategy_factory.dart';
export 'klondike_layout_strategy.dart';
export 'spider_layout_strategy.dart';
