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
  });

  final String id;
  final int grade;
  final String textbookCode;
  final int week;
  final String subject;
  final QuestionDifficulty difficulty;
  final String type;
  final String prompt;
  final String audioText;
  final String visualEmoji;
  final List<String> options;
  final int correctIndex;
  final String hintText;

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
    );
  }
}
