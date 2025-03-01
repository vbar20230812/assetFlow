import 'package:flutter/material.dart';
// Import math for pi calculation
import 'dart:math' as math;

/// A customizable loading indicator widget for the AssetFlow app
class AssetFlowLoader extends StatefulWidget {
  /// Size of the loader
  final double size;

  /// Optional primary color for the loader
  final Color? primaryColor;

  /// Optional secondary color for the loader
  final Color? secondaryColor;

  /// Duration of the animation (optional)
  final Duration? duration;

  const AssetFlowLoader({
    super.key,
    this.size = 50.0,
    this.primaryColor,
    this.secondaryColor,
    this.duration,
  });

  @override
  AssetFlowLoaderState createState() => AssetFlowLoaderState();
}

class AssetFlowLoaderState extends State<AssetFlowLoader> 
    with SingleTickerProviderStateMixin {
  
  /// Animation controller for the loader
  late AnimationController _controller;

  /// Primary animation used for the loader
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();

    // Initialize the animation controller
    _controller = AnimationController(
      duration: widget.duration ?? const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    // Create a curved animation for smoother movement
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    // Always dispose of the animation controller to prevent memory leaks
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Use theme colors if not provided
    final effectivePrimaryColor = widget.primaryColor ?? 
        Theme.of(context).primaryColor;
    final effectiveSecondaryColor = widget.secondaryColor ?? 
        Theme.of(context).colorScheme.secondary;

    return Center(
      child: SizedBox(
        width: widget.size,
        height: widget.size,
        child: AnimatedBuilder(
          animation: _animation,
          builder: (context, child) {
            return CustomPaint(
              painter: _LoaderPainter(
                progress: _animation.value,
                primaryColor: effectivePrimaryColor,
                secondaryColor: effectiveSecondaryColor,
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Custom painter to create a sophisticated loader animation
class _LoaderPainter extends CustomPainter {
  final double progress;
  final Color primaryColor;
  final Color secondaryColor;

  _LoaderPainter({
    required this.progress,
    required this.primaryColor,
    required this.secondaryColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = primaryColor
      ..strokeWidth = 4.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Create an arc that animates based on the progress
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,  // Start from the top
      2 * math.pi * progress,  // Sweep angle based on progress
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(_LoaderPainter oldDelegate) {
    return oldDelegate.progress != progress ||
           oldDelegate.primaryColor != primaryColor ||
           oldDelegate.secondaryColor != secondaryColor;
  }
}

