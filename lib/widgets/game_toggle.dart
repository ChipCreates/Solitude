import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class GameToggleOption<T> {
  final T value;
  final String? label;
  final Widget? child;
  final Color? color; // Optional color for the option

  const GameToggleOption({
    required this.value,
    this.label,
    this.child,
    this.color,
  });
}

class GameToggle<T> extends StatelessWidget {
  final T value;
  final List<GameToggleOption<T>> options;
  final ValueChanged<T> onChanged;
  
  const GameToggle({
    super.key,
    required this.value,
    required this.options,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final accent = AppTheme.accentColor(context);

    return Container(
      decoration: BoxDecoration(
        color: accent.withValues(alpha:0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: accent.withValues(alpha:0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: options.map((option) {
          final isSelected = option.value == value;
          return GestureDetector(
            onTap: () => onChanged(option.value),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: isSelected
                    ? accent.withValues(alpha:0.25)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(7),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: Colors.black.withValues(alpha:0.2),
                          blurRadius: 2,
                          offset: const Offset(0, 1),
                        ),
                      ]
                    : null,
              ),
              child: option.child != null
                  ? Center(child: option.child)
                  : Text(
                      option.label ?? '',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 14,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                        color: option.color != null
                            ? (isSelected ? option.color : option.color!.withValues(alpha:0.6))
                            : (isSelected ? AppColors.cream : AppColors.cream.withValues(alpha:0.6)),
                      ),
                    ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class GameSwitch extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;
  
  const GameSwitch({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final accent = AppTheme.accentColor(context);

    return GestureDetector(
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 52,
        height: 28,
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: value
              ? accent.withValues(alpha:0.35)
              : accent.withValues(alpha:0.12),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: value
                ? accent.withValues(alpha:0.5)
                : accent.withValues(alpha:0.3),
            width: 1,
          ),
        ),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          alignment: value ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              color: AppColors.cream,
              borderRadius: BorderRadius.circular(11),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha:0.2),
                  blurRadius: 2,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
