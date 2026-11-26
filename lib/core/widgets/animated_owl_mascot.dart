import 'dart:math' as math;
import 'package:flutter/material.dart';

enum OwlMood {
  idle,
  happy,
  encourage,
  love,
  giggle,
  sideEye,
  dizzy,
  angry,
  crying,
  eating,
  sleeping,
}

/// Nhân vật Cú mèo 3D đa cảm xúc (11 trạng thái), 4 màu lông, 8 ngoại trang anh hùng
/// (CSGT, CSCĐ, CSHS, Quân đội, Y tế, Cứu hỏa, Phi hành gia, Siêu anh hùng) và phụ kiện.
class AnimatedOwlMascot extends StatefulWidget {
  const AnimatedOwlMascot({
    super.key,
    this.mood = OwlMood.idle,
    this.size = 130,
    this.skin = 'orange',
    this.costume = 'none',
    this.accessory = 'grad_cap',
    this.showSoapBubbles = false,
  });

  final OwlMood mood;
  final double size;
  final String skin;
  final String costume;
  final String accessory;
  final bool showSoapBubbles;

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
      duration: const Duration(milliseconds: 1300),
    )..repeat(reverse: true);

    _blinkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3400),
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
        final isBlinking = blinkT > 0.92 && blinkT < 0.98;

        double dy = math.sin(t * math.pi) * 5;
        double dx = 0;
        double tilt = 0;
        double scale = 1.0;
        double wingAngle = math.sin(t * math.pi) * 0.14;
        double shadowScale = 1.0 - math.sin(t * math.pi) * 0.08;

        switch (widget.mood) {
          case OwlMood.happy:
            dy = -math.sin(t * math.pi).abs() * 14;
            wingAngle = 0.45 + math.sin(t * math.pi * 4) * 0.35;
            shadowScale = 1.0 - math.sin(t * math.pi).abs() * 0.22;
            break;
          case OwlMood.love:
            dy = math.sin(t * math.pi) * 3;
            scale = 1.0 + math.sin(t * math.pi) * 0.05;
            wingAngle = 0.25;
            break;
          case OwlMood.giggle:
            dx = math.sin(t * math.pi * 6) * 5;
            dy = -math.sin(t * math.pi * 3).abs() * 6;
            wingAngle = 0.55;
            break;
          case OwlMood.dizzy:
            tilt = math.sin(t * math.pi * 4) * 0.18;
            wingAngle = 0.35;
            break;
          case OwlMood.angry:
            dx = math.sin(t * math.pi * 8) * 3;
            scale = 1.03;
            wingAngle = -0.15;
            break;
          case OwlMood.crying:
            dy = 4 + math.sin(t * math.pi * 2) * 3;
            tilt = -0.06;
            wingAngle = -0.1;
            break;
          case OwlMood.eating:
            scale = 1.0 + math.sin(t * math.pi * 4).abs() * 0.06;
            wingAngle = 0.3;
            break;
          case OwlMood.sleeping:
            dy = 6 + math.sin(t * math.pi) * 2;
            wingAngle = 0.04;
            break;
          case OwlMood.encourage:
            tilt = math.sin(t * math.pi * 2) * 0.1;
            wingAngle = 0.22;
            break;
          case OwlMood.sideEye:
          case OwlMood.idle:
            break;
        }

        return SizedBox(
          width: widget.size,
          height: widget.size * 1.14,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Positioned(
                bottom: 2,
                child: Transform.scale(
                  scale: shadowScale,
                  child: Container(
                    width: widget.size * 0.62,
                    height: widget.size * 0.13,
                    decoration: BoxDecoration(
                      color: Colors.brown.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(100),
                    ),
                  ),
                ),
              ),
              Transform.translate(
                offset: Offset(dx, dy - 4),
                child: Transform.rotate(
                  angle: tilt,
                  child: Transform.scale(
                    scale: scale,
                    child: CustomPaint(
                      size: Size(widget.size, widget.size),
                      painter: _Owl3DPainter(
                        mood: widget.mood,
                        wingAngle: wingAngle,
                        isBlinking: isBlinking,
                        phase: t,
                        skin: widget.skin,
                        costume: widget.costume,
                        accessory: widget.accessory,
                        showSoapBubbles: widget.showSoapBubbles,
                      ),
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
    required this.phase,
    required this.skin,
    required this.costume,
    required this.accessory,
    required this.showSoapBubbles,
  });

  final OwlMood mood;
  final double wingAngle;
  final bool isBlinking;
  final double phase;
  final String skin;
  final String costume;
  final String accessory;
  final bool showSoapBubbles;

  List<Color> _skinColors() {
    switch (skin) {
      case 'snow':
        return const [Color(0xFFFFFFFF), Color(0xFFE2E8F0), Color(0xFF94A3B8)];
      case 'galaxy':
        return const [Color(0xFFA78BFA), Color(0xFF6D28D9), Color(0xFF3B0764)];
      case 'gold':
        return const [Color(0xFFFFF3B0), Color(0xFFF59E0B), Color(0xFFB45309)];
      default:
        return const [Color(0xFFFFB86B), Color(0xFFE6832E), Color(0xFFB85A14)];
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final cx = w / 2;
    final cy = h * 0.54;
    final skinCols = _skinColors();

    // 0. Áo choàng Siêu anh hùng phía sau thân
    if (costume == 'superhero') {
      final cape = Path()
        ..moveTo(w * 0.22, h * 0.44)
        ..lineTo(w * 0.04, h * 0.88)
        ..quadraticBezierTo(cx, h * 0.98, w * 0.96, h * 0.88)
        ..lineTo(w * 0.78, h * 0.44)
        ..close();
      canvas.drawPath(cape, Paint()..color = const Color(0xFFDC2626));
    }

    // 1. Hai cánh 3D
    _drawWing(canvas, Offset(w * 0.18, h * 0.56), -wingAngle, w * 0.19, h * 0.30, true, skinCols);
    _drawWing(canvas, Offset(w * 0.82, h * 0.56), wingAngle, w * 0.19, h * 0.30, false, skinCols);

    // 2. Hai chỏm tai
    final earPaint = Paint()..color = skinCols[1];
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

    // 3. Thân 3D
    final bodyRect = Rect.fromCenter(center: Offset(cx, cy), width: w * 0.72, height: h * 0.74);
    final bodyPaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.35, -0.45),
        radius: 0.9,
        colors: skinCols,
      ).createShader(bodyRect);
    canvas.drawOval(bodyRect, bodyPaint);

    // 4. Bụng sáng bóng
    final bellyRect = Rect.fromCenter(center: Offset(cx, h * 0.69), width: w * 0.46, height: h * 0.36);
    final bellyPaint = Paint()
      ..shader = const RadialGradient(
        center: Alignment(-0.2, -0.3),
        radius: 0.9,
        colors: [Color(0xFFFFF8E8), Color(0xFFFDE3B4)],
      ).createShader(bellyRect);
    canvas.drawOval(bellyRect, bellyPaint);

    // 5. Đồng phục Ngoại trang trên thân
    _drawCostumeBody(canvas, w, h, cx);

    // 6. Đôi mắt biểu cảm
    _drawEye(canvas, Offset(w * 0.37, h * 0.43), w * 0.13, true);
    _drawEye(canvas, Offset(w * 0.63, h * 0.43), w * 0.13, false);

    // 7. Mỏ & Miệng (há mỏ khi ăn / cười)
    _drawBeak(canvas, cx, w, h);

    // 8. Má hồng (đỏ đậm hơn khi giận hoặc được nựng)
    final blushAlpha = (mood == OwlMood.love || mood == OwlMood.angry) ? 0.55 : 0.32;
    final blushPaint = Paint()..color = const Color(0xFFFF597B).withValues(alpha: blushAlpha);
    canvas.drawOval(Rect.fromCenter(center: Offset(w * 0.27, h * 0.53), width: w * 0.11, height: h * 0.06), blushPaint);
    canvas.drawOval(Rect.fromCenter(center: Offset(w * 0.73, h * 0.53), width: w * 0.11, height: h * 0.06), blushPaint);

    // 9. Đôi chân
    final footPaint = Paint()..color = const Color(0xFFF48C06);
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(w * 0.41, h * 0.90), width: w * 0.12, height: h * 0.07), const Radius.circular(6)),
      footPaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(w * 0.59, h * 0.90), width: w * 0.12, height: h * 0.07), const Radius.circular(6)),
      footPaint,
    );

    // 10. Mũ ngoại trang hoặc phụ kiện
    _drawCostumeHead(canvas, w, h, cx);
    if (costume == 'none' || costume == 'cshs' || costume == 'superhero') {
      _drawAccessory(canvas, w, h, cx);
    }

    // 11. Hiệu ứng cảm xúc & bọt xà phòng
    _drawMoodEffects(canvas, w, h, cx);
  }

  void _drawCostumeBody(Canvas canvas, double w, double h, double cx) {
    if (costume == 'none') return;

    final coatRect = Rect.fromCenter(center: Offset(cx, h * 0.72), width: w * 0.62, height: h * 0.34);
    switch (costume) {
      case 'csgt':
        // Đồng phục vàng lúa chín + cà vạt đỏ + gậy chỉ huy
        canvas.drawRRect(RRect.fromRectAndRadius(coatRect, Radius.circular(w * 0.16)), Paint()..color = const Color(0xFFEAB308));
        final tie = Path()
          ..moveTo(cx, h * 0.58)
          ..lineTo(cx - w * 0.04, h * 0.76)
          ..lineTo(cx, h * 0.82)
          ..lineTo(cx + w * 0.04, h * 0.76)
          ..close();
        canvas.drawPath(tie, Paint()..color = const Color(0xFFDC2626));
        // Gậy chỉ huy giao thông sọc trắng đỏ bên cánh phải
        canvas.drawLine(
          Offset(w * 0.84, h * 0.64),
          Offset(w * 0.95, h * 0.34),
          Paint()..color = Colors.white..strokeWidth = w * 0.045..strokeCap = StrokeCap.round,
        );
        canvas.drawLine(
          Offset(w * 0.89, h * 0.50),
          Offset(w * 0.93, h * 0.40),
          Paint()..color = const Color(0xFFEF4444)..strokeWidth = w * 0.045,
        );
        break;
      case 'cscd':
        // Đồng phục xanh đen chiến thuật + giáp ngực + sao vàng
        canvas.drawRRect(RRect.fromRectAndRadius(coatRect, Radius.circular(w * 0.16)), Paint()..color = const Color(0xFF1E293B));
        canvas.drawRRect(
          RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(cx, h * 0.70), width: w * 0.36, height: h * 0.22), Radius.circular(w * 0.06)),
          Paint()..color = const Color(0xFF0F172A),
        );
        canvas.drawCircle(Offset(cx, h * 0.70), w * 0.06, Paint()..color = const Color(0xFFFACC15));
        break;
      case 'cshs':
        // Vest xanh navy lịch lãm + sơ mi trắng + cà vạt đen + phù hiệu thám tử
        canvas.drawRRect(RRect.fromRectAndRadius(coatRect, Radius.circular(w * 0.16)), Paint()..color = const Color(0xFF1E3A8A));
        final shirt = Path()
          ..moveTo(cx - w * 0.12, h * 0.56)
          ..lineTo(cx, h * 0.78)
          ..lineTo(cx + w * 0.12, h * 0.56)
          ..close();
        canvas.drawPath(shirt, Paint()..color = Colors.white);
        canvas.drawCircle(Offset(cx + w * 0.16, h * 0.68), w * 0.045, Paint()..color = const Color(0xFFFACC15));
        break;
      case 'army':
        // Quân phục xanh lá bộ đội + thắt lưng nâu + sao vàng
        canvas.drawRRect(RRect.fromRectAndRadius(coatRect, Radius.circular(w * 0.16)), Paint()..color = const Color(0xFF3F6212));
        canvas.drawRect(Rect.fromCenter(center: Offset(cx, h * 0.78), width: w * 0.58, height: h * 0.05), Paint()..color = const Color(0xFF78350F));
        canvas.drawRect(Rect.fromCenter(center: Offset(cx, h * 0.78), width: w * 0.11, height: h * 0.06), Paint()..color = const Color(0xFFFACC15));
        break;
      case 'doctor':
        // Áo blouse trắng + ống nghe y tế
        canvas.drawRRect(RRect.fromRectAndRadius(coatRect, Radius.circular(w * 0.16)), Paint()..color = Colors.white);
        canvas.drawArc(
          Rect.fromCenter(center: Offset(cx, h * 0.60), width: w * 0.34, height: h * 0.22),
          0,
          math.pi,
          false,
          Paint()..color = const Color(0xFF334155)..style = PaintingStyle.stroke..strokeWidth = w * 0.032,
        );
        canvas.drawCircle(Offset(cx, h * 0.73), w * 0.055, Paint()..color = const Color(0xFF0EA5E9));
        break;
      case 'firefighter':
        // Áo cứu hỏa đỏ-cam + sọc phản quang vàng
        canvas.drawRRect(RRect.fromRectAndRadius(coatRect, Radius.circular(w * 0.16)), Paint()..color = const Color(0xFFDC2626));
        canvas.drawRect(Rect.fromCenter(center: Offset(cx, h * 0.68), width: w * 0.58, height: h * 0.05), Paint()..color = const Color(0xFFFDE047));
        canvas.drawRect(Rect.fromCenter(center: Offset(cx, h * 0.78), width: w * 0.56, height: h * 0.05), Paint()..color = const Color(0xFFFDE047));
        break;
      case 'astronaut':
        // Bộ đồ phi hành gia trắng + bảng điều khiển ngực
        canvas.drawRRect(RRect.fromRectAndRadius(coatRect, Radius.circular(w * 0.18)), Paint()..color = const Color(0xFFF8FAFC));
        canvas.drawRRect(
          RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(cx, h * 0.70), width: w * 0.28, height: h * 0.14), const Radius.circular(6)),
          Paint()..color = const Color(0xFFCBD5E1),
        );
        canvas.drawCircle(Offset(cx - w * 0.07, h * 0.70), w * 0.028, Paint()..color = const Color(0xFFEF4444));
        canvas.drawCircle(Offset(cx, h * 0.70), w * 0.028, Paint()..color = const Color(0xFF3B82F6));
        canvas.drawCircle(Offset(cx + w * 0.07, h * 0.70), w * 0.028, Paint()..color = const Color(0xFF10B981));
        break;
      case 'superhero':
        // Huy hiệu siêu anh hùng trên ngực
        canvas.drawCircle(Offset(cx, h * 0.70), w * 0.11, Paint()..color = const Color(0xFFFACC15));
        canvas.drawCircle(Offset(cx, h * 0.70), w * 0.07, Paint()..color = const Color(0xFFDC2626));
        break;
    }
  }

  void _drawCostumeHead(Canvas canvas, double w, double h, double cx) {
    switch (costume) {
      case 'csgt':
        // Mũ kê-pi vàng sao đỏ
        canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(cx, h * 0.17), width: w * 0.48, height: h * 0.13), const Radius.circular(10)), Paint()..color = const Color(0xFFEAB308));
        canvas.drawRect(Rect.fromCenter(center: Offset(cx, h * 0.23), width: w * 0.44, height: h * 0.04), Paint()..color = const Color(0xFFDC2626));
        canvas.drawCircle(Offset(cx, h * 0.17), w * 0.045, Paint()..color = const Color(0xFFDC2626));
        break;
      case 'cscd':
        // Mũ bảo hiểm chiến thuật đen + kính chắn xanh
        canvas.drawArc(Rect.fromCenter(center: Offset(cx, h * 0.28), width: w * 0.64, height: h * 0.36), math.pi, math.pi, true, Paint()..color = const Color(0xFF0F172A));
        canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(cx, h * 0.27), width: w * 0.46, height: h * 0.09), const Radius.circular(8)), Paint()..color = const Color(0xFF38BDF8).withValues(alpha: 0.65));
        break;
      case 'cshs':
        // Kính râm thám tử ngầu
        final sunglass = Paint()..color = const Color(0xFF0F172A).withValues(alpha: 0.85);
        canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(w * 0.37, h * 0.43), width: w * 0.22, height: h * 0.12), const Radius.circular(6)), sunglass);
        canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(w * 0.63, h * 0.43), width: w * 0.22, height: h * 0.12), const Radius.circular(6)), sunglass);
        canvas.drawLine(Offset(w * 0.48, h * 0.42), Offset(w * 0.52, h * 0.42), Paint()..color = const Color(0xFF0F172A)..strokeWidth = 3);
        break;
      case 'army':
        // Mũ cối xanh bộ đội + sao vàng trên nền đỏ
        canvas.drawArc(Rect.fromCenter(center: Offset(cx, h * 0.24), width: w * 0.60, height: h * 0.30), math.pi, math.pi, true, Paint()..color = const Color(0xFF4D7C0F));
        canvas.drawRect(Rect.fromCenter(center: Offset(cx, h * 0.24), width: w * 0.64, height: h * 0.045), Paint()..color = const Color(0xFF365314));
        canvas.drawCircle(Offset(cx, h * 0.17), w * 0.055, Paint()..color = const Color(0xFFDC2626));
        canvas.drawCircle(Offset(cx, h * 0.17), w * 0.025, Paint()..color = const Color(0xFFFACC15));
        break;
      case 'doctor':
        // Mũ y tế trắng + chữ thập đỏ
        canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(cx, h * 0.17), width: w * 0.38, height: h * 0.13), const Radius.circular(8)), Paint()..color = Colors.white);
        final red = Paint()..color = const Color(0xFFEF4444);
        canvas.drawRect(Rect.fromCenter(center: Offset(cx, h * 0.17), width: w * 0.12, height: h * 0.035), red);
        canvas.drawRect(Rect.fromCenter(center: Offset(cx, h * 0.17), width: w * 0.035, height: h * 0.10), red);
        break;
      case 'firefighter':
        // Mũ cứu hỏa đỏ + huy hiệu vàng
        canvas.drawArc(Rect.fromCenter(center: Offset(cx, h * 0.25), width: w * 0.62, height: h * 0.34), math.pi, math.pi, true, Paint()..color = const Color(0xFFB91C1C));
        canvas.drawRect(Rect.fromCenter(center: Offset(cx, h * 0.25), width: w * 0.68, height: h * 0.05), Paint()..color = const Color(0xFF991B1B));
        canvas.drawCircle(Offset(cx, h * 0.16), w * 0.06, Paint()..color = const Color(0xFFFACC15));
        break;
      case 'astronaut':
        // Mũ kính cầu vũ trụ trong suốt
        canvas.drawCircle(
          Offset(cx, h * 0.43),
          w * 0.37,
          Paint()..color = const Color(0xFFBAE6FD).withValues(alpha: 0.26),
        );
        canvas.drawCircle(
          Offset(cx, h * 0.43),
          w * 0.37,
          Paint()..color = Colors.white.withValues(alpha: 0.85)..style = PaintingStyle.stroke..strokeWidth = w * 0.035,
        );
        break;
      case 'superhero':
        // Mặt nạ siêu anh hùng
        canvas.drawRRect(
          RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(cx, h * 0.43), width: w * 0.56, height: h * 0.14), const Radius.circular(14)),
          Paint()..color = const Color(0xFF2563EB).withValues(alpha: 0.35),
        );
        break;
    }
  }

  void _drawAccessory(Canvas canvas, double w, double h, double cx) {
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
        Paint()..color = const Color(0xFFFFD166)..strokeWidth = w * 0.025..strokeCap = StrokeCap.round,
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
      canvas.drawLine(Offset(w * 0.51, h * 0.43), Offset(w * 0.49, h * 0.43), frame);
    } else if (accessory == 'bowtie') {
      final bow = Paint()..color = const Color(0xFFEF4444);
      final left = Path()
        ..moveTo(cx, h * 0.60)
        ..lineTo(cx - w * 0.12, h * 0.55)
        ..lineTo(cx - w * 0.12, h * 0.65)
        ..close();
      final right = Path()
        ..moveTo(cx, h * 0.60)
        ..lineTo(cx + w * 0.12, h * 0.55)
        ..lineTo(cx + w * 0.12, h * 0.65)
        ..close();
      canvas.drawPath(left, bow);
      canvas.drawPath(right, bow);
      canvas.drawCircle(Offset(cx, h * 0.60), w * 0.035, Paint()..color = const Color(0xFFB91C1C));
    }
  }

  void _drawBeak(Canvas canvas, double cx, double w, double h) {
    final openAmount = (mood == OwlMood.eating || mood == OwlMood.giggle)
        ? h * 0.045 * (0.4 + 0.6 * math.sin(phase * math.pi * 4).abs())
        : 0.0;

    if (openAmount > 1) {
      canvas.drawOval(
        Rect.fromCenter(center: Offset(cx, h * 0.55), width: w * 0.12, height: h * 0.07 + openAmount),
        Paint()..color = const Color(0xFF991B1B),
      );
    }

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
  }

  void _drawWing(Canvas canvas, Offset pivot, double angle, double rw, double rh, bool isLeft, List<Color> skinCols) {
    canvas.save();
    canvas.translate(pivot.dx, pivot.dy);
    canvas.rotate(angle);
    final rect = Rect.fromCenter(
      center: Offset(isLeft ? -rw * 0.25 : rw * 0.25, rh * 0.1),
      width: rw,
      height: rh,
    );
    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [skinCols[1], skinCols[2]],
      ).createShader(rect);
    canvas.drawOval(rect, paint);
    canvas.restore();
  }

  void _drawEye(Canvas canvas, Offset center, double radius, bool isLeft) {
    canvas.drawCircle(center, radius * 1.18, Paint()..color = const Color(0xFFFFF8E8));

    if (mood == OwlMood.sleeping || isBlinking) {
      final linePaint = Paint()
        ..color = const Color(0xFF3E2723)
        ..strokeWidth = radius * 0.24
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(
        Offset(center.dx - radius * 0.65, center.dy + (mood == OwlMood.sleeping ? radius * 0.15 : 0)),
        Offset(center.dx + radius * 0.65, center.dy + (mood == OwlMood.sleeping ? radius * 0.15 : 0)),
        linePaint,
      );
      return;
    }

    if (mood == OwlMood.happy || mood == OwlMood.love || mood == OwlMood.giggle) {
      final smileEye = Paint()
        ..color = const Color(0xFF2B2D42)
        ..style = PaintingStyle.stroke
        ..strokeWidth = radius * 0.26
        ..strokeCap = StrokeCap.round;
      final arcRect = Rect.fromCircle(center: Offset(center.dx, center.dy + radius * 0.15), radius: radius * 0.65);
      canvas.drawArc(arcRect, math.pi, math.pi, false, smileEye);
      return;
    }

    if (mood == OwlMood.dizzy) {
      final spiral = Paint()
        ..color = const Color(0xFF1F2937)
        ..style = PaintingStyle.stroke
        ..strokeWidth = radius * 0.18;
      canvas.drawCircle(center, radius * 0.65, spiral);
      canvas.drawCircle(center, radius * 0.28, spiral);
      return;
    }

    // Mắt tròn bình thường / liếc mắt / giận / khóc
    double pupilDx = 0;
    if (mood == OwlMood.sideEye) {
      pupilDx = radius * 0.34;
    } else if (mood == OwlMood.idle) {
      pupilDx = math.sin(phase * math.pi) * radius * 0.14;
    }

    final pupilCenter = Offset(center.dx + pupilDx, center.dy);
    canvas.drawCircle(pupilCenter, radius * 0.70, Paint()..color = const Color(0xFF1F2937));
    canvas.drawCircle(
      Offset(pupilCenter.dx - radius * 0.20, pupilCenter.dy - radius * 0.22),
      radius * 0.25,
      Paint()..color = Colors.white,
    );

    // Lông mày giận hờn (chữ V)
    if (mood == OwlMood.angry) {
      final brow = Paint()
        ..color = const Color(0xFF7F1D1D)
        ..strokeWidth = radius * 0.26
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(
        Offset(center.dx - radius * 0.7, center.dy - radius * (isLeft ? 0.95 : 0.45)),
        Offset(center.dx + radius * 0.7, center.dy - radius * (isLeft ? 0.45 : 0.95)),
        brow,
      );
    }

    // Giọt nước mắt rơi khi khóc
    if (mood == OwlMood.crying) {
      final tearY = center.dy + radius * 0.9 + (phase * radius * 1.4);
      canvas.drawCircle(Offset(center.dx, tearY), radius * 0.24, Paint()..color = const Color(0xFF38BDF8));
    }
  }

  void _drawMoodEffects(Canvas canvas, double w, double h, double cx) {
    if (mood == OwlMood.happy || mood == OwlMood.love) {
      final col = mood == OwlMood.love ? const Color(0xFFFF4D6D) : const Color(0xFFFFD166);
      final r = w * 0.055 * (0.8 + 0.4 * math.sin(phase * math.pi));
      canvas.drawCircle(Offset(w * 0.14, h * 0.20 - phase * 10), r, Paint()..color = col);
      canvas.drawCircle(Offset(w * 0.86, h * 0.18 - phase * 12), r * 1.1, Paint()..color = col);
    } else if (mood == OwlMood.dizzy) {
      final angle = phase * math.pi * 2;
      canvas.drawCircle(Offset(cx + math.cos(angle) * w * 0.24, h * 0.08), w * 0.045, Paint()..color = const Color(0xFFFACC15));
      canvas.drawCircle(Offset(cx - math.cos(angle) * w * 0.24, h * 0.10), w * 0.04, Paint()..color = const Color(0xFF38BDF8));
    } else if (mood == OwlMood.angry) {
      final p = Paint()..color = const Color(0xFFEF4444)..strokeWidth = 3..strokeCap = StrokeCap.round;
      canvas.drawLine(Offset(w * 0.78, h * 0.14), Offset(w * 0.85, h * 0.21), p);
      canvas.drawLine(Offset(w * 0.85, h * 0.14), Offset(w * 0.78, h * 0.21), p);
    }

    if (showSoapBubbles) {
      final b1 = Paint()..color = const Color(0xFFBAE6FD).withValues(alpha: 0.75);
      final bStroke = Paint()..color = Colors.white..style = PaintingStyle.stroke..strokeWidth = 2;
      final pts = [
        Offset(w * 0.30, h * 0.48 - phase * 10),
        Offset(w * 0.68, h * 0.46 - phase * 8),
        Offset(w * 0.48, h * 0.56 - phase * 12),
        Offset(w * 0.58, h * 0.36 - phase * 6),
      ];
      for (var i = 0; i < pts.length; i++) {
        final r = w * (0.055 + (i % 2) * 0.025);
        canvas.drawCircle(pts[i], r, b1);
        canvas.drawCircle(pts[i], r, bStroke);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _Owl3DPainter oldDelegate) =>
      oldDelegate.mood != mood ||
      oldDelegate.wingAngle != wingAngle ||
      oldDelegate.isBlinking != isBlinking ||
      oldDelegate.phase != phase ||
      oldDelegate.skin != skin ||
      oldDelegate.costume != costume ||
      oldDelegate.accessory != accessory ||
      oldDelegate.showSoapBubbles != showSoapBubbles;
}
