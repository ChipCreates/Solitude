import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Custom volume slider with progress bar styling
/// Blue fill on the left of the handle, base color on the right
class VolumeSlider extends StatelessWidget {
  final double value; // 0.0 to 1.0
  final ValueChanged<double> onChanged;

  const VolumeSlider({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        const trackHeight = 16.0; // Height of the slider track (doubled from 8)
        const thumbSize = 24.0; // Size of the drag handle (increased from 20)

        return GestureDetector(
          onHorizontalDragUpdate: (details) {
            final dx = details.localPosition.dx;
            final newValue = (dx / width).clamp(0.0, 1.0);
            onChanged(newValue);
          },
          onTapDown: (details) {
            final dx = details.localPosition.dx;
            final newValue = (dx / width).clamp(0.0, 1.0);
            onChanged(newValue);
          },
          child: Container(
            width: width,
            height: thumbSize,
            alignment: Alignment.centerLeft,
            child: Stack(
              alignment: Alignment.centerLeft,
              children: [
                // Background track (inactive/right side)
                Container(
                  width: width,
                  height: trackHeight,
                  decoration: BoxDecoration(
                    color: AppTheme.buttonColor(context).withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(trackHeight / 2),
                    border: Border.all(
                      color: AppTheme.buttonBorderColor(context).withValues(alpha: 0.2),
                      width: 1,
                    ),
                  ),
                ),

                // Active track (filled/left side)
                Container(
                  width: width * value,
                  height: trackHeight,
                  decoration: BoxDecoration(
                    color: AppTheme.accentColor(context),
                    borderRadius: BorderRadius.circular(trackHeight / 2),
                  ),
                ),

                // Thumb/handle
                Positioned(
                  left: (width - thumbSize) * value,
                  child: Container(
                    width: thumbSize,
                    height: thumbSize,
                    decoration: BoxDecoration(
                      color: AppTheme.cardFaceColor(context),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppTheme.accentColor(context),
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha:0.3),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
