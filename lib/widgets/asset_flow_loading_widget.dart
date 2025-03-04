import 'package:flutter/material.dart';
import 'dart:math' as math;

/// A custom animated loader for AssetFlow app
class AssetFlowLoader extends StatefulWidget {
  final double size;
  final Color primaryColor;
  final Duration duration;

  const AssetFlowLoader({
    super.key,
    this.size = 50.0,
    this.primaryColor = Colors.indigo,
    this.duration = const Duration(seconds: 1),
  });

  @override
  State<AssetFlowLoader> createState() => _AssetFlowLoaderState();
}

class _AssetFlowLoaderState extends State<AssetFlowLoader>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: widget.size,
      width: widget.size,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Transform.rotate(
            angle: _controller.value * 2 * math.pi,
            child: CustomPaint(
              size: Size(widget.size, widget.size),
              painter: _LoaderPainter(
                primaryColor: widget.primaryColor,
                progress: _controller.value,
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Custom painter for the loader animation
class _LoaderPainter extends CustomPainter {
  final Color primaryColor;
  final double progress;

  _LoaderPainter({
    required this.primaryColor,
    required this.progress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final strokeWidth = radius * 0.2;

    // Create a gradient effect for the loader
    final gradient = SweepGradient(
      center: Alignment.center,
      startAngle: 0.0,
      endAngle: 2 * math.pi,
      colors: [
        primaryColor.withOpacity(0.3),
        primaryColor,
      ],
      stops: const [0.0, 1.0],
      transform: GradientRotation(progress * 2 * math.pi),
    );

    // Draw background circle
    final backgroundPaint = Paint()
      ..color = primaryColor.withOpacity(0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    canvas.drawCircle(center, radius - strokeWidth / 2, backgroundPaint);

    // Draw progress arc
    final foregroundPaint = Paint()
      ..shader = gradient.createShader(Rect.fromCircle(
        center: center,
        radius: radius,
      ))
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - strokeWidth / 2),
      0,
      progress * 2 * math.pi,
      false,
      foregroundPaint,
    );
  }

  @override
  bool shouldRepaint(_LoaderPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.primaryColor != primaryColor;
}