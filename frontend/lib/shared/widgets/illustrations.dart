import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../core/design_system.dart';

/// Custom illustration widget that supports SVG loading with fallback to custom graphics
/// Designed to replace Material icons with branded illustrations
class AppIllustration extends StatelessWidget {
  final String? assetPath;
  final IllustrationType type;
  final double? size;
  final Color? color;
  final bool showBackground;

  const AppIllustration({
    super.key,
    this.assetPath,
    required this.type,
    this.size,
    this.color,
    this.showBackground = false,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveSize = size ?? AppSizing.iconXl;
    final effectiveColor = color ?? AppColors.primary;

    // If asset path is provided, try to load it (SVG support would go here)
    // For now, we'll use custom-drawn illustrations as fallback
    return _buildCustomIllustration(effectiveSize, effectiveColor);
  }

  Widget _buildCustomIllustration(double size, Color color) {
    return SizedBox(
      width: size,
      height: size,
      child: showBackground
          ? Container(
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: _getIllustrationWidget(size, color),
            )
          : _getIllustrationWidget(size, color),
    );
  }

  Widget _getIllustrationWidget(double size, Color color) {
    switch (type) {
      case IllustrationType.emptySchools:
        return _EmptySchoolsIllustration(size: size, color: color);
      case IllustrationType.emptyAnnouncements:
        return _EmptyAnnouncementsIllustration(size: size, color: color);
      case IllustrationType.emptyAchievements:
        return _EmptyAchievementsIllustration(size: size, color: color);
      case IllustrationType.emptySearch:
        return _EmptySearchIllustration(size: size, color: color);
      case IllustrationType.success:
        return _SuccessIllustration(size: size, color: color);
      case IllustrationType.error:
        return _ErrorIllustration(size: size, color: color);
      case IllustrationType.education:
        return _EducationIllustration(size: size, color: color);
      case IllustrationType.community:
        return _CommunityIllustration(size: size, color: color);
      case IllustrationType.growth:
        return _GrowthIllustration(size: size, color: color);
    }
  }
}

enum IllustrationType {
  emptySchools,
  emptyAnnouncements,
  emptyAchievements,
  emptySearch,
  success,
  error,
  education,
  community,
  growth,
}

/// Custom empty state illustration for schools
class _EmptySchoolsIllustration extends StatelessWidget {
  final double size;
  final Color color;

  const _EmptySchoolsIllustration({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _EmptySchoolsPainter(color),
    );
  }
}

class _EmptySchoolsPainter extends CustomPainter {
  final Color color;

  _EmptySchoolsPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    final fillPaint = Paint()
      ..color = color.withOpacity(0.1)
      ..style = PaintingStyle.fill;

    final center = Offset(size.width / 2, size.height / 2);
    final scale = size.width / 100;

    // Draw school building shape
    final buildingPath = Path();
    buildingPath.moveTo(30 * scale, 70 * scale);
    buildingPath.lineTo(30 * scale, 40 * scale);
    buildingPath.lineTo(50 * scale, 25 * scale);
    buildingPath.lineTo(70 * scale, 40 * scale);
    buildingPath.lineTo(70 * scale, 70 * scale);
    buildingPath.close();

    canvas.drawPath(buildingPath, fillPaint);
    canvas.drawPath(buildingPath, paint);

    // Draw door
    final doorPath = Path();
    doorPath.moveTo(45 * scale, 70 * scale);
    doorPath.lineTo(45 * scale, 55 * scale);
    doorPath.lineTo(55 * scale, 55 * scale);
    doorPath.lineTo(55 * scale, 70 * scale);
    doorPath.close();

    canvas.drawPath(doorPath, paint);

    // Draw windows
    final windowPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    canvas.drawRect(
      Rect.fromLTWH(35 * scale, 45 * scale, 8 * scale, 8 * scale),
      windowPaint,
    );
    canvas.drawRect(
      Rect.fromLTWH(57 * scale, 45 * scale, 8 * scale, 8 * scale),
      windowPaint,
    );

