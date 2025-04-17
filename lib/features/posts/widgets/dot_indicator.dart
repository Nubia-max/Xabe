import 'package:flutter/material.dart';

class DotIndicator extends StatelessWidget {
  final int index;
  final double currentPage; // Can be a fraction for smooth transitions.
  final int totalDots;

  const DotIndicator({
    super.key,
    required this.index,
    required this.currentPage,
    required this.totalDots,
  });

  // Calculate the scale based on the distance from the active dot.
  double _calculateScale() {
    final distance = (currentPage - index).abs();

    // When the dot is exactly active, scale up.
    if (distance < 0.5) {
      return 1.0;
    }
    // Nearby dots have an intermediate size.
    else if (distance < 1.0) {
      return 1.0;
    }
    // Dots further away shrink.
    else if (distance < 2.0) {
      return 0.8;
    }
    // Very far dots get minimized.
    else {
      return 0.6;
    }
  }

  // Choose a color based on proximity to the current page.
  Color _calculateColor() {
    final distance = (currentPage - index).abs();
    if (distance < 0.5) {
      return Colors.white;
    } else {
      return Colors.grey.withOpacity(0.6);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scale = _calculateScale();
    final color = _calculateColor();

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      // We adjust the container size based on the scale.
      width: 8 * scale,
      height: 8 * scale,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
      ),
    );
  }
}
