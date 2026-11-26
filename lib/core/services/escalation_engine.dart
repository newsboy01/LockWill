import 'package:intl/intl.dart';
import '../models/child_profile.dart';
import '../models/daily_usage_state.dart';
import '../models/question.dart';

class ExtensionChallenge {
  const ExtensionChallenge({
    required this.turnNumber,
    required this.questionCount,
    required this.rewardMinutes,
    required this.targetDifficulty,
    required this.isDailyCapReached,
  });

  final int turnNumber;
  final int questionCount;
  final int rewardMinutes;
  final QuestionDifficulty targetDifficulty;
  final bool isDailyCapReached;
}

/// Quản lý cơ chế tăng dần số lượng & độ khó bài tập trong 1 ngày (theo tùy chỉnh phụ huynh),
/// luôn giữ kiến thức trong phạm vi chương trình lớp hiện tại và tự reset lúc 00:00.
class EscalationEngine {
  static String todayKey([DateTime? now]) {
    final dt = now ?? DateTime.now();
    return DateFormat('yyyy-MM-dd').format(dt);
  }

  DailyUsageState ensureFreshDay(
    DailyUsageState current,
    ChildProfile profile, {
    DateTime? now,
  }) {
    final key = todayKey(now);
    if (current.dateKey == key) return current;

    return DailyUsageState(
      dateKey: key,
      usedMinutes: 0,
      grantedMinutes: profile.dailyBaseMinutes,
      extensionCountToday: 0,
      totalCorrectToday: 0,
    );
  }

  /// Tính số câu hỏi và độ khó cho lượt gia hạn tiếp theo:
  /// - Tỷ lệ theo thời lượng gia hạn (`extensionMinutes`) phụ huynh chọn: càng nhiều phút càng nhiều câu.
  /// - Mỗi lượt gia hạn tiếp theo trong ngày cộng thêm +2 câu và nâng độ khó dần (Dễ -> TB -> Khá trong lớp).
  ExtensionChallenge nextChallenge(
    DailyUsageState state,
    ChildProfile profile,
  ) {
    final remainingCap = profile.dailyMaxMinutes - state.grantedMinutes;
    if (remainingCap <= 0) {
      return const ExtensionChallenge(
        turnNumber: 0,
        questionCount: 0,
        rewardMinutes: 0,
        targetDifficulty: QuestionDifficulty.hard,
        isDailyCapReached: true,
      );
    }

    final turn = state.extensionCountToday + 1;
    final desiredReward = profile.extensionMinutes.clamp(5, 60);
    final reward = remainingCap >= desiredReward ? desiredReward : remainingCap;

    // Quy đổi số câu cơ bản tỷ lệ với thời lượng gia hạn (chuẩn theo mốc 15 phút)
    final scaledBase =
        ((profile.baseQuestions * reward) / 15.0).round().clamp(3, 25);
    // Càng xin thêm nhiều lần trong ngày, số câu tăng thêm (+2 câu mỗi lượt)
    final totalQuestions = (scaledBase + (turn - 1) * 2).clamp(3, 30);

    final difficulty = turn == 1
        ? QuestionDifficulty.easy
        : (turn == 2 ? QuestionDifficulty.medium : QuestionDifficulty.hard);

    return ExtensionChallenge(
      turnNumber: turn,
      questionCount: totalQuestions,
      rewardMinutes: reward,
      targetDifficulty: difficulty,
      isDailyCapReached: false,
    );
  }
}
