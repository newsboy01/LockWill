import 'dart:convert';
import 'dart:math';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/child_profile.dart';
import '../models/question.dart';

class CurriculumService {
  static const _cacheKey = 'lockwill_remote_questions_cache_v1';
  List<Question>? _cachedQuestions;
  final Set<String> _askedPromptsInSession = <String>{};
  final Random _random = Random();

  /// Tự động tải ngân hàng câu hỏi mới nhất từ GitHub (không cần cài lại APK).
  Future<int> syncQuestionsFromGitHub(String repo) async {
    try {
      final cleanRepo = repo.trim().isEmpty ? 'newsboy01/LockWill' : repo.trim();
      final uri = Uri.parse(
        'https://raw.githubusercontent.com/$cleanRepo/main/assets/data/sample_questions.json',
      );
      final res = await http.get(uri).timeout(const Duration(seconds: 6));
      if (res.statusCode == 200) {
        final decoded = jsonDecode(res.body) as List<dynamic>;
        final parsed = decoded
            .map((e) => Question.fromJson(e as Map<String, dynamic>))
            .toList();
        if (parsed.isNotEmpty) {
          _cachedQuestions = parsed;
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString(_cacheKey, res.body);
          return parsed.length;
        }
      }
    } catch (_) {
      // Mất mạng thì giữ nguyên cache hoặc bộ câu hỏi đóng sẵn trong app.
    }
    return 0;
  }

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

  void resetSessionHistory() {
    _askedPromptsInSession.clear();
  }

  Future<List<Question>> loadQuestionsForChallenge({
    required ChildProfile profile,
    required QuestionDifficulty targetDifficulty,
    required int count,
  }) async {
    _cachedQuestions ??= await _loadFromAssets();
    final all = _cachedQuestions!;

    // Lọc câu tĩnh cùng lớp chưa từng hỏi trong ngày.
    final staticPool = all
        .where((q) =>
            q.grade == profile.grade && !_askedPromptsInSession.contains(q.prompt))
        .toList()
      ..shuffle(_random);

    final result = <Question>[];
    final usedPrompts = <String>{};

    // Lớp 1 ưu tiên lấy đa dạng dạng bài tĩnh (Ghép vần, Kéo thả hình học, Đố vui, Đúng/Sai)
    final ratio = profile.grade == 1 ? 0.6 : 0.4;
    final maxStatic = (count * ratio).ceil().clamp(1, staticPool.length);
    for (final q in staticPool.take(maxStatic)) {
      result.add(q);
      usedPrompts.add(q.prompt);
      _askedPromptsInSession.add(q.prompt);
    }

    var guard = 0;
    while (result.length < count && guard < 120) {
      guard++;
      final generated = _generateDynamicQuestion(
        profile: profile,
        difficulty: targetDifficulty,
        seedIndex: result.length + guard,
      );
      if (!usedPrompts.contains(generated.prompt) &&
          !_askedPromptsInSession.contains(generated.prompt)) {
        result.add(generated);
        usedPrompts.add(generated.prompt);
        _askedPromptsInSession.add(generated.prompt);
      }
    }

    result.shuffle(_random);
    return result;
  }

