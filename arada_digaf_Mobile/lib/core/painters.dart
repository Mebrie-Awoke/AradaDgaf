import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'theme.dart';

/// 1. Headset on Screen Logo
class HeadsetScreenLogo extends StatelessWidget {
  final double size;
  final Color color;

  const HeadsetScreenLogo({
    super.key,
    this.size = 80,
    this.color = AppColors.primaryGreen,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: HeadsetScreenLogoPainter(color: color),
    );
  }
}

class HeadsetScreenLogoPainter extends CustomPainter {
  final Color color;

  HeadsetScreenLogoPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Outer circle container
    final circlePaint = Paint()
      ..color = AppColors.mintSurface
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(w / 2, h / 2), w * 0.48, circlePaint);

    final borderPaint = Paint()
      ..color = color.withAlpha(50)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawCircle(Offset(w / 2, h / 2), w * 0.48, borderPaint);

    final primaryPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final strokePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // Monitor Screen
    final screenLeft = w * 0.30;
    final screenTop = h * 0.32;
    final screenW = w * 0.40;
    final screenH = h * 0.30;
    final screenRRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(screenLeft, screenTop, screenW, screenH),
      const Radius.circular(5),
    );
    canvas.drawRRect(screenRRect, primaryPaint);

    // Inner monitor glass
    final innerPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(screenLeft + 3, screenTop + 3, screenW - 6, screenH - 6),
        const Radius.circular(3),
      ),
      innerPaint,
    );

    // Stand & base
    final standPath = Path()
      ..moveTo(w * 0.45, screenTop + screenH)
      ..lineTo(w * 0.55, screenTop + screenH)
      ..lineTo(w * 0.53, screenTop + screenH + h * 0.08)
      ..lineTo(w * 0.47, screenTop + screenH + h * 0.08)
      ..close();
    canvas.drawPath(standPath, primaryPaint);

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(w * 0.5, screenTop + screenH + h * 0.09),
          width: w * 0.22,
          height: h * 0.035,
        ),
        const Radius.circular(2),
      ),
      primaryPaint,
    );

    // Headset arch over monitor
    strokePaint.strokeWidth = w * 0.045;
    final headsetRect = Rect.fromCenter(
      center: Offset(w * 0.5, h * 0.44),
      width: w * 0.56,
      height: h * 0.46,
    );
    canvas.drawArc(headsetRect, math.pi * 1.05, math.pi * 0.9, false, strokePaint);

    // Left earcup
    final earcupPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(w * 0.23, h * 0.46), width: w * 0.07, height: h * 0.16),
        const Radius.circular(3),
      ),
      earcupPaint,
    );

    // Right earcup
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(w * 0.77, h * 0.46), width: w * 0.07, height: h * 0.16),
        const Radius.circular(3),
      ),
      earcupPaint,
    );

    // Microphone arm
    final micPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;
    final micPath = Path()
      ..moveTo(w * 0.75, h * 0.52)
      ..quadraticBezierTo(w * 0.70, h * 0.65, w * 0.56, h * 0.65);
    canvas.drawPath(micPath, micPaint);

    // Microphone tip
    canvas.drawCircle(Offset(w * 0.55, h * 0.65), 3, primaryPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// 2. Addis Ababa Skyline & Monument Illustration
class AddisSkyline extends StatelessWidget {
  final double height;
  final bool showBottomWave;

  const AddisSkyline({
    super.key,
    this.height = 140,
    this.showBottomWave = true,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: double.infinity,
      child: CustomPaint(
        painter: AddisSkylinePainter(showBottomWave: showBottomWave),
      ),
    );
  }
}

class AddisSkylinePainter extends CustomPainter {
  final bool showBottomWave;

  AddisSkylinePainter({this.showBottomWave = true});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Distant soft mountain silhouette
    final mountainPaint = Paint()
      ..color = const Color(0xFFD4E7DF)
      ..style = PaintingStyle.fill;
    final mountainPath = Path()
      ..moveTo(0, h * 0.7)
      ..quadraticBezierTo(w * 0.25, h * 0.45, w * 0.5, h * 0.65)
      ..quadraticBezierTo(w * 0.75, h * 0.48, w, h * 0.68)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();
    canvas.drawPath(mountainPath, mountainPaint);

    // City Buildings (left side)
    final bldgPaint1 = Paint()..color = const Color(0xFF7A9F93);
    final bldgPaint2 = Paint()..color = const Color(0xFF9ABBB1);
    final windowPaint = Paint()..color = Colors.white.withAlpha(180);

    // Building 1 (far left)
    canvas.drawRect(Rect.fromLTWH(w * 0.05, h * 0.50, w * 0.12, h * 0.35), bldgPaint1);
    for (double by = h * 0.54; by < h * 0.75; by += 8) {
      for (double bx = w * 0.07; bx < w * 0.15; bx += 8) {
        canvas.drawRect(Rect.fromLTWH(bx, by, 4, 4), windowPaint);
      }
    }

    // Building 2 (mid left)
    canvas.drawRect(Rect.fromLTWH(w * 0.18, h * 0.58, w * 0.10, h * 0.28), bldgPaint2);
    for (double by = h * 0.62; by < h * 0.78; by += 7) {
      canvas.drawRect(Rect.fromLTWH(w * 0.21, by, 10, 3), windowPaint);
    }

    // Building 3 (right side)
    canvas.drawRect(Rect.fromLTWH(w * 0.78, h * 0.52, w * 0.09, h * 0.35), bldgPaint1);
    for (double by = h * 0.56; by < h * 0.78; by += 8) {
      canvas.drawRect(Rect.fromLTWH(w * 0.81, by, 8, 4), windowPaint);
    }

    // Building 4 (far right)
    canvas.drawRect(Rect.fromLTWH(w * 0.88, h * 0.46, w * 0.08, h * 0.40), bldgPaint2);
    for (double by = h * 0.50; by < h * 0.80; by += 8) {
      canvas.drawRect(Rect.fromLTWH(w * 0.90, by, 7, 4), windowPaint);
    }

    // The iconic Addis Ababa Yekatit 12 / Arat Kilo / Tiglachin Monument Tower
    final monumentX = w * 0.62;
    final monumentPaint = Paint()..color = const Color(0xFFE6EFEA);
    final monumentShadow = Paint()..color = const Color(0xFF90ACA2);
    final monumentDetail = Paint()
      ..color = AppColors.darkGreen
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    // Stepped pedestal
    canvas.drawRect(Rect.fromCenter(center: Offset(monumentX, h * 0.75), width: w * 0.18, height: h * 0.05), monumentShadow);
    canvas.drawRect(Rect.fromCenter(center: Offset(monumentX, h * 0.72), width: w * 0.14, height: h * 0.04), monumentPaint);
    canvas.drawRect(Rect.fromCenter(center: Offset(monumentX, h * 0.69), width: w * 0.10, height: h * 0.03), monumentShadow);

    // Tall Monument Spire
    final spirePath = Path()
      ..moveTo(monumentX - w * 0.025, h * 0.68)
      ..lineTo(monumentX - w * 0.012, h * 0.12)
      ..lineTo(monumentX, h * 0.06) // sharp top point
      ..lineTo(monumentX + w * 0.012, h * 0.12)
      ..lineTo(monumentX + w * 0.025, h * 0.68)
      ..close();
    canvas.drawPath(spirePath, monumentPaint);

    // Shaded side of spire
    final spireShade = Path()
      ..moveTo(monumentX, h * 0.06)
      ..lineTo(monumentX + w * 0.012, h * 0.12)
      ..lineTo(monumentX + w * 0.025, h * 0.68)
      ..lineTo(monumentX, h * 0.68)
      ..close();
    canvas.drawPath(spireShade, monumentShadow);
    canvas.drawPath(spirePath, monumentDetail);

    // Green Trees / Parks
    final treePaint1 = Paint()..color = const Color(0xFF2C7D59);
    final treePaint2 = Paint()..color = const Color(0xFF1E6043);

    void drawTree(double cx, double cy, double r) {
      canvas.drawCircle(Offset(cx, cy), r, treePaint1);
      canvas.drawCircle(Offset(cx + r * 0.25, cy + r * 0.1), r * 0.75, treePaint2);
    }

    drawTree(w * 0.32, h * 0.73, 14);
    drawTree(w * 0.38, h * 0.74, 18);
    drawTree(w * 0.46, h * 0.75, 15);
    drawTree(w * 0.72, h * 0.74, 16);
    drawTree(w * 0.52, h * 0.75, 12);

    // Rolling green foreground & wavy layers (as in the showcase image)
    if (showBottomWave) {
      final wavePaint1 = Paint()
        ..shader = const LinearGradient(
          colors: [Color(0xFF0F7A60), Color(0xFF0B6B54)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ).createShader(Rect.fromLTWH(0, h * 0.72, w, h * 0.28));

      final wave1 = Path()
        ..moveTo(0, h * 0.76)
        ..quadraticBezierTo(w * 0.3, h * 0.70, w * 0.65, h * 0.78)
        ..quadraticBezierTo(w * 0.85, h * 0.82, w, h * 0.74)
        ..lineTo(w, h)
        ..lineTo(0, h)
        ..close();
      canvas.drawPath(wave1, wavePaint1);

      final wavePaint2 = Paint()
        ..color = AppColors.darkGreen
        ..style = PaintingStyle.fill;

      final wave2 = Path()
        ..moveTo(0, h * 0.85)
        ..quadraticBezierTo(w * 0.4, h * 0.80, w * 0.75, h * 0.87)
        ..lineTo(w, h * 0.84)
        ..lineTo(w, h)
        ..lineTo(0, h)
        ..close();
      canvas.drawPath(wave2, wavePaint2);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// 3. Simple Ethiopian Flag (Drawn in code)
class EthiopianFlag extends StatelessWidget {
  final double width;
  final double height;
  final bool circular;

  const EthiopianFlag({
    super.key,
    this.width = 36,
    this.height = 24,
    this.circular = true,
  });

  @override
  Widget build(BuildContext context) {
    if (circular) {
      return ClipOval(
        child: SizedBox(
          width: width,
          height: width,
          child: CustomPaint(
            painter: EthiopianFlagPainter(),
          ),
        ),
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: SizedBox(
        width: width,
        height: height,
        child: CustomPaint(
          painter: EthiopianFlagPainter(),
        ),
      ),
    );
  }
}

class EthiopianFlagPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final stripeH = h / 3;

    // Green stripe
    canvas.drawRect(
      Rect.fromLTWH(0, 0, w, stripeH),
      Paint()..color = const Color(0xFF078930),
    );

    // Yellow stripe
    canvas.drawRect(
      Rect.fromLTWH(0, stripeH, w, stripeH),
      Paint()..color = const Color(0xFFFCDD09),
    );

    // Red stripe
    canvas.drawRect(
      Rect.fromLTWH(0, stripeH * 2, w, stripeH),
      Paint()..color = const Color(0xFFDA121A),
    );

    // Blue central emblem disk
    final center = Offset(w / 2, h / 2);
    final radius = h * 0.28;
    canvas.drawCircle(
      center,
      radius,
      Paint()..color = const Color(0xFF0F47AF),
    );

    // Central 5-pointed star with gold rays
    final starPaint = Paint()
      ..color = const Color(0xFFFCDD09)
      ..style = PaintingStyle.fill;
    final rayPaint = Paint()
      ..color = const Color(0xFFFCDD09)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;

    final starPath = Path();
    for (int i = 0; i < 5; i++) {
      final angle = -math.pi / 2 + (i * 4 * math.pi / 5);
      final x = center.dx + radius * 0.65 * math.cos(angle);
      final y = center.dy + radius * 0.65 * math.sin(angle);
      if (i == 0) {
        starPath.moveTo(x, y);
      } else {
        starPath.lineTo(x, y);
      }
      // Star rays
      final rayAngle = -math.pi / 2 + (i * 2 * math.pi / 5) + (math.pi / 5);
      canvas.drawLine(
        center,
        Offset(
          center.dx + radius * 0.9 * math.cos(rayAngle),
          center.dy + radius * 0.9 * math.sin(rayAngle),
        ),
        rayPaint,
      );
    }
    starPath.close();
    canvas.drawPath(starPath, starPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// 4. Confetti Painter for Submission Success
class ConfettiWidget extends StatefulWidget {
  const ConfettiWidget({super.key});

  @override
  State<ConfettiWidget> createState() => _ConfettiWidgetState();
}

class _ConfettiWidgetState extends State<ConfettiWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          size: Size.infinite,
          painter: ConfettiPainter(progress: _controller.value),
        );
      },
    );
  }
}

class ConfettiPainter extends CustomPainter {
  final double progress;

  ConfettiPainter({required this.progress});

  static final List<_ConfettiParticle> _particles = List.generate(35, (index) {
    final rand = math.Random(index * 7 + 13);
    return _ConfettiParticle(
      xRatio: rand.nextDouble(),
      yOffset: rand.nextDouble(),
      speed: 0.4 + rand.nextDouble() * 0.6,
      size: 6 + rand.nextDouble() * 8,
      color: [
        const Color(0xFF0B6B54),
        const Color(0xFFF57C00),
        const Color(0xFF1976D2),
        const Color(0xFFE53935),
        const Color(0xFFFCDD09),
        const Color(0xFF7B1FA2),
      ][index % 6],
      rotationSpeed: (rand.nextDouble() - 0.5) * 8,
      isCircle: index % 3 == 0,
    );
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    for (final p in _particles) {
      final y = ((p.yOffset + progress * p.speed) % 1.0) * h;
      final x = p.xRatio * w + math.sin(progress * 6 + p.yOffset * 10) * 15;
      final rotation = progress * p.rotationSpeed * math.pi;

      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(rotation);

      final paint = Paint()
        ..color = p.color.withAlpha(220)
        ..style = PaintingStyle.fill;

      if (p.isCircle) {
        canvas.drawCircle(Offset.zero, p.size / 2, paint);
      } else {
        canvas.drawRect(
          Rect.fromCenter(center: Offset.zero, width: p.size, height: p.size * 0.6),
          paint,
        );
      }
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant ConfettiPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

class _ConfettiParticle {
  final double xRatio;
  final double yOffset;
  final double speed;
  final double size;
  final Color color;
  final double rotationSpeed;
  final bool isCircle;

  const _ConfettiParticle({
    required this.xRatio,
    required this.yOffset,
    required this.speed,
    required this.size,
    required this.color,
    required this.rotationSpeed,
    required this.isCircle,
  });
}

/// 5. Vector Avatar / Illustration (Woman with laptop at desk)
class EmployeeIllustration extends StatelessWidget {
  final double width;
  final double height;

  const EmployeeIllustration({
    super.key,
    this.width = 110,
    this.height = 100,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: CustomPaint(
        painter: EmployeeIllustrationPainter(),
      ),
    );
  }
}

class EmployeeIllustrationPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Background circle mint glow
    final bgPaint = Paint()..color = AppColors.mintSurface;
    canvas.drawCircle(Offset(w * 0.55, h * 0.45), w * 0.40, bgPaint);

    // Desk surface
    final deskPaint = Paint()
      ..color = const Color(0xFFC3D8D0)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(w * 0.1, h * 0.88), Offset(w * 0.95, h * 0.88), deskPaint);

    // Person Body / Suit (Dark green blazer)
    final blazerPaint = Paint()..color = AppColors.darkGreen;
    final bodyPath = Path()
      ..moveTo(w * 0.38, h * 0.88)
      ..lineTo(w * 0.38, h * 0.58)
      ..quadraticBezierTo(w * 0.52, h * 0.48, w * 0.68, h * 0.58)
      ..lineTo(w * 0.72, h * 0.88)
      ..close();
    canvas.drawPath(bodyPath, blazerPaint);

    // Inner blouse
    final blousePaint = Paint()..color = Colors.white;
    final blousePath = Path()
      ..moveTo(w * 0.49, h * 0.52)
      ..lineTo(w * 0.57, h * 0.52)
      ..lineTo(w * 0.53, h * 0.64)
      ..close();
    canvas.drawPath(blousePath, blousePaint);

    // Head / Face
    final skinPaint = Paint()..color = const Color(0xFF8D5524);
    canvas.drawCircle(Offset(w * 0.53, h * 0.36), w * 0.14, skinPaint);

    // Hair
    final hairPaint = Paint()..color = const Color(0xFF211510);
    final hairPath = Path()
      ..addArc(
        Rect.fromCircle(center: Offset(w * 0.53, h * 0.34), radius: w * 0.155),
        math.pi * 0.8,
        math.pi * 1.4,
      )
      ..lineTo(w * 0.68, h * 0.44)
      ..quadraticBezierTo(w * 0.53, h * 0.28, w * 0.38, h * 0.44)
      ..close();
    canvas.drawPath(hairPath, hairPaint);

    // Hair bun / ponytail
    canvas.drawCircle(Offset(w * 0.66, h * 0.28), w * 0.07, hairPaint);

    // Laptop on desk
    final laptopPaint = Paint()..color = const Color(0xFF78909C);
    // Screen open angled
    final screenPath = Path()
      ..moveTo(w * 0.18, h * 0.87)
      ..lineTo(w * 0.22, h * 0.68)
      ..lineTo(w * 0.40, h * 0.68)
      ..lineTo(w * 0.36, h * 0.87)
      ..close();
    canvas.drawPath(screenPath, laptopPaint);

    // Glowing screen face
    final glowPaint = Paint()..color = const Color(0xFFE0F7FA);
    final glowPath = Path()
      ..moveTo(w * 0.20, h * 0.85)
      ..lineTo(w * 0.23, h * 0.70)
      ..lineTo(w * 0.38, h * 0.70)
      ..lineTo(w * 0.35, h * 0.85)
      ..close();
    canvas.drawPath(glowPath, glowPaint);

    // Laptop base
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.16, h * 0.86, w * 0.24, h * 0.03),
        const Radius.circular(1.5),
      ),
      Paint()..color = const Color(0xFF546E7A),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

