import 'package:flutter/material.dart';

import 'package:ctg_app/core/theme/app_colors.dart';
import 'package:ctg_app/core/theme/app_text_styles.dart';

class GoogleSignInButton extends StatelessWidget {
  const GoogleSignInButton({required this.onPressed, super.key});

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.ink,
        side: const BorderSide(color: AppColors.line, width: 1.5),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Google G icon (simplified SVG path via custom painter)
          _GoogleIcon(),
          const SizedBox(width: 10),
          Text(
            'Continuar con Google',
            style: AppTextStyles.labelMd,
          ),
        ],
      ),
    );
  }
}

class _GoogleIcon extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: 20,
      child: CustomPaint(painter: _GooglePainter()),
    );
  }
}

class _GooglePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final r = size.width / 2;

    // Simplified: draw colored arcs to approximate Google G
    final paint = Paint()..style = PaintingStyle.stroke..strokeWidth = 2.5;

    // Blue
    paint.color = const Color(0xFF4285F4);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: r - 1),
      -0.3,
      1.9,
      false,
      paint,
    );
    // Green
    paint.color = const Color(0xFF34A853);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: r - 1),
      1.6,
      1.0,
      false,
      paint,
    );
    // Yellow
    paint.color = const Color(0xFFFBBC05);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: r - 1),
      2.6,
      0.8,
      false,
      paint,
    );
    // Red
    paint.color = const Color(0xFFEA4335);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: r - 1),
      3.4,
      0.8,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