  Question _generateDynamicQuestion({
    required ChildProfile profile,
    required QuestionDifficulty difficulty,
    required int seedIndex,
  }) {
    final grade = profile.grade;
    final mode = seedIndex % 5;

    // 1. Đếm hình trực quan (Tối ưu cho Lớp 1-2)
    if (mode == 0 && grade <= 2) {
      final emojis = ['🍎', '🍓', '⭐', '🎈', '🐥', '🌸', '🚗', '🧁'];
      final icon = emojis[_random.nextInt(emojis.length)];
      final maxEach = difficulty == QuestionDifficulty.easy ? 4 : 6;
      final a = _random.nextInt(maxEach) + 1;
      final b = _random.nextInt(maxEach) + 1;
      final ans = a + b;
      return _buildNumericChoiceQuestion(
        id: 'dyn_vc_${DateTime.now().microsecondsSinceEpoch}_$seedIndex',
        grade: grade,
        textbook: profile.textbook.code,
        week: profile.currentWeek,
        difficulty: difficulty,
        type: 'visual_count',
        prompt: 'Đếm xem có tất cả bao nhiêu hình dưới đây?',
        audioText: 'Bé hãy đếm xem có tất cả bao nhiêu hình trên màn hình nhé!',
        visualEmoji: '${icon * a}  +  ${icon * b}  =  ?',
        answer: ans,
        hintText: 'Nhóm bên trái có $a hình, đếm tiếp nhóm bên phải thêm $b hình nữa!',
      );
    }

    // 2. Kéo thả số còn thiếu vào phép tính / dãy số (Drag & Drop)
    if (mode == 1) {
      if (grade == 1) {
        final start = _random.nextInt(12) + 1;
        final ans = start + 2;
        return _buildNumericChoiceQuestion(
          id: 'dyn_dd_seq_${DateTime.now().microsecondsSinceEpoch}_$seedIndex',
          grade: grade,
          textbook: profile.textbook.code,
          week: profile.currentWeek,
          difficulty: difficulty,
          type: 'drag_drop',
          prompt: 'Kéo số còn thiếu vào ô trống: $start, ${start + 1}, [ ? ], ${start + 3}',
          audioText: 'Bé hãy đếm xuôi: $start, ${start + 1}, rồi đến số mấy? Kéo số đúng vào ô trống nhé!',
          visualEmoji: '$start ➡️ ${start + 1} ➡️ ⬜ ➡️ ${start + 3}',
          answer: ans,
          hintText: 'Đứng ngay sau số ${start + 1} là số $ans đó!',
        );
      } else {
        final a = _random.nextInt(15) + 5;
        final b = _random.nextInt(15) + 5;
        final sum = a + b;
        return _buildNumericChoiceQuestion(
          id: 'dyn_dd_math_${DateTime.now().microsecondsSinceEpoch}_$seedIndex',
          grade: grade,
          textbook: profile.textbook.code,
          week: profile.currentWeek,
          difficulty: difficulty,
          type: 'drag_drop',
          prompt: 'Kéo số thích hợp thả vào ô trống: $a + [ ? ] = $sum',
          audioText: '$a cộng mấy bằng $sum? Bé hãy kéo số đúng thả vào ô trống!',
          visualEmoji: '$a  +  ⬜  =  $sum',
          answer: b,
          hintText: 'Lấy $sum trừ đi $a sẽ ra số cần tìm là $b!',
        );
      }
    }

    // 3. So sánh > < =
    if (mode == 2) {
      final maxVal = grade == 1
          ? (difficulty == QuestionDifficulty.easy ? 10 : 20)
          : (grade == 2 ? 99 : 500);
      final a = _random.nextInt(maxVal) + 1;
      final b = _random.nextInt(maxVal) + 1;
      final correctIdx = a > b ? 0 : (a < b ? 1 : 2);
      return Question(
        id: 'dyn_cmp_${DateTime.now().microsecondsSinceEpoch}_$seedIndex',
        grade: grade,
        textbookCode: profile.textbook.code,
        week: profile.currentWeek,
        subject: 'Toán - So sánh',
        difficulty: difficulty,
        type: 'compare_math',
        prompt: 'Chọn dấu thích hợp: $a  .....  $b',
        audioText: 'Bé hãy so sánh số $a và số $b, chọn dấu lớn hơn, bé hơn hoặc bằng!',
        visualEmoji: '$a   ⬜   $b',
        options: const ['>', '<', '='],
        correctIndex: correctIdx,
        hintText: a > b
            ? '$a lớn hơn $b nên chọn dấu >.'
            : (a < b ? '$a bé hơn $b nên chọn dấu <.' : 'Hai số bằng nhau nên chọn dấu =.'),
      );
    }

    // 4 & 5. Phép tính theo đúng chương trình lớp 1..5 (tự nhập bàn phím hoặc trắc nghiệm)
    late int a;
    late int b;
    late String op;
    late int ans;

    if (grade == 1) {
      final limit = difficulty == QuestionDifficulty.easy ? 10 : 18;
      final isAdd = _random.nextBool();
      if (isAdd) {
        a = _random.nextInt(limit - 2) + 1;
        b = _random.nextInt(limit - a) + 1;
        op = '+';
        ans = a + b;
      } else {
        a = _random.nextInt(limit - 2) + 3;
        b = _random.nextInt(a - 1) + 1;
        op = '-';
        ans = a - b;
      }
    } else if (grade == 2) {
      a = _random.nextInt(45) + 10;
      b = _random.nextInt(40) + 5;
      if (_random.nextBool()) {
        op = '+';
        ans = a + b;
      } else {
        if (a < b) {
          final tmp = a;
          a = b;
          b = tmp;
        }
        op = '-';
        ans = a - b;
      }
    } else if (grade == 3) {
      a = _random.nextInt(8) + 2;
      b = _random.nextInt(8) + 2;
      op = '×';
      ans = a * b;
    } else {
      a = _random.nextInt(35) + 12;
      b = _random.nextInt(9) + 3;
      op = '×';
      ans = a * b;
    }

    if (mode == 3) {
      return Question(
        id: 'dyn_fill_${DateTime.now().microsecondsSinceEpoch}_$seedIndex',
        grade: grade,
        textbookCode: profile.textbook.code,
        week: profile.currentWeek,
        subject: 'Toán - Tự điền',
        difficulty: difficulty,
        type: 'fill_number',
        prompt: 'Dùng bàn phím điền kết quả: $a $op $b = ?',
        audioText: 'Bé hãy tính và bấm bàn phím nhập kết quả của $a ${op == '×' ? 'nhân' : op} $b nhé!',
        visualEmoji: '$a  $op  $b  =  ?',
        options: [ans.toString()],
        correctIndex: 0,
        hintText: 'Bé tính cẩn thận từng bước: $a $op $b sẽ ra $ans đó!',
      );
    }

    return _buildNumericChoiceQuestion(
      id: 'dyn_mc_${DateTime.now().microsecondsSinceEpoch}_$seedIndex',
      grade: grade,
      textbook: profile.textbook.code,
      week: profile.currentWeek,
      difficulty: difficulty,
      type: 'multiple_choice',
      prompt: 'Tính nhanh: $a $op $b = ?',
      audioText: 'Tính nhanh: $a ${op == '×' ? 'nhân' : op} $b bằng bao nhiêu?',
      visualEmoji: '$a  $op  $b  =  ?',
      answer: ans,
      hintText: 'Thử nhẩm lại phép tính $a $op $b nhé!',
    );
  }

