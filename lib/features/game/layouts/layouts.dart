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
/// Grid-based Strategies (use GridLayoutMixin):
/// - [KlondikeLayoutStrategy] - 7 columns, stock/waste, 4 foundations
/// - [SpiderLayoutStrategy] - 10 columns, stock only
/// - [FreeCellLayoutStrategy] - 8 columns, 4 free cells, 4 foundations
/// - [CanfieldLayoutStrategy] - 4 columns, reserve, stock/waste, 4 foundations
/// - [FortyThievesLayoutStrategy] - 10 columns, stock/waste, 8 foundations
/// - [YukonLayoutStrategy] - 7 columns, foundations only
/// - [ScorpionLayoutStrategy] - 7 columns, stock only
/// - [GolfLayoutStrategy] - 7 columns, stock/waste (waste is target)
///
/// Absolute-positioned Strategies (pyramid/tree layouts):
/// - [PyramidLayoutStrategy] - 28 cards in 7-row triangle, stock/waste/discard
/// - [TriPeaksLayoutStrategy] - 3 overlapping 4-row pyramids, stock/waste
library;

export 'layout_strategy.dart';
export 'layout_strategy_factory.dart';
// Grid-based layouts
export 'klondike_layout_strategy.dart';
export 'spider_layout_strategy.dart';
export 'freecell_layout_strategy.dart';
export 'canfield_layout_strategy.dart';
export 'forty_thieves_layout_strategy.dart';
export 'yukon_layout_strategy.dart';
export 'scorpion_layout_strategy.dart';
export 'golf_layout_strategy.dart';
// Absolute-positioned layouts
export 'pyramid_layout_strategy.dart';
export 'tripeaks_layout_strategy.dart';
