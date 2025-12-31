import 'package:flutter/material.dart';

/// Wraps a pile widget with a keyboard focus indicator
class FocusedPileWrapper extends StatelessWidget {
  final Widget child;
  final bool isFocused;
  final double width;

  const FocusedPileWrapper({
    super.key,
    required this.child,
    required this.isFocused,
    required this.width,
  });

  @override
  Widget build(BuildContext context) {
    if (!isFocused) return child;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(width * 0.06),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withValues(alpha:0.6),
            blurRadius: 12,
            spreadRadius: 2,
          ),
        ],
      ),
      child: child,
    );
  }
}
