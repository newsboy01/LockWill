import 'dart:convert';
import 'dart:math';
import 'package:flutter/services.dart';
import '../models/child_profile.dart';
import '../models/question.dart';

class CurriculumService {
  List<Question>? _cachedQuestions;
  final Set<String> _askedPromptsInSession = <String>{};
  final Random _random = Random();

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

    // Lọc các câu tĩnh cùng lớp chưa từng hỏi trong phiên/ngày.
    final staticPool = all
        .where((q) =>
            q.grade == profile.grade && !_askedPromptsInSession.contains(q.prompt))
        .toList()
      ..shuffle(_random);

    final result = <Question>[];
    final usedPrompts = <String>{};

    // Lấy tối đa ~40% câu tĩnh đa dạng môn (Tiếng Việt, Tiếng Anh, Khoa học, Đố vui),
    // phần còn lại sinh động theo đúng trình độ lớp để KHÔNG BAO GIỜ trùng lặp.
    final maxStatic = (count * 0.4).ceil().clamp(1, staticPool.length);
    for (final q in staticPool.take(maxStatic)) {
      result.add(q);
      usedPrompts.add(q.prompt);
      _askedPromptsInSession.add(q.prompt);
    }

    var guard = 0;
    while (result.length < count && guard < 100) {
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
    final mode = seedIndex % 3;

    if (mode == 0 && grade <= 2) {
      // Dạng đếm hình trực quan (Visual Count)
      final emojis = ['🍎', '🍓', '⭐', '🎈', '🐥', '🌸'];
      final icon = emojis[_random.nextInt(emojis.length)];
      final a = _random.nextInt(4) + 1;
      final b = _random.nextInt(4) + 1;
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
        hintText: 'Đếm nhóm bên trái có $a, đếm tiếp nhóm bên phải thêm $b nữa!',
      );
    }

    if (mode == 1) {
      // Dạng so sánh > < = (Compare Math)
      final maxVal = grade == 1 ? 15 : (grade == 2 ? 99 : 500);
      final a = _random.nextInt(maxVal) + 1;
      final b = _random.nextInt(maxVal) + 1;
      final correctIdx = a > b ? 0 : (a < b ? 1 : 2);
      return Question(
        id: 'dyn_cmp_${DateTime.now().microsecondsSinceEpoch}_$seedIndex',
        grade: grade,
        textbookCode: profile.textbook.code,
        week: profile.currentWeek,
        subject: 'Toán',
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

    // Dạng phép tính theo từng lớp (Toán nhập số hoặc trắc nghiệm)
    late int a;
    late int b;
    late String op;
    late int ans;

    if (grade == 1) {
      final isAdd = _random.nextBool();
      if (isAdd) {
        a = _random.nextInt(8) + 1;
        b = _random.nextInt(10 - a) + 1;
        op = '+';
        ans = a + b;
      } else {
        a = _random.nextInt(8) + 3;
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
      a = _random.nextInt(40) + 12;
      b = _random.nextInt(9) + 3;
      op = '×';
      ans = a * b;
    }

    final useFillNumber = seedIndex % 2 == 0;
    if (useFillNumber) {
      return Question(
        id: 'dyn_fill_${DateTime.now().microsecondsSinceEpoch}_$seedIndex',
        grade: grade,
        textbookCode: profile.textbook.code,
        week: profile.currentWeek,
        subject: 'Toán',
        difficulty: difficulty,
        type: 'fill_number',
        prompt: 'Điền kết quả đúng của phép tính: $a $op $b = ?',
        audioText: 'Bé hãy tính và nhập kết quả của phép tính $a ${op == '×' ? 'nhân' : op} $b bằng bao nhiêu?',
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
      subject: 'Toán',
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
    final raw = await rootBundle.loadString('assets/data/sample_questions.json');
    final decoded = jsonDecode(raw) as List<dynamic>;
    return decoded
        .map((e) => Question.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
