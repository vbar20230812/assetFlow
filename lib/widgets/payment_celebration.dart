import 'dart:math';
import 'package:flutter/material.dart';

/// A confetti animation widget for celebrating payments
class ConfettiAnimation extends StatefulWidget {
  final double width;
  final double height;

  const ConfettiAnimation({
    super.key,
    this.width = 300,
    this.height = 300,
  });

  @override
  State<ConfettiAnimation> createState() => _ConfettiAnimationState();
}

class _ConfettiAnimationState extends State<ConfettiAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late List<ConfettiPiece> _confetti;
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );

    // Generate confetti pieces
    _confetti = List.generate(
      100,
      (_) => ConfettiPiece(
        x: _random.nextDouble() * widget.width,
        y: -20 - _random.nextDouble() * 50, // Start above the visible area
        size: 5 + _random.nextDouble() * 10,
        color: _getRandomColor(),
        velocity: _random.nextDouble() * 250 + 100,
        angle: _random.nextDouble() * 2 * pi,
        angularVelocity: _random.nextDouble() * 4 - 2,
      ),
    );

    // Start the animation
    _controller.forward();

    // Add animation listener to update confetti positions
    _controller.addListener(() {
      if (mounted) {
        setState(() {
          for (var piece in _confetti) {
            // Update position based on velocity and time
            piece.y += piece.velocity * _controller.value / 10;
            piece.x += sin(piece.angle) * 2;
            piece.angle += piece.angularVelocity * 0.01;
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Color _getRandomColor() {
    final colors = [
      Colors.red,
      Colors.green,
      Colors.blue,
      Colors.yellow,
      Colors.purple,
      Colors.orange,
      Colors.pink,
      Colors.teal,
    ];
    return colors[_random.nextInt(colors.length)];
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.width,
      height: widget.height,
      child: CustomPaint(
        painter: ConfettiPainter(confetti: _confetti),
      ),
    );
  }
}

/// Custom painter for drawing confetti
class ConfettiPainter extends CustomPainter {
  final List<ConfettiPiece> confetti;

  ConfettiPainter({required this.confetti});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();

    for (var piece in confetti) {
      paint.color = piece.color;
      canvas.save();
      canvas.translate(piece.x, piece.y);
      canvas.rotate(piece.angle);

      // Draw different shapes for variety
      if (piece.size.toInt() % 3 == 0) {
        // Draw circle
        canvas.drawCircle(Offset.zero, piece.size / 2, paint);
      } else if (piece.size.toInt() % 3 == 1) {
        // Draw square
        canvas.drawRect(
          Rect.fromCenter(
            center: Offset.zero,
            width: piece.size,
            height: piece.size,
          ),
          paint,
        );
      } else {
        // Draw triangle
        final path = Path();
        path.moveTo(0, -piece.size / 2);
        path.lineTo(piece.size / 2, piece.size / 2);
        path.lineTo(-piece.size / 2, piece.size / 2);
        path.close();
        canvas.drawPath(path, paint);
      }

      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldPainter) => true;
}

/// Data class for a single confetti piece
class ConfettiPiece {
  double x;
  double y;
  double size;
  Color color;
  double velocity;
  double angle;
  double angularVelocity;

  ConfettiPiece({
    required this.x,
    required this.y,
    required this.size,
    required this.color,
    required this.velocity,
    required this.angle,
    required this.angularVelocity,
  });
}

/// Dialog that shows a payment celebration with confetti
class PaymentCelebrationDialog extends StatelessWidget {
  final String amount;
  final String currency;
  final String projectName;

  const PaymentCelebrationDialog({
    super.key,
    required this.amount,
    required this.currency,
    required this.projectName,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Container(
        width: 300,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              spreadRadius: 5,
            ),
          ],
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // Confetti animation
            const Positioned(
              top: -150,
              left: 0,
              right: 0,
              child: ConfettiAnimation(
                height: 200,
              ),
            ),
            // Content
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.celebration,
                  size: 60,
                  color: Colors.amber,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Congratulations!',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Your payment of $amount $currency from $projectName has been credited today!',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('Awesome!'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}