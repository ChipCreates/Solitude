import 'package:flutter/material.dart';
import 'package:solitude/features/game/models/move.dart';
import 'package:solitude/features/game/models/pile.dart';
import 'package:solitude/features/game/services/game_controller.dart';

/// A widget that displays the move history with undo/redo navigation
class MoveHistoryViewer extends StatelessWidget {
  final GameController controller;

  const MoveHistoryViewer({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final moveHistory = controller.moveHistory;
    final redoHistory = controller.redoHistory;

    if (moveHistory.isEmpty && redoHistory.isEmpty) {
      return Center(
        child: Text(
          'No moves yet',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
      );
    }

    return ListView(
      children: [
        // Redo stack (shown in reverse order, most recent at top)
        if (redoHistory.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Undone Moves (${redoHistory.length})',
              style: theme.textTheme.titleSmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ),
          ...redoHistory.reversed.map((move) => _MoveHistoryTile(
                move: move,
                isUndone: true,
                onTap: () => controller.redo(),
              )),
          const Divider(),
        ],

        // Current move history
        if (moveHistory.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Moves (${moveHistory.length})',
              style: theme.textTheme.titleSmall,
            ),
          ),
          ...moveHistory.reversed.map((move) => _MoveHistoryTile(
                move: move,
                isUndone: false,
                onTap: () => controller.undo(),
              )),
        ],
      ],
    );
  }
}

class _MoveHistoryTile extends StatelessWidget {
  final Move move;
  final bool isUndone;
  final VoidCallback onTap;

  const _MoveHistoryTile({
    required this.move,
    required this.isUndone,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListTile(
      leading: Icon(
        _getMoveIcon(),
        color: isUndone
            ? theme.colorScheme.onSurface.withValues(alpha: 0.4)
            : theme.colorScheme.primary,
      ),
      title: Text(
        move.description,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: isUndone
              ? theme.colorScheme.onSurface.withValues(alpha: 0.4)
              : theme.colorScheme.onSurface,
          decoration: isUndone ? TextDecoration.lineThrough : null,
        ),
      ),
      trailing: isUndone
          ? IconButton(
              icon: const Icon(Icons.redo),
              tooltip: 'Redo',
              onPressed: onTap,
            )
          : IconButton(
              icon: const Icon(Icons.undo),
              tooltip: 'Undo',
              onPressed: onTap,
            ),
      dense: true,
    );
  }

  IconData _getMoveIcon() {
    if (move.drewFromStock) {
      if (move.toPile.type == PileType.stock) {
        return Icons.refresh; // Recycle
      }
      return Icons.style; // Draw cards
    }

    if (move.toPile.type == PileType.foundation) {
      return Icons.arrow_upward; // To foundation
    }

    return Icons.swap_horiz; // Tableau move
  }
}

/// A widget that displays move history with the ability to jump to any point
class MoveHistoryViewerWithJump extends StatelessWidget {
  final GameController controller;
  final ScrollController? scrollController;
  final VoidCallback? onClose;

  const MoveHistoryViewerWithJump({
    super.key,
    required this.controller,
    this.scrollController,
    this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final moveHistory = controller.moveHistory;
    final redoHistory = controller.redoHistory;
    final totalMoves = moveHistory.length + redoHistory.length;

    if (totalMoves == 0) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.history,
              size: 64,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'No moves yet',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: scrollController,
      itemCount: totalMoves + 2, // +2 for section headers
      itemBuilder: (context, index) {
        // First section: Undone moves (if any)
        if (redoHistory.isNotEmpty) {
          if (index == 0) {
            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Icon(
                    Icons.redo,
                    size: 20,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Undone Moves (${redoHistory.length})',
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            );
          }

          if (index <= redoHistory.length) {
            final redoIndex = index - 1;
            final move = redoHistory[redoHistory.length - 1 - redoIndex];
            final moveNumber = moveHistory.length + redoIndex + 1;

            return _JumpableMoveHistoryTile(
              move: move,
              moveNumber: moveNumber,
              isUndone: true,
              onJump: () {
                // Redo to this point
                final redosNeeded = redoIndex + 1;
                for (int i = 0; i < redosNeeded; i++) {
                  controller.redo();
                }
                onClose?.call();
              },
            );
          }

          if (index == redoHistory.length + 1) {
            return const Divider(height: 32);
          }

          // Adjust index for move history section
          index = (index - redoHistory.length - 2).toInt();
        }

        // Second section: Current move history
        if (index == 0) {
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Icon(
                  Icons.check_circle_outline,
                  size: 20,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Active Moves (${moveHistory.length})',
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
          );
        }

        final moveIndex = index - 1;
        if (moveIndex >= moveHistory.length) return const SizedBox.shrink();

        final move = moveHistory[moveHistory.length - 1 - moveIndex];
        final moveNumber = moveHistory.length - moveIndex;

        return _JumpableMoveHistoryTile(
          move: move,
          moveNumber: moveNumber,
          isUndone: false,
          isCurrent: moveIndex == 0, // Most recent move
          onJump: () {
            // Undo to this point
            final undosNeeded = moveIndex;
            for (int i = 0; i < undosNeeded; i++) {
              controller.undo();
            }
            onClose?.call();
          },
        );
      },
    );
  }
}

class _JumpableMoveHistoryTile extends StatelessWidget {
  final Move move;
  final int moveNumber;
  final bool isUndone;
  final bool isCurrent;
  final VoidCallback onJump;

  const _JumpableMoveHistoryTile({
    required this.move,
    required this.moveNumber,
    required this.isUndone,
    this.isCurrent = false,
    required this.onJump,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: isUndone
              ? theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5)
              : isCurrent
                  ? theme.colorScheme.primaryContainer
                  : theme.colorScheme.surfaceContainerHighest,
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Icon(
            _getMoveIcon(),
            size: 20,
            color: isUndone
                ? theme.colorScheme.onSurface.withValues(alpha: 0.4)
                : isCurrent
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurface,
          ),
        ),
      ),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: isUndone
                  ? theme.colorScheme.onSurface.withValues(alpha: 0.1)
                  : theme.colorScheme.primary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              '#$moveNumber',
              style: theme.textTheme.labelSmall?.copyWith(
                color: isUndone
                    ? theme.colorScheme.onSurface.withValues(alpha: 0.5)
                    : theme.colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              move.description,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: isUndone
                    ? theme.colorScheme.onSurface.withValues(alpha: 0.4)
                    : theme.colorScheme.onSurface,
                decoration: isUndone ? TextDecoration.lineThrough : null,
              ),
            ),
          ),
        ],
      ),
      trailing: isCurrent
          ? Chip(
              label: Text(
                'Current',
                style: theme.textTheme.labelSmall,
              ),
              backgroundColor: theme.colorScheme.primaryContainer,
              padding: EdgeInsets.zero,
              visualDensity: VisualDensity.compact,
            )
          : TextButton.icon(
              icon: const Icon(Icons.restore, size: 16),
              label: const Text('Jump'),
              onPressed: onJump,
              style: TextButton.styleFrom(
                visualDensity: VisualDensity.compact,
              ),
            ),
      dense: true,
    );
  }

  IconData _getMoveIcon() {
    if (move.drewFromStock) {
      if (move.toPile.type == PileType.stock) {
        return Icons.refresh; // Recycle
      }
      return Icons.style; // Draw cards
    }

    if (move.toPile.type == PileType.foundation) {
      return Icons.arrow_upward; // To foundation
    }

    return Icons.swap_horiz; // Tableau move
  }
}