  Question _buildNumericChoiceQuestion({
    required String id,
    required int grade,
    required String textbook,
    required int week,
    required QuestionDifficulty difficulty,
    required String type,
    required String prompt,
    required String audioText,
    required String visualEmoji,
    required int answer,
    required String hintText,
  }) {
    final optionsSet = <int>{answer};
    while (optionsSet.length < 4) {
      final delta = _random.nextInt(5) + 1;
      final candidate = _random.nextBool() ? answer + delta : (answer - delta).abs();
      optionsSet.add(candidate);
    }
    final options = optionsSet.map((e) => e.toString()).toList()..shuffle(_random);
    final correctIndex = options.indexOf(answer.toString());

    return Question(
      id: id,
      grade: grade,
      textbookCode: textbook,
      week: week,
      subject: type == 'drag_drop' ? 'Toán - Kéo thả' : 'Toán',
      difficulty: difficulty,
      type: type,
      prompt: prompt,
      audioText: audioText,
      visualEmoji: visualEmoji,
      options: options,
      correctIndex: correctIndex,
      hintText: hintText,
    );
  }

  Future<List<Question>> _loadFromAssets() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedRaw = prefs.getString(_cacheKey);
      if (cachedRaw != null && cachedRaw.isNotEmpty) {
        final decoded = jsonDecode(cachedRaw) as List<dynamic>;
        return decoded
            .map((e) => Question.fromJson(e as Map<String, dynamic>))
            .toList();
      }
    } catch (_) {}

    final raw = await rootBundle.loadString('assets/data/sample_questions.json');
    final decoded = jsonDecode(raw) as List<dynamic>;
    return decoded
        .map((e) => Question.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
