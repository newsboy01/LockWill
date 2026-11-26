import 'dart:math' as math;
import 'package:flutter/material.dart';

enum OwlMood { idle, happy, encourage }

/// Nhân vật Cú mèo vẽ khối phong cách hoạt hình 3D (đổ bóng khối, vỗ cánh, chớp mắt, phụ kiện thưởng sao).
class AnimatedOwlMascot extends StatefulWidget {
  const AnimatedOwlMascot({
    super.key,
    this.mood = OwlMood.idle,
    this.size = 120,
    this.accessory = 'grad_cap',
  });

  final OwlMood mood;
  final double size;
  final String accessory; // none | grad_cap | glasses | crown

  @override
  State<AnimatedOwlMascot> createState() => _AnimatedOwlMascotState();
}

class _AnimatedOwlMascotState extends State<AnimatedOwlMascot>
    with TickerProviderStateMixin {
  late final AnimationController _loopController;
  late final AnimationController _blinkController;

  @override
  void initState() {
    super.initState();
    _loopController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    _blinkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    )..repeat();
  }

  @override
  void dispose() {
    _loopController.dispose();
    _blinkController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_loopController, _blinkController]),
      builder: (context, _) {
        final t = _loopController.value;
        final blinkT = _blinkController.value;
        // Chớp mắt tự nhiên ở cuối mỗi chu kỳ 3.2 giây.
        final isBlinking = blinkT > 0.92 && blinkT < 0.98;

        double dy = math.sin(t * math.pi) * 5;
        double tilt = 0;
        double wingAngle = math.sin(t * math.pi) * 0.14;
        double shadowScale = 1.0 - math.sin(t * math.pi) * 0.08;

        if (widget.mood == OwlMood.happy) {
          dy = -math.sin(t * math.pi).abs() * 14;
          wingAngle = 0.45 + math.sin(t * math.pi * 4) * 0.35;
          shadowScale = 1.0 - math.sin(t * math.pi).abs() * 0.22;
        } else if (widget.mood == OwlMood.encourage) {
          tilt = math.sin(t * math.pi * 2) * 0.1;
          wingAngle = 0.22;
        }

        return SizedBox(
          width: widget.size,
          height: widget.size * 1.12,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Đổ bóng 3D dưới chân
              Positioned(
                bottom: 2,
                child: Transform.scale(
                  scale: shadowScale,
                  child: Container(
                    width: widget.size * 0.62,
                    height: widget.size * 0.14,
                    decoration: BoxDecoration(
                      color: Colors.brown.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(100),
                    ),
                  ),
                ),
              ),
              // Thân Cú mèo 3D chuyển động
              Transform.translate(
                offset: Offset(0, dy - 4),
                child: Transform.rotate(
                  angle: tilt,
                  child: CustomPaint(
                    size: Size(widget.size, widget.size),
                    painter: _Owl3DPainter(
                      mood: widget.mood,
                      wingAngle: wingAngle,
                      isBlinking: isBlinking,
                      sparklePhase: t,
                      accessory: widget.accessory,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _Owl3DPainter extends CustomPainter {
  _Owl3DPainter({
    required this.mood,
    required this.wingAngle,
    required this.isBlinking,
    required this.sparklePhase,
    required this.accessory,
  });

  final OwlMood mood;
  final double wingAngle;
  final bool isBlinking;
  final double sparklePhase;
  final String accessory;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final cx = w / 2;
    final cy = h * 0.54;

    // 1. Hai cánh vỗ 3D
    _drawWing(canvas, Offset(w * 0.18, h * 0.56), -wingAngle, w * 0.19, h * 0.30, true);
    _drawWing(canvas, Offset(w * 0.82, h * 0.56), wingAngle, w * 0.19, h * 0.30, false);

    // 2. Hai chỏm tai
    final earPaint = Paint()..color = const Color(0xFFD97724);
    final leftEar = Path()
      ..moveTo(w * 0.24, h * 0.30)
      ..lineTo(w * 0.18, h * 0.12)
      ..lineTo(w * 0.36, h * 0.22)
      ..close();
    final rightEar = Path()
      ..moveTo(w * 0.76, h * 0.30)
      ..lineTo(w * 0.82, h * 0.12)
      ..lineTo(w * 0.64, h * 0.22)
      ..close();
    canvas.drawPath(leftEar, earPaint);
    canvas.drawPath(rightEar, earPaint);

    // 3. Thân chính hình cầu 3D (RadialGradient tạo khối)
    final bodyRect = Rect.fromCenter(center: Offset(cx, cy), width: w * 0.72, height: h * 0.74);
    final bodyPaint = Paint()
      ..shader = const RadialGradient(
        center: Alignment(-0.35, -0.45),
        radius: 0.9,
        colors: [
          Color(0xFFFFB86B),
          Color(0xFFE6832E),
          Color(0xFFB85A14),
        ],
      ).createShader(bodyRect);
    canvas.drawOval(bodyRect, bodyPaint);

    // 4. Bụng kem sáng bóng
    final bellyRect = Rect.fromCenter(center: Offset(cx, h * 0.69), width: w * 0.46, height: h * 0.36);
    final bellyPaint = Paint()
      ..shader = const RadialGradient(
        center: Alignment(-0.2, -0.3),
        radius: 0.9,
        colors: [Color(0xFFFFF8E8), Color(0xFFFDE3B4)],
      ).createShader(bellyRect);
    canvas.drawOval(bellyRect, bellyPaint);

    // 5. Đôi mắt lớn sáng long lanh
    _drawEye(canvas, Offset(w * 0.37, h * 0.43), w * 0.13);
    _drawEye(canvas, Offset(w * 0.63, h * 0.43), w * 0.13);

    // 6. Mỏ cam 3D
    final beakPath = Path()
      ..moveTo(cx, h * 0.48)
      ..lineTo(cx - w * 0.065, h * 0.54)
      ..quadraticBezierTo(cx, h * 0.60, cx + w * 0.065, h * 0.54)
      ..close();
    final beakPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFFFFD166), Color(0xFFF48C06)],
      ).createShader(beakPath.getBounds());
    canvas.drawPath(beakPath, beakPaint);

    // 7. Má hồng dễ thương
    final blushPaint = Paint()..color = const Color(0xFFFF758F).withValues(alpha: 0.35);
    canvas.drawOval(Rect.fromCenter(center: Offset(w * 0.27, h * 0.53), width: w * 0.11, height: h * 0.06), blushPaint);
    canvas.drawOval(Rect.fromCenter(center: Offset(w * 0.73, h * 0.53), width: w * 0.11, height: h * 0.06), blushPaint);

    // 8. Đôi chân nhỏ
    final footPaint = Paint()..color = const Color(0xFFF48C06);
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(w * 0.41, h * 0.90), width: w * 0.12, height: h * 0.07), const Radius.circular(6)),
      footPaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(w * 0.59, h * 0.90), width: w * 0.12, height: h * 0.07), const Radius.circular(6)),
      footPaint,
    );

    // 9. Phụ kiện mở khóa bằng sao (Mũ cử nhân / Kính thông minh / Vương miện)
    if (accessory == 'grad_cap') {
      final capPaint = Paint()..color = const Color(0xFF1D4ED8);
      final diamond = Path()
        ..moveTo(cx, h * 0.05)
        ..lineTo(cx + w * 0.25, h * 0.16)
        ..lineTo(cx, h * 0.25)
        ..lineTo(cx - w * 0.25, h * 0.16)
        ..close();
      canvas.drawPath(diamond, capPaint);
      canvas.drawLine(
        Offset(cx + w * 0.22, h * 0.16),
        Offset(cx + w * 0.26, h * 0.28),
        Paint()
          ..color = const Color(0xFFFFD166)
          ..strokeWidth = w * 0.025
          ..strokeCap = StrokeCap.round,
      );
    } else if (accessory == 'crown') {
      final crown = Path()
        ..moveTo(cx - w * 0.18, h * 0.22)
        ..lineTo(cx - w * 0.15, h * 0.09)
        ..lineTo(cx - w * 0.06, h * 0.16)
        ..lineTo(cx, h * 0.06)
        ..lineTo(cx + w * 0.06, h * 0.16)
        ..lineTo(cx + w * 0.15, h * 0.09)
        ..lineTo(cx + w * 0.18, h * 0.22)
        ..close();
      canvas.drawPath(crown, Paint()..color = const Color(0xFFFFCA3A));
    } else if (accessory == 'glasses') {
      final frame = Paint()
        ..color = const Color(0xFF1E293B)
        ..style = PaintingStyle.stroke
        ..strokeWidth = w * 0.032;
      canvas.drawCircle(Offset(w * 0.37, h * 0.43), w * 0.14, frame);
      canvas.drawCircle(Offset(w * 0.63, h * 0.43), w * 0.14, frame);
      canvas.drawLine(
        Offset(w * 0.51, h * 0.43),
        Offset(w * 0.49, h * 0.43),
        frame,
      );
    }

    // 10. Hiệu ứng sao lấp lánh khi vui mừng
    if (mood == OwlMood.happy) {
      final starPaint = Paint()..color = const Color(0xFFFFD166);
      final r = w * 0.055 * (0.8 + 0.4 * math.sin(sparklePhase * math.pi));
      canvas.drawCircle(Offset(w * 0.12, h * 0.18), r, starPaint);
      canvas.drawCircle(Offset(w * 0.88, h * 0.16), r * 1.15, starPaint);
      canvas.drawCircle(Offset(w * 0.50, h * 0.06), r * 0.9, Paint()..color = const Color(0xFF2EC4B6));
    }
  }

  void _drawWing(Canvas canvas, Offset pivot, double angle, double rw, double rh, bool isLeft) {
    canvas.save();
    canvas.translate(pivot.dx, pivot.dy);
    canvas.rotate(angle);
    final rect = Rect.fromCenter(
      center: Offset(isLeft ? -rw * 0.25 : rw * 0.25, rh * 0.1),
      width: rw,
      height: rh,
    );
    final paint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFFD97724), Color(0xFF9E470C)],
      ).createShader(rect);
    canvas.drawOval(rect, paint);
    canvas.restore();
  }

  void _drawEye(Canvas canvas, Offset center, double radius) {
    // Vòng lông trắng quanh mắt
    canvas.drawCircle(center, radius * 1.18, Paint()..color = const Color(0xFFFFF8E8));
    if (isBlinking) {
      final linePaint = Paint()
        ..color = const Color(0xFF3E2723)
        ..strokeWidth = radius * 0.25
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(
        Offset(center.dx - radius * 0.65, center.dy),
        Offset(center.dx + radius * 0.65, center.dy),
        linePaint,
      );
      return;
    }

    if (mood == OwlMood.happy) {
      // Mắt cười cong vui vẻ (^ ^)
      final smileEye = Paint()
        ..color = const Color(0xFF2B2D42)
        ..style = PaintingStyle.stroke
        ..strokeWidth = radius * 0.26
        ..strokeCap = StrokeCap.round;
      final arcRect = Rect.fromCircle(center: Offset(center.dx, center.dy + radius * 0.15), radius: radius * 0.65);
      canvas.drawArc(arcRect, math.pi, math.pi, false, smileEye);
      return;
    }

    // Tròng mắt đen bóng 3D + chấm phản sáng
    canvas.drawCircle(center, radius * 0.72, Paint()..color = const Color(0xFF1F2937));
    canvas.drawCircle(
      Offset(center.dx - radius * 0.22, center.dy - radius * 0.24),
      radius * 0.26,
      Paint()..color = Colors.white,
    );
    canvas.drawCircle(
      Offset(center.dx + radius * 0.22, center.dy + radius * 0.18),
      radius * 0.11,
      Paint()..color = Colors.white.withValues(alpha: 0.8),
    );
  }

  @override
  bool shouldRepaint(covariant _Owl3DPainter oldDelegate) =>
      oldDelegate.mood != mood ||
      oldDelegate.wingAngle != wingAngle ||
      oldDelegate.isBlinking != isBlinking ||
      oldDelegate.sparklePhase != sparklePhase;
}
