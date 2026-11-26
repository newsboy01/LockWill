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
    this.parentName = 'Phụ huynh',
    this.extensionMinutes = 15,
    this.baseQuestions = 5,
    this.speechRate = 0.45,
    this.speechPitch = 1.08,
    this.voiceName = '',
    this.sfxStyle = SfxStyle.cheerful,
    this.location = 'Việt Nam',
    this.githubRepo = 'newsboy01/LockWill',
    this.githubToken = '',
    this.stars = 0,
    this.owlAccessory = 'grad_cap',
    this.bgmEnabled = false,
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
  final int dailyMaxMinutes; // Mở rộng lên tới 480 phút/ngày
  final String parentPin;
  final String parentName;

  /// Tùy chỉnh thời lượng mỗi lần gia hạn và số câu hỏi cơ bản tương ứng.
  final int extensionMinutes; // 5, 10, 15, 20, 30
  final int baseQuestions; // 3..15

  /// Tùy chỉnh giọng đọc tiếng Việt cho trẻ từ Lớp 1-5.
  final double speechRate; // 0.25 .. 0.75
  final double speechPitch; // 0.8 .. 1.3
  final String voiceName;
  final SfxStyle sfxStyle;

  final String location;
  final String githubRepo;
  final String githubToken;

  /// Gamification
  final int stars;
  final String owlAccessory; // none | grad_cap | glasses | crown
  final bool bgmEnabled;

  final List<String> blockedPackages;

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
    String? parentName,
    int? extensionMinutes,
    int? baseQuestions,
    double? speechRate,
    double? speechPitch,
    String? voiceName,
    SfxStyle? sfxStyle,
    String? location,
    String? githubRepo,
    String? githubToken,
    int? stars,
    String? owlAccessory,
    bool? bgmEnabled,
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
      parentName: parentName ?? this.parentName,
      extensionMinutes: extensionMinutes ?? this.extensionMinutes,
      baseQuestions: baseQuestions ?? this.baseQuestions,
      speechRate: speechRate ?? this.speechRate,
      speechPitch: speechPitch ?? this.speechPitch,
      voiceName: voiceName ?? this.voiceName,
      sfxStyle: sfxStyle ?? this.sfxStyle,
      location: location ?? this.location,
      githubRepo: githubRepo ?? this.githubRepo,
      githubToken: githubToken ?? this.githubToken,
      stars: stars ?? this.stars,
      owlAccessory: owlAccessory ?? this.owlAccessory,
      bgmEnabled: bgmEnabled ?? this.bgmEnabled,
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
        'parentName': parentName,
        'extensionMinutes': extensionMinutes,
        'baseQuestions': baseQuestions,
        'speechRate': speechRate,
        'speechPitch': speechPitch,
        'voiceName': voiceName,
        'sfxStyle': sfxStyle.code,
        'location': location,
        'githubRepo': githubRepo,
        'githubToken': githubToken,
        'stars': stars,
        'owlAccessory': owlAccessory,
        'bgmEnabled': bgmEnabled,
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
      dailyMaxMinutes: (json['dailyMaxMinutes'] as int?) ?? 240,
      parentPin: (json['parentPin'] as String?) ?? '1234',
      parentName: (json['parentName'] as String?) ?? 'Phụ huynh',
      extensionMinutes: (json['extensionMinutes'] as int?) ?? 15,
      baseQuestions: (json['baseQuestions'] as int?) ?? 5,
      speechRate: ((json['speechRate'] as num?) ?? 0.45).toDouble(),
      speechPitch: ((json['speechPitch'] as num?) ?? 1.08).toDouble(),
      voiceName: (json['voiceName'] as String?) ?? '',
      sfxStyle: SfxStyle.fromCode((json['sfxStyle'] as String?) ?? 'cheerful'),
      location: (json['location'] as String?) ?? 'Việt Nam',
      githubRepo: (json['githubRepo'] as String?) ?? 'newsboy01/LockWill',
      githubToken: (json['githubToken'] as String?) ?? '',
      stars: (json['stars'] as int?) ?? 0,
      owlAccessory: (json['owlAccessory'] as String?) ?? 'grad_cap',
      bgmEnabled: (json['bgmEnabled'] as bool?) ?? false,
      blockedPackages: List<String>.from(
        (json['blockedPackages'] as List<dynamic>?) ??
            const ['com.google.android.youtube', 'com.zhiliaoapp.musically'],
      ),
    );
  }
}
