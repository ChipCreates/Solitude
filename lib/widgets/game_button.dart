import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class GameButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isPrimary;
  final double? width;
  final IconData? icon;
  
  const GameButton({
    super.key,
    required this.label,
    this.onPressed,
    this.isPrimary = false,
    this.width,
    this.icon,
  });

  @override
  State<GameButton> createState() => _GameButtonState();
}

class _GameButtonState extends State<GameButton> {
  bool _isPressed = false;
  bool _isHovered = false;
  
  @override
  Widget build(BuildContext context) {
    final accent = AppTheme.accentColor(context);
    final baseColor = widget.isPrimary
        ? accent.withValues(alpha: 0.18)
        : AppTheme.buttonColor(context);

    final borderColor = widget.isPrimary
        ? accent.withValues(alpha: _isHovered ? 0.7 : 0.45)
        : AppTheme.buttonBorderColor(context).withValues(alpha: _isHovered ? 0.6 : 0.35);
    
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) {
          setState(() => _isPressed = false);
          widget.onPressed?.call();
        },
        onTapCancel: () => setState(() => _isPressed = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 100),
          width: widget.width,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          transform: Matrix4.identity()..translateByDouble(0.0, _isPressed ? 1.0 : 0.0, 0.0, 1.0),
            decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: _isPressed
                ? [baseColor.withValues(alpha:0.6), baseColor]
                : [baseColor, baseColor.withValues(alpha:0.9)],
            ),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: borderColor, width: 1),
            boxShadow: _isPressed
                ? []
                : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha:0.2),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (widget.icon != null) ...[
                Icon(
                  widget.icon,
                  size: 18,
                  color: AppTheme.textColor(context),
                ),
                const SizedBox(width: 8),
              ],
              Text(
                widget.label,
                style: AppTypography.button(context),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class GameIconButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final String? tooltip;
  final String? label;
  final double size;

  const GameIconButton({
    super.key,
    required this.icon,
    this.onPressed,
    this.tooltip,
    this.label,
    this.size = 44,
  });

  @override
  State<GameIconButton> createState() => _GameIconButtonState();
}

class _GameIconButtonState extends State<GameIconButton> {
  bool _isPressed = false;
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) {
          setState(() => _isPressed = false);
          widget.onPressed?.call();
        },
        onTapCancel: () => setState(() => _isPressed = false),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 100),
              width: widget.size,
              height: widget.size,
              decoration: BoxDecoration(
                color: _isPressed
                    ? AppTheme.buttonColor(context).withValues(alpha:0.25)
                    : (_isHovered ? AppTheme.buttonColor(context).withValues(alpha:0.15) : Colors.transparent),
                borderRadius: BorderRadius.circular(widget.size / 2),
              ),
              child: Icon(
                widget.icon,
                size: widget.size * 0.5,
                color: widget.onPressed != null
                    ? AppTheme.textColor(context)
                    : AppTheme.mutedTextColor(context),
              ),
            ),
            if (widget.label != null) ...[
              const SizedBox(height: 2),
              Text(
                widget.label!,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: widget.onPressed != null
                      ? AppTheme.textColor(context)
                      : AppTheme.mutedTextColor(context),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
