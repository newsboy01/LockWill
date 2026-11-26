import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/child_profile.dart';
import '../models/question.dart';

class CurriculumService {
  List<Question>? _cachedQuestions;

  /// Ước lượng tuần học thực tế theo năm học Việt Nam (khai giảng đầu tháng 9).
  static int estimateCurrentSchoolWeek([DateTime? now]) {
    final dt = now ?? DateTime.now();
    final schoolYearStartYear = dt.month >= 9 ? dt.year : dt.year - 1;
    final start = DateTime(schoolYearStartYear, 9, 5);
    final diffDays = dt.difference(start).inDays;
    if (diffDays <= 0) return 1;
    final week = (diffDays ~/ 7) + 1;
    return week.clamp(1, 35);
  }

  Future<List<Question>> loadQuestionsForChallenge({
    required ChildProfile profile,
    required QuestionDifficulty targetDifficulty,
    required int count,
  }) async {
    _cachedQuestions ??= await _loadFromAssets();
    final all = _cachedQuestions!;

    // Ưu tiên đúng lớp + đúng tuần/bộ sách; nếu thiếu trong bộ mẫu thì fallback cùng lớp.
    final exactGrade = all.where((q) => q.grade == profile.grade).toList();
    final preferred = exactGrade
        .where((q) =>
            q.textbookCode == profile.textbook.code &&
            q.difficulty == targetDifficulty)
        .toList();

    final pool = <Question>[
      ...preferred,
      ...exactGrade.where((q) => !preferred.contains(q)),
    ];

    if (pool.isEmpty) {
      return all.take(count).toList();
    }

    final result = <Question>[];
    for (var i = 0; i < count; i++) {
      result.add(pool[i % pool.length]);
    }
    return result;
  }

  Future<List<Question>> _loadFromAssets() async {
    final raw = await rootBundle.loadString('assets/data/sample_questions.json');
    final decoded = jsonDecode(raw) as List<dynamic>;
    return decoded
        .map((e) => Question.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
