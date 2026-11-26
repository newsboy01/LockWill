class DailyUsageState {
  const DailyUsageState({
    required this.dateKey,
    required this.usedMinutes,
    required this.grantedMinutes,
    required this.extensionCountToday,
    required this.totalCorrectToday,
  });

  /// Định dạng YYYY-MM-DD để phát hiện sang ngày mới và tự động reset.
  final String dateKey;
  final int usedMinutes;
  final int grantedMinutes;
  final int extensionCountToday;
  final int totalCorrectToday;

  int get remainingMinutes {
    final left = grantedMinutes - usedMinutes;
    return left > 0 ? left : 0;
  }

  bool get isTimeUp => remainingMinutes <= 0;

  DailyUsageState copyWith({
    String? dateKey,
    int? usedMinutes,
    int? grantedMinutes,
    int? extensionCountToday,
    int? totalCorrectToday,
  }) {
    return DailyUsageState(
      dateKey: dateKey ?? this.dateKey,
      usedMinutes: usedMinutes ?? this.usedMinutes,
      grantedMinutes: grantedMinutes ?? this.grantedMinutes,
      extensionCountToday: extensionCountToday ?? this.extensionCountToday,
      totalCorrectToday: totalCorrectToday ?? this.totalCorrectToday,
    );
  }
}
