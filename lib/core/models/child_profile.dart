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

enum SfxStyle {
  cheerful('cheerful', 'Vui tươi (Chuông sáng)'),
  gentle('gentle', 'Nhẹ nhàng (Êm dịu)'),
  off('off', 'Chỉ đọc giọng nói (Tắt nhạc hiệu ứng)');

  const SfxStyle(this.code, this.displayName);
  final String code;
  final String displayName;

  static SfxStyle fromCode(String code) {
    return SfxStyle.values.firstWhere(
      (e) => e.code == code,
      orElse: () => SfxStyle.cheerful,
    );
  }
}

class ChildProfile {
  const ChildProfile({
    required this.name,
    required this.age,
    required this.grade,
    required this.textbook,
    required this.currentWeek,
    required this.dailyBaseMinutes,
    required this.dailyMaxMinutes,
    required this.parentPin,
    this.speechRate = 0.45,
    this.speechPitch = 1.08,
    this.voiceName = '',
    this.sfxStyle = SfxStyle.cheerful,
    this.location = 'Việt Nam',
    this.githubRepo = 'newsboy01/LockWill',
    this.githubToken = '',
    this.blockedPackages = const [
      'com.google.android.youtube',
      'com.zhiliaoapp.musically',
    ],
  });

  final String name;
  final int age; // 6..11
  final int grade; // 1..5
  final TextbookSeries textbook;
  final int currentWeek; // 1..35
  final int dailyBaseMinutes;
  final int dailyMaxMinutes;
  final String parentPin;

  /// Tùy chỉnh giọng đọc tiếng Việt cho trẻ từ Lớp 1-5.
  final double speechRate; // 0.25 (rất chậm) .. 0.75 (nhanh)
  final double speechPitch; // 0.8 (ấm) .. 1.3 (vui tươi)
  final String voiceName; // Tên giọng vi-VN cụ thể nếu thiết bị hỗ trợ
  final SfxStyle sfxStyle;

  /// Thông tin vị trí và đồng bộ GitHub để phân loại hồ sơ bé giữa các gia đình.
  final String location;
  final String githubRepo;
  final String githubToken;

  final List<String> blockedPackages;

  /// Khối lớp nhỏ (1-2) cần giao diện nút siêu lớn và ưu tiên giọng đọc (Audio-First).
  bool get isAudioFirstGrade => grade <= 2;

  ChildProfile copyWith({
    String? name,
    int? age,
    int? grade,
    TextbookSeries? textbook,
    int? currentWeek,
    int? dailyBaseMinutes,
    int? dailyMaxMinutes,
    String? parentPin,
    double? speechRate,
    double? speechPitch,
    String? voiceName,
    SfxStyle? sfxStyle,
    String? location,
    String? githubRepo,
    String? githubToken,
    List<String>? blockedPackages,
  }) {
    return ChildProfile(
      name: name ?? this.name,
      age: age ?? this.age,
      grade: grade ?? this.grade,
      textbook: textbook ?? this.textbook,
      currentWeek: currentWeek ?? this.currentWeek,
      dailyBaseMinutes: dailyBaseMinutes ?? this.dailyBaseMinutes,
      dailyMaxMinutes: dailyMaxMinutes ?? this.dailyMaxMinutes,
      parentPin: parentPin ?? this.parentPin,
      speechRate: speechRate ?? this.speechRate,
      speechPitch: speechPitch ?? this.speechPitch,
      voiceName: voiceName ?? this.voiceName,
      sfxStyle: sfxStyle ?? this.sfxStyle,
      location: location ?? this.location,
      githubRepo: githubRepo ?? this.githubRepo,
      githubToken: githubToken ?? this.githubToken,
      blockedPackages: blockedPackages ?? this.blockedPackages,
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'age': age,
        'grade': grade,
        'textbook': textbook.code,
        'currentWeek': currentWeek,
        'dailyBaseMinutes': dailyBaseMinutes,
        'dailyMaxMinutes': dailyMaxMinutes,
        'parentPin': parentPin,
        'speechRate': speechRate,
        'speechPitch': speechPitch,
        'voiceName': voiceName,
        'sfxStyle': sfxStyle.code,
        'location': location,
        'githubRepo': githubRepo,
        'githubToken': githubToken,
        'blockedPackages': blockedPackages,
      };

  factory ChildProfile.fromJson(Map<String, dynamic> json) {
    return ChildProfile(
      name: (json['name'] as String?) ?? 'Bé Minh',
      age: (json['age'] as int?) ?? 6,
      grade: (json['grade'] as int?) ?? 1,
      textbook: TextbookSeries.fromCode((json['textbook'] as String?) ?? ''),
      currentWeek: (json['currentWeek'] as int?) ?? 12,
      dailyBaseMinutes: (json['dailyBaseMinutes'] as int?) ?? 30,
      dailyMaxMinutes: (json['dailyMaxMinutes'] as int?) ?? 90,
      parentPin: (json['parentPin'] as String?) ?? '1234',
      speechRate: ((json['speechRate'] as num?) ?? 0.45).toDouble(),
      speechPitch: ((json['speechPitch'] as num?) ?? 1.08).toDouble(),
      voiceName: (json['voiceName'] as String?) ?? '',
      sfxStyle: SfxStyle.fromCode((json['sfxStyle'] as String?) ?? 'cheerful'),
      location: (json['location'] as String?) ?? 'Việt Nam',
      githubRepo: (json['githubRepo'] as String?) ?? 'newsboy01/LockWill',
      githubToken: (json['githubToken'] as String?) ?? '',
      blockedPackages: List<String>.from(
        (json['blockedPackages'] as List<dynamic>?) ??
            const ['com.google.android.youtube', 'com.zhiliaoapp.musically'],
      ),
    );
  }
}
