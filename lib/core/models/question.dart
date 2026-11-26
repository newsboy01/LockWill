enum QuestionDifficulty {
  easy('easy', 'Dễ'),
  medium('medium', 'Trung bình'),
  hard('hard', 'Khá / Nâng cao');

  const QuestionDifficulty(this.code, this.label);
  final String code;
  final String label;

  static QuestionDifficulty fromCode(String code) {
    return QuestionDifficulty.values.firstWhere(
      (e) => e.code == code,
      orElse: () => QuestionDifficulty.easy,
    );
  }
}

class Question {
  const Question({
    required this.id,
    required this.grade,
    required this.textbookCode,
    required this.week,
    required this.subject,
    required this.difficulty,
    required this.type,
    required this.prompt,
    required this.audioText,
    required this.visualEmoji,
    required this.options,
    required this.correctIndex,
    required this.hintText,
    this.expectedSequence = const [],
  });

  final String id;
  final int grade;
  final String textbookCode;
  final int week;
  final String subject;
  final QuestionDifficulty difficulty;

  /// Các dạng bài:
  /// - `multiple_choice`: Trắc nghiệm 4 lựa chọn
  /// - `visual_count`: Đếm hình trực quan
  /// - `compare_math`: So sánh > < =
  /// - `true_false`: Đúng / Sai
  /// - `fill_number`: Tự nhập số bằng bàn phím
  /// - `drag_drop`: Kéo thả đáp án vào ô trống
  /// - `word_build`: Ghép chữ / ghép vần / ghép số theo thứ tự
  final String type;
  final String prompt;
  final String audioText;
  final String visualEmoji;
  final List<String> options;
  final int correctIndex;
  final String hintText;

  /// Dùng cho dạng `word_build`: thứ tự các mảnh đúng cần ghép (VD: ["m", "èo"]).
  final List<String> expectedSequence;

  factory Question.fromJson(Map<String, dynamic> json) {
    return Question(
      id: json['id'] as String,
      grade: json['grade'] as int,
      textbookCode: json['textbook'] as String,
      week: json['week'] as int,
      subject: json['subject'] as String,
      difficulty: QuestionDifficulty.fromCode(json['difficulty'] as String),
      type: json['type'] as String,
      prompt: json['prompt'] as String,
      audioText: json['audioText'] as String,
      visualEmoji: (json['visualEmoji'] as String?) ?? '',
      options: List<String>.from(json['options'] as List<dynamic>),
      correctIndex: json['correctIndex'] as int,
      hintText: (json['hintText'] as String?) ?? '',
      expectedSequence: List<String>.from(
        (json['expectedSequence'] as List<dynamic>?) ?? const [],
      ),
    );
  }
}
