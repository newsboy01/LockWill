enum TextbookSeries {
  ketNoiTriThuc('ket_noi_tri_thuc', 'Kết nối tri thức với cuộc sống'),
  chanTroiSangTao('chan_troi_sang_tao', 'Chân trời sáng tạo'),
  canhDieu('canh_dieu', 'Cánh Diều');

  const TextbookSeries(this.code, this.displayName);
  final String code;
  final String displayName;

  static TextbookSeries fromCode(String code) {
    return TextbookSeries.values.firstWhere(
      (e) => e.code == code,
      orElse: () => TextbookSeries.ketNoiTriThuc,
    );
  }
}

class ChildProfile {
  const ChildProfile({
    required this.name,
    required this.grade,
    required this.textbook,
    required this.currentWeek,
    required this.dailyBaseMinutes,
    required this.dailyMaxMinutes,
    required this.parentPin,
    this.blockedPackages = const [
      'com.google.android.youtube',
      'com.zhiliaoapp.musically',
    ],
  });

  final String name;
  final int grade; // 1..5
  final TextbookSeries textbook;
  final int currentWeek; // 1..35
  final int dailyBaseMinutes;
  final int dailyMaxMinutes;
  final String parentPin;
  final List<String> blockedPackages;

  /// Khối lớp nhỏ (1-2) cần giao diện nút siêu lớn và ưu tiên giọng đọc (Audio-First).
  bool get isAudioFirstGrade => grade <= 2;

  ChildProfile copyWith({
    String? name,
    int? grade,
    TextbookSeries? textbook,
    int? currentWeek,
    int? dailyBaseMinutes,
    int? dailyMaxMinutes,
    String? parentPin,
    List<String>? blockedPackages,
  }) {
    return ChildProfile(
      name: name ?? this.name,
      grade: grade ?? this.grade,
      textbook: textbook ?? this.textbook,
      currentWeek: currentWeek ?? this.currentWeek,
      dailyBaseMinutes: dailyBaseMinutes ?? this.dailyBaseMinutes,
      dailyMaxMinutes: dailyMaxMinutes ?? this.dailyMaxMinutes,
      parentPin: parentPin ?? this.parentPin,
      blockedPackages: blockedPackages ?? this.blockedPackages,
    );
  }
}
