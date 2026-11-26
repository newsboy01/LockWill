import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/child_profile.dart';
import '../models/daily_usage_state.dart';
import 'curriculum_service.dart';
import 'escalation_engine.dart';

class StorageService {
  static const _profileKey = 'lockwill_child_profile_v1';
  static const _usageKey = 'lockwill_daily_usage_v1';
  static const _onboardingKey = 'lockwill_onboarding_done_v1';

  Future<bool> hasCompletedOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_onboardingKey) ?? false;
  }

  Future<void> markOnboardingCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_onboardingKey, true);
  }

  Future<ChildProfile> loadProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_profileKey);
    if (raw == null) {
      return ChildProfile(
        name: 'Bé Minh',
        age: 6,
        grade: 1,
        textbook: TextbookSeries.ketNoiTriThuc,
        currentWeek: CurriculumService.estimateCurrentSchoolWeek(),
        dailyBaseMinutes: 30,
        dailyMaxMinutes: 240,
        parentPin: '1234',
        parentName: 'Bố/Mẹ',
        extensionMinutes: 15,
        baseQuestions: 5,
      );
    }
    return ChildProfile.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  Future<void> saveProfile(ChildProfile profile) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_profileKey, jsonEncode(profile.toJson()));
  }

  Future<DailyUsageState> loadUsageState(ChildProfile profile) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_usageKey);
    if (raw == null) {
      return DailyUsageState(
        dateKey: EscalationEngine.todayKey(),
        usedMinutes: profile.dailyBaseMinutes,
        grantedMinutes: profile.dailyBaseMinutes,
        extensionCountToday: 0,
        totalCorrectToday: 0,
      );
    }
    final json = jsonDecode(raw) as Map<String, dynamic>;
    return DailyUsageState(
      dateKey: (json['dateKey'] as String?) ?? EscalationEngine.todayKey(),
      usedMinutes: (json['usedMinutes'] as int?) ?? 0,
      grantedMinutes:
          (json['grantedMinutes'] as int?) ?? profile.dailyBaseMinutes,
      extensionCountToday: (json['extensionCountToday'] as int?) ?? 0,
      totalCorrectToday: (json['totalCorrectToday'] as int?) ?? 0,
    );
  }

  Future<void> saveUsageState(DailyUsageState state) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _usageKey,
      jsonEncode({
        'dateKey': state.dateKey,
        'usedMinutes': state.usedMinutes,
        'grantedMinutes': state.grantedMinutes,
        'extensionCountToday': state.extensionCountToday,
        'totalCorrectToday': state.totalCorrectToday,
      }),
    );
  }
}
