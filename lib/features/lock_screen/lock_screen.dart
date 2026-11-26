import 'package:flutter/material.dart';
import '../../core/models/child_profile.dart';
import '../../core/models/daily_usage_state.dart';
import '../../core/services/escalation_engine.dart';
import '../../core/widgets/animated_owl_mascot.dart';
import '../../core/widgets/tactile_3d_button.dart';

class LockScreen extends StatelessWidget {
  const LockScreen({
    super.key,
    required this.profile,
    required this.usageState,
    required this.nextChallenge,
    required this.isMuted,
    required this.onToggleMute,
    required this.onStartQuiz,
    required this.onOpenParentGate,
    required this.onSpeakWelcome,
  });

  final ChildProfile profile;
  final DailyUsageState usageState;
  final ExtensionChallenge nextChallenge;
  final bool isMuted;
  final VoidCallback onToggleMute;
  final VoidCallback onStartQuiz;
  final VoidCallback onOpenParentGate;
  final VoidCallback onSpeakWelcome;

  @override
  Widget build(BuildContext context) {
    final capReached = nextChallenge.isDailyCapReached;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFFFF3E0), Color(0xFFE8F7FF)],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(22),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                        child: Text(
                          '🎓 ${profile.name} (${profile.age}t) • Lớp ${profile.grade} • Tuần ${profile.currentWeek}',
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Row(
                      children: [
                        IconButton.filledTonal(
                          onPressed: onToggleMute,
                          tooltip: isMuted ? 'Bật âm thanh' : 'Tắt âm thanh',
                          icon: Icon(
                            isMuted
                                ? Icons.volume_off_rounded
                                : Icons.volume_up_rounded,
                          ),
                        ),
                        const SizedBox(width: 6),
                        IconButton.filledTonal(
                          onPressed: onOpenParentGate,
                          tooltip: 'Cổng phụ huynh',
                          icon: const Icon(Icons.admin_panel_settings_rounded),
                        ),
                      ],
                    ),
                  ],
                ),
                const Spacer(),
                const AnimatedOwlMascot(mood: OwlMood.idle, size: 165),
                const SizedBox(height: 18),
                Text(
                  capReached
                      ? 'Hôm nay ${profile.name} đã dùng đủ giờ rồi!'
                      : 'Hết giờ giải trí rồi, ${profile.name} ơi!',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF2B2D42),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  capReached
                      ? 'Mắt cần nghỉ ngơi nhé. Ngày mai đồng hồ sẽ tự động đặt lại lúc 00:00.'
                      : 'Hoàn thành ${nextChallenge.questionCount} câu hỏi (${nextChallenge.targetDifficulty.label}) để nhận thêm +${nextChallenge.rewardMinutes} phút nhé!',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 17,
                    height: 1.4,
                    color: Color(0xFF475569),
                  ),
                ),
                const SizedBox(height: 16),
                if (!capReached)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: const Color(0xFFBAE6FD)),
                    ),
                    child: Text(
                      '⭐ Lượt xin thêm hôm nay: Lần ${nextChallenge.turnNumber} • Độ khó: ${nextChallenge.targetDifficulty.label}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0369A1),
                      ),
                    ),
                  ),
                const Spacer(),
                if (profile.isAudioFirstGrade)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Tactile3DButton(
                      color: const Color(0xFF38BDF8),
                      shadowColor: const Color(0xFF0284C7),
                      onPressed: onSpeakWelcome,
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.hearing_rounded,
                              color: Colors.white, size: 26),
                          SizedBox(width: 8),
                          Text(
                            'Nghe bạn Cú hướng dẫn',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                Tactile3DButton(
                  color: const Color(0xFFFF8C42),
                  shadowColor: const Color(0xFFD16014),
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  onPressed: capReached ? null : onStartQuiz,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        capReached
                            ? Icons.bedtime_rounded
                            : Icons.play_arrow_rounded,
                        color: Colors.white,
                        size: 30,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        capReached
                            ? 'Hẹn bé ngày mai nhé'
                            : 'Làm ${nextChallenge.questionCount} câu nhận +${nextChallenge.rewardMinutes} phút',
                        style: const TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
