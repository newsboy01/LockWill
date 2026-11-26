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

/// Quản lý cơ chế tăng dần số lượng & độ khó bài tập trong 1 ngày,
/// và tự động reset về trạng thái ban đầu khi sang ngày mới.
class EscalationEngine {
  static String todayKey([DateTime? now]) {
    final dt = now ?? DateTime.now();
    return DateFormat('yyyy-MM-dd').format(dt);
  }

  /// Nếu đã sang ngày mới, trả về state mới với quỹ thời gian mặc định.
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

  /// Tính yêu cầu bài tập cho lượt xin thêm giờ tiếp theo trong ngày.
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
    if (turn == 1) {
      return ExtensionChallenge(
        turnNumber: 1,
        questionCount: 5,
        rewardMinutes: remainingCap >= 15 ? 15 : remainingCap,
        targetDifficulty: QuestionDifficulty.easy,
        isDailyCapReached: false,
      );
    } else if (turn == 2) {
      return ExtensionChallenge(
        turnNumber: 2,
        questionCount: 8,
        rewardMinutes: remainingCap >= 15 ? 15 : remainingCap,
        targetDifficulty: QuestionDifficulty.medium,
        isDailyCapReached: false,
      );
    } else {
      final extraQuestions = 10 + (turn - 3) * 2;
      return ExtensionChallenge(
        turnNumber: turn,
        questionCount: extraQuestions,
        rewardMinutes: remainingCap >= 10 ? 10 : remainingCap,
        targetDifficulty: QuestionDifficulty.hard,
        isDailyCapReached: false,
      );
    }
  }
}
