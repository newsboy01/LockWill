import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../core/platform/device_lock_service.dart';
import '../../core/widgets/animated_owl_mascot.dart';
import '../../core/widgets/tactile_3d_button.dart';

/// Hộp thoại Chúc mừng 3D rực rỡ sau khi bé hoàn thành bài tập:
/// - Pháo hoa / sao bay chuyển động
/// - Bạn Cú mèo 3D nhảy mừng
/// - Hiển thị số phút + số sao thưởng và danh sách ứng dụng vừa được mở khóa 🔓
class CelebrationDialog extends StatefulWidget {
  const CelebrationDialog({
    super.key,
    required this.childName,
    required this.owlAccessory,
    required this.rewardMinutes,
    required this.earnedStars,
    required this.unlockedApps,
    required this.onLaunchApp,
  });

  final String childName;
  final String owlAccessory;
  final int rewardMinutes;
  final int earnedStars;
  final List<InstalledAppInfo> unlockedApps;
  final ValueChanged<String> onLaunchApp;

  @override
  State<CelebrationDialog> createState() => _CelebrationDialogState();
}

class _CelebrationDialogState extends State<CelebrationDialog>
    with SingleTickerProviderStateMixin {
  late final AnimationController _confettiCtrl;

  @override
  void initState() {
    super.initState();
    _confettiCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat();
  }

  @override
  void dispose() {
    _confettiCtrl.dispose();
    super.dispose();
  }

  (String, Color) _iconMetaForApp(InstalledAppInfo app) {
    final lower = '${app.appName} ${app.packageName}'.toLowerCase();
    if (lower.contains('youtube')) return ('▶️', const Color(0xFFFF0000));
    if (lower.contains('tiktok') || lower.contains('trill') || lower.contains('musically')) {
      return ('🎵', const Color(0xFF111827));
    }
    if (lower.contains('roblox') || lower.contains('game')) {
      return ('🎮', const Color(0xFF7C3AED));
    }
    if (lower.contains('facebook')) return ('📘', const Color(0xFF1877F2));
    return ('📱', const Color(0xFF0EA5E9));
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFFFFFBE6), Color(0xFFE6FFF9)],
                ),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: const Color(0xFFFFCA3A), width: 3),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 24,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AnimatedOwlMascot(
                      mood: OwlMood.happy,
                      size: 120,
                      accessory: widget.owlAccessory,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      '🎉 Chúc mừng ${widget.childName}!',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF0F766E),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 10,
                      runSpacing: 8,
                      alignment: WrapAlignment.center,
                      children: [
                        _rewardBadge('⏱️ +${widget.rewardMinutes} phút giải trí',
                            const Color(0xFF10B981)),
                        _rewardBadge(
                            '⭐ +${widget.earnedStars} Sao', const Color(0xFFF59E0B)),
                      ],
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      '🔓 Các ứng dụng sau đã được mở khóa:',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 14.5,
                        color: Color(0xFF334155),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      alignment: WrapAlignment.center,
                      children: widget.unlockedApps.take(6).map((app) {
                        final meta = _iconMetaForApp(app);
                        return InkWell(
                          borderRadius: BorderRadius.circular(18),
                          onTap: () {
                            Navigator.of(context).pop();
                            widget.onLaunchApp(app.packageName);
                          },
                          child: Container(
                            width: 112,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 10),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                  color: const Color(0xFF6EE7B7), width: 2),
                            ),
                            child: Column(
                              children: [
                                Stack(
                                  clipBehavior: Clip.none,
                                  children: [
                                    CircleAvatar(
                                      radius: 20,
                                      backgroundColor:
                                          meta.$2.withValues(alpha: 0.14),
                                      child: Text(meta.$1,
                                          style: const TextStyle(fontSize: 20)),
                                    ),
                                    const Positioned(
                                      right: -4,
                                      bottom: -2,
                                      child: Text('🔓',
                                          style: TextStyle(fontSize: 13)),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  app.appName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 12.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 18),
                    Tactile3DButton(
                      color: const Color(0xFF10B981),
                      shadowColor: const Color(0xFF047857),
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text(
                        'Tuyệt vời! Bắt đầu chơi thôi 🚀',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Lớp pháo hoa / sao bay phủ trên không chặn thao tác bấm
            Positioned.fill(
              child: IgnorePointer(
                child: AnimatedBuilder(
                  animation: _confettiCtrl,
                  builder: (_, __) => CustomPaint(
                    painter: _ConfettiPainter(_confettiCtrl.value),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _rewardBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w900,
          fontSize: 14,
        ),
      ),
    );
  }
}

class _ConfettiPainter extends CustomPainter {
  _ConfettiPainter(this.progress);
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    const colors = [
      Color(0xFFFFCA3A),
      Color(0xFF2EC4B6),
      Color(0xFFFF595E),
      Color(0xFF3A86FF),
      Color(0xFF8338EC),
    ];
    for (var i = 0; i < 18; i++) {
      final seed = i * 37.3;
      final x = ((math.sin(seed) * 0.5 + 0.5) * size.width);
      final y = ((progress + (i % 7) * 0.14) % 1.0) * size.height;
      final paint = Paint()
        ..color = colors[i % colors.length].withValues(alpha: 0.78);
      canvas.drawCircle(Offset(x, y), 4.5 + (i % 3), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