    // Draw small question mark
    final textPainter = TextPainter(
      text: TextSpan(
        text: '?',
        style: TextStyle(
          color: color,
          fontSize: 20 * scale,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(center.dx - textPainter.width / 2, center.dy - textPainter.height / 2),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Custom empty state illustration for announcements
class _EmptyAnnouncementsIllustration extends StatelessWidget {
  final double size;
  final Color color;

  const _EmptyAnnouncementsIllustration({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _EmptyAnnouncementsPainter(color),
    );
  }
}

class _EmptyAnnouncementsPainter extends CustomPainter {
  final Color color;

  _EmptyAnnouncementsPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    final fillPaint = Paint()
      ..color = color.withOpacity(0.1)
      ..style = PaintingStyle.fill;

    final scale = size.width / 100;
    final center = Offset(size.width / 2, size.height / 2);

    // Draw megaphone body
    final bodyPath = Path();
    bodyPath.moveTo(25 * scale, 40 * scale);
    bodyPath.lineTo(45 * scale, 40 * scale);
    bodyPath.lineTo(60 * scale, 30 * scale);
    bodyPath.lineTo(60 * scale, 70 * scale);
    bodyPath.lineTo(45 * scale, 60 * scale);
    bodyPath.lineTo(25 * scale, 60 * scale);
    bodyPath.close();

    canvas.drawPath(bodyPath, fillPaint);
    canvas.drawPath(bodyPath, paint);

    // Draw sound waves
    final wavePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    for (int i = 1; i <= 3; i++) {
      final wavePath = Path();
      final startX = 65 * scale;
      final waveWidth = 10 * scale * i;
      final waveHeight = 15 * scale * i;

      wavePath.moveTo(startX, 50 * scale);
      wavePath.quadraticBezierTo(
        startX + waveWidth / 2,
        50 * scale - waveHeight / 2,
        startX + waveWidth,
        50 * scale,
      );
      wavePath.quadraticBezierTo(
        startX + waveWidth / 2,
        50 * scale + waveHeight / 2,
        startX,
        50 * scale,
      );

      canvas.drawPath(wavePath, wavePaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Custom empty state illustration for achievements
class _EmptyAchievementsIllustration extends StatelessWidget {
  final double size;
  final Color color;

  const _EmptyAchievementsIllustration({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _EmptyAchievementsPainter(color),
    );
  }
}

class _EmptyAchievementsPainter extends CustomPainter {
  final Color color;

  _EmptyAchievementsPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    final fillPaint = Paint()
      ..color = color.withOpacity(0.1)
      ..style = PaintingStyle.fill;

    final scale = size.width / 100;
    final center = Offset(size.width / 2, size.height / 2);

    // Draw trophy cup
    final cupPath = Path();
    cupPath.moveTo(30 * scale, 35 * scale);
    cupPath.lineTo(35 * scale, 55 * scale);
    cupPath.lineTo(65 * scale, 55 * scale);
    cupPath.lineTo(70 * scale, 35 * scale);
    cupPath.quadraticBezierTo(70 * scale, 25 * scale, 50 * scale, 25 * scale);
    cupPath.quadraticBezierTo(30 * scale, 25 * scale, 30 * scale, 35 * scale);

    canvas.drawPath(cupPath, fillPaint);
    canvas.drawPath(cupPath, paint);

    // Draw trophy base
    final basePath = Path();
    basePath.moveTo(40 * scale, 55 * scale);
    basePath.lineTo(40 * scale, 70 * scale);
    basePath.lineTo(60 * scale, 70 * scale);
    basePath.lineTo(60 * scale, 55 * scale);

    canvas.drawPath(basePath, paint);

    // Draw star
    final starPath = Path();
    final starCenter = Offset(50 * scale, 42 * scale);
    final outerRadius = 8 * scale;
    final innerRadius = 4 * scale;

    for (int i = 0; i < 5; i++) {
      final outerAngle = (i * 72 - 90) * 3.14159 / 180;
      final innerAngle = ((i * 72) + 36 - 90) * 3.14159 / 180;

      if (i == 0) {
        starPath.moveTo(
          starCenter.dx + outerRadius * math.cos(outerAngle),
          starCenter.dy + outerRadius * math.sin(outerAngle),
        );
      } else {
        starPath.lineTo(
          starCenter.dx + outerRadius * math.cos(outerAngle),
          starCenter.dy + outerRadius * math.sin(outerAngle),
        );
      }
      starPath.lineTo(
        starCenter.dx + innerRadius * math.cos(innerAngle),
        starCenter.dy + innerRadius * math.sin(innerAngle),
      );
    }
    starPath.close();

    canvas.drawPath(starPath, paint..style = PaintingStyle.fill);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Custom empty state illustration for search
class _EmptySearchIllustration extends StatelessWidget {
  final double size;
  final Color color;

  const _EmptySearchIllustration({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _EmptySearchPainter(color),
    );
  }
}

class _EmptySearchPainter extends CustomPainter {
  final Color color;

  _EmptySearchPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    final scale = size.width / 100;

    // Draw magnifying glass
    final center = Offset(40 * scale, 40 * scale);
    final glassRadius = 20 * scale;

    canvas.drawCircle(center, glassRadius, paint);

    // Draw handle
    final handleStart = Offset(
      center.dx + glassRadius * 0.707,
      center.dy + glassRadius * 0.707,
    );
    final handleEnd = Offset(
      handleStart.dx + 25 * scale,
      handleStart.dy + 25 * scale,
    );

    canvas.drawLine(handleStart, handleEnd, paint);

    // Draw small "x" inside
    final xPaint = Paint()
      ..color = color
      ..strokeWidth = 2.0;

    final xSize = 8 * scale;
    canvas.drawLine(
      Offset(center.dx - xSize / 2, center.dy - xSize / 2),
      Offset(center.dx + xSize / 2, center.dy + xSize / 2),
      xPaint,
    );
    canvas.drawLine(
      Offset(center.dx + xSize / 2, center.dy - xSize / 2),
      Offset(center.dx - xSize / 2, center.dy + xSize / 2),
      xPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Success illustration
class _SuccessIllustration extends StatelessWidget {
  final double size;
  final Color color;

  const _SuccessIllustration({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _SuccessPainter(color),
    );
  }
}

class _SuccessPainter extends CustomPainter {
  final Color color;

  _SuccessPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final fillPaint = Paint()
      ..color = color.withOpacity(0.1)
      ..style = PaintingStyle.fill;

    final scale = size.width / 100;
    final center = Offset(size.width / 2, size.height / 2);

    // Draw circle
    canvas.drawCircle(center, 40 * scale, fillPaint);
    canvas.drawCircle(center, 40 * scale, paint);

    // Draw checkmark
    final checkPath = Path();
    checkPath.moveTo(35 * scale, 50 * scale);
    checkPath.lineTo(45 * scale, 60 * scale);
    checkPath.lineTo(65 * scale, 40 * scale);

    canvas.drawPath(checkPath, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Error illustration
class _ErrorIllustration extends StatelessWidget {
  final double size;
  final Color color;

  const _ErrorIllustration({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _ErrorPainter(color),
    );
  }
}

class _ErrorPainter extends CustomPainter {
  final Color color;

  _ErrorPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round;

    final fillPaint = Paint()
      ..color = color.withOpacity(0.1)
      ..style = PaintingStyle.fill;

    final scale = size.width / 100;
    final center = Offset(size.width / 2, size.height / 2);

    // Draw circle
    canvas.drawCircle(center, 40 * scale, fillPaint);
    canvas.drawCircle(center, 40 * scale, paint);

    // Draw X
    final xSize = 25 * scale;
    canvas.drawLine(
      Offset(center.dx - xSize / 2, center.dy - xSize / 2),
      Offset(center.dx + xSize / 2, center.dy + xSize / 2),
      paint,
    );
    canvas.drawLine(
      Offset(center.dx + xSize / 2, center.dy - xSize / 2),
      Offset(center.dx - xSize / 2, center.dy + xSize / 2),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Education illustration for landing
class _EducationIllustration extends StatelessWidget {
  final double size;
  final Color color;

  const _EducationIllustration({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _EducationPainter(color),
    );
  }
}

class _EducationPainter extends CustomPainter {
  final Color color;

  _EducationPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    final fillPaint = Paint()
      ..color = color.withOpacity(0.1)
      ..style = PaintingStyle.fill;

    final scale = size.width / 100;

    // Draw book
    final bookPath = Path();
    bookPath.moveTo(25 * scale, 35 * scale);
    bookPath.lineTo(25 * scale, 65 * scale);
    bookPath.quadraticBezierTo(50 * scale, 70 * scale, 75 * scale, 65 * scale);
    bookPath.lineTo(75 * scale, 35 * scale);
    bookPath.quadraticBezierTo(50 * scale, 30 * scale, 25 * scale, 35 * scale);

    canvas.drawPath(bookPath, fillPaint);
    canvas.drawPath(bookPath, paint);

    // Draw book spine
    canvas.drawLine(
      Offset(50 * scale, 32 * scale),
      Offset(50 * scale, 68 * scale),
      paint,
    );

    // Draw graduation cap
    final capPath = Path();
    capPath.moveTo(30 * scale, 25 * scale);
    capPath.lineTo(70 * scale, 25 * scale);
    capPath.lineTo(70 * scale, 20 * scale);
    capPath.lineTo(30 * scale, 20 * scale);
    capPath.close();

    canvas.drawPath(capPath, fillPaint);
    canvas.drawPath(capPath, paint);

    // Draw tassel
    canvas.drawLine(
      Offset(70 * scale, 20 * scale),
      Offset(75 * scale, 30 * scale),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Community illustration for landing
class _CommunityIllustration extends StatelessWidget {
  final double size;
  final Color color;

  const _CommunityIllustration({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _CommunityPainter(color),
    );
  }
}

class _CommunityPainter extends CustomPainter {
  final Color color;

  _CommunityPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    final fillPaint = Paint()
      ..color = color.withOpacity(0.1)
      ..style = PaintingStyle.fill;

    final scale = size.width / 100;

    // Draw three people figures
    final centers = [
      Offset(30 * scale, 50 * scale),
      Offset(50 * scale, 40 * scale),
      Offset(70 * scale, 50 * scale),
    ];

    for (final center in centers) {
      // Head
      canvas.drawCircle(center, 10 * scale, fillPaint);
      canvas.drawCircle(center, 10 * scale, paint);

      // Body
      final bodyPath = Path();
      bodyPath.moveTo(center.dx - 12 * scale, center.dy + 12 * scale);
      bodyPath.quadraticBezierTo(
        center.dx,
        center.dy + 35 * scale,
        center.dx + 12 * scale,
        center.dy + 12 * scale,
      );

      canvas.drawPath(bodyPath, paint);
    }

    // Draw connection lines
    final linePaint = Paint()
      ..color = color
      ..strokeWidth = 1.5;

    canvas.drawLine(centers[0], centers[1], linePaint);
    canvas.drawLine(centers[1], centers[2], linePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Growth illustration for landing
class _GrowthIllustration extends StatelessWidget {
  final double size;
  final Color color;

  const _GrowthIllustration({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _GrowthPainter(color),
    );
  }
}

class _GrowthPainter extends CustomPainter {
  final Color color;

  _GrowthPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    final fillPaint = Paint()
      ..color = color.withOpacity(0.1)
      ..style = PaintingStyle.fill;

    final scale = size.width / 100;

    // Draw growing bars
    final bars = [20, 35, 50, 65, 80];
    final barWidth = 12 * scale;
    final spacing = 8 * scale;
    final startX = 20 * scale;

    for (int i = 0; i < bars.length; i++) {
      final barHeight = bars[i] * scale;
      final x = startX + i * (barWidth + spacing);
      final y = 80 * scale - barHeight;

      final barPath = Path();
      barPath.moveTo(x, 80 * scale);
      barPath.lineTo(x, y);
      barPath.lineTo(x + barWidth, y);
      barPath.lineTo(x + barWidth, 80 * scale);
      barPath.close();

      canvas.drawPath(barPath, fillPaint);
      canvas.drawPath(barPath, paint);
    }

    // Draw arrow pointing up
    final arrowPath = Path();
    arrowPath.moveTo(85 * scale, 30 * scale);
    arrowPath.lineTo(90 * scale, 20 * scale);
    arrowPath.lineTo(95 * scale, 30 * scale);

    canvas.drawPath(arrowPath, paint);
    canvas.drawLine(
      Offset(90 * scale, 20 * scale),
      Offset(90 * scale, 10 * scale),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}