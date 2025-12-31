import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/game_controller.dart';

/// Floating Action Button for auto-finishing the game.
/// Only visible when the game is in a state that can be auto-completed.
class AutoFinishFab extends StatelessWidget {
  const AutoFinishFab({super.key});

  @override
  Widget build(BuildContext context) {
    return Selector<GameController, bool>(
      selector: (_, controller) => controller.canAutoFinish,
      builder: (context, canAutoFinish, _) {
        if (!canAutoFinish) {
          return const SizedBox.shrink();
        }

        final controller = context.read<GameController>();

        return FloatingActionButton.extended(
          onPressed: controller.autoFinishGame,
          label: const Text('Auto Finish'),
          icon: const Icon(Icons.auto_awesome),
          backgroundColor: Theme.of(context).colorScheme.primary,
          foregroundColor: Theme.of(context).colorScheme.onPrimary,
        );
      },
    );
  }
}
