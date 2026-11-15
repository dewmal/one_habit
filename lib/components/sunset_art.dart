import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Sunset illustration: purple-to-pink sky, pale sun and navy mountains.
class SunsetArt extends StatelessWidget {
  const SunsetArt({super.key});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.sunsetPurple,
            AppColors.sunsetPink,
            AppColors.sunsetOrange,
          ],
          stops: [0.0, 0.6, 1.0],
        ),
        borderRadius: BorderRadius.all(Radius.circular(AppRadii.stageCard)),
      ),
      child: CustomPaint(painter: _SunsetPainter(), size: Size.infinite),
    );
  }
}

class _SunsetPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final sun = Paint()..color = const Color(0xFFFFDCC4);
    canvas.drawCircle(
      Offset(size.width * 0.7, size.height * 0.45),
      size.width * 0.12,
      sun,
    );

    final back = Paint()..color = AppColors.surface;
    final backRidge = Path()
      ..moveTo(0, size.height * 0.85)
      ..lineTo(size.width * 0.3, size.height * 0.5)
      ..lineTo(size.width * 0.5, size.height * 0.7)
      ..lineTo(size.width * 0.7, size.height * 0.4)
      ..lineTo(size.width, size.height * 0.7)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(backRidge, back);

    final front = Paint()..color = AppColors.bg;
    final frontRidge = Path()
      ..moveTo(0, size.height)
      ..lineTo(0, size.height * 0.9)
      ..lineTo(size.width * 0.4, size.height * 0.75)
      ..lineTo(size.width * 0.75, size.height * 0.9)
      ..lineTo(size.width, size.height * 0.8)
      ..lineTo(size.width, size.height)
      ..close();
    canvas.drawPath(frontRidge, front);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
