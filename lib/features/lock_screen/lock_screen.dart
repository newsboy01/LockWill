import 'package:flutter/material.dart';
import '../../core/models/child_profile.dart';
import '../../core/models/daily_usage_state.dart';
import '../../core/services/escalation_engine.dart';

class LockScreen extends StatelessWidget {
  const LockScreen({
    super.key,
    required this.profile,
    required this.usageState,
    required this.nextChallenge,
    required this.onStartQuiz,
    required this.onOpenParentGate,
    required this.onSpeakWelcome,
  });

  final ChildProfile profile;
  final DailyUsageState usageState;
  final ExtensionChallenge nextChallenge;
  final VoidCallback onStartQuiz;
  final VoidCallback onOpenParentGate;
  final VoidCallback onSpeakWelcome;

  @override
  Widget build(BuildContext context) {
    final capReached = nextChallenge.isDailyCapReached;

    return Scaffold(
      backgroundColor: const Color(0xFFFFF8EE),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Chip(
                    avatar: const Icon(Icons.school_rounded, size: 18),
                    label: Text(
                      'Lớp ${profile.grade} • Tuần ${profile.currentWeek}',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                  IconButton.filledTonal(
                    onPressed: onOpenParentGate,
                    tooltip: 'Cổng phụ huynh',
                    icon: const Icon(Icons.admin_panel_settings_rounded),
                  ),
                ],
              ),
              const Spacer(),
              Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFE4B5),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.orange.withValues(alpha: 0.2),
                      blurRadius: 24,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: const Center(
                  child: Text('🦉', style: TextStyle(fontSize: 72)),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                capReached
                    ? 'Hôm nay ${profile.name} đã dùng đủ giờ rồi!'
                    : 'Hết giờ giải trí rồi, ${profile.name} ơi!',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF2B2D42),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                capReached
                    ? 'Mắt cần nghỉ ngơi nhé. Ngày mai đồng hồ sẽ tự động đặt lại lúc 00:00.'
                    : 'Hoàn thành ${nextChallenge.questionCount} câu hỏi (${nextChallenge.targetDifficulty.label}) để nhận thêm +${nextChallenge.rewardMinutes} phút nhé!',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 17,
                  height: 1.4,
                  color: Color(0xFF5C6274),
                ),
              ),
              const SizedBox(height: 20),
              if (!capReached)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEAF6FF),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    'Lượt xin thêm hôm nay: Lần ${nextChallenge.turnNumber} • Độ khó: ${nextChallenge.targetDifficulty.label}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1D6FA5),
                    ),
                  ),
                ),
              const Spacer(),
              if (profile.isAudioFirstGrade)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: OutlinedButton.icon(
                    onPressed: onSpeakWelcome,
                    icon: const Icon(Icons.volume_up_rounded, size: 28),
                    label: const Text(
                      'Nghe bạn Cú hướng dẫn',
                      style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                    ),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(54),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ),
                ),
              SizedBox(
                width: double.infinity,
                height: 66,
                child: FilledButton.icon(
                  onPressed: capReached ? null : onStartQuiz,
                  icon: Icon(
                    capReached ? Icons.bedtime_rounded : Icons.play_arrow_rounded,
                    size: 32,
                  ),
                  label: Text(
                    capReached
                        ? 'Hẹn bé ngày mai nhé'
                        : 'Làm ${nextChallenge.questionCount} câu nhận +${nextChallenge.rewardMinutes} phút',
                    style: const TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFFF8C42),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(22),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}
