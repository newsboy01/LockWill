import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/child_profile.dart';
import '../platform/device_lock_service.dart';

class LearningSessionReport {
  const LearningSessionReport({
    required this.id,
    required this.timestamp,
    required this.childName,
    required this.age,
    required this.grade,
    required this.textbook,
    required this.location,
    required this.deviceBrand,
    required this.deviceModel,
    required this.osVersion,
    required this.totalQuestions,
    required this.firstTryCorrect,
    required this.wrongAttempts,
    required this.rewardMinutes,
    required this.subjectBreakdown,
  });

  final String id;
  final String timestamp;
  final String childName;
  final int age;
  final int grade;
  final String textbook;
  final String location;
  final String deviceBrand;
  final String deviceModel;
  final String osVersion;
  final int totalQuestions;
  final int firstTryCorrect;
  final int wrongAttempts;
  final int rewardMinutes;
  final Map<String, Map<String, int>> subjectBreakdown;

  Map<String, dynamic> toJson() => {
        'id': id,
        'timestamp': timestamp,
        'childName': childName,
        'age': age,
        'grade': grade,
        'textbook': textbook,
        'location': location,
        'deviceBrand': deviceBrand,
        'deviceModel': deviceModel,
        'osVersion': osVersion,
        'totalQuestions': totalQuestions,
        'firstTryCorrect': firstTryCorrect,
        'wrongAttempts': wrongAttempts,
        'rewardMinutes': rewardMinutes,
        'subjectBreakdown': subjectBreakdown,
      };
}

/// Lưu lịch sử học tập cục bộ và tự động đồng bộ lên GitHub (docs/reports/learning_data.json)
/// để trang Web Phân tích Phụ huynh trên GitHub Pages tự tổng hợp & đánh giá.
class LearningReportService {
  static const _localReportsKey = 'lockwill_learning_reports_v1';
  static const _remoteReportPath = 'docs/reports/learning_data.json';

  Future<List<Map<String, dynamic>>> loadLocalReports() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_localReportsKey);
    if (raw == null) return [];
    final list = jsonDecode(raw) as List<dynamic>;
    return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  Future<bool> recordAndSyncSession({
    required ChildProfile profile,
    required DeviceLockService deviceLockService,
    required int totalQuestions,
    required int firstTryCorrect,
    required int wrongAttempts,
    required int rewardMinutes,
    required Map<String, Map<String, int>> subjectBreakdown,
  }) async {
    final device = await deviceLockService.getDeviceInfo();
    final report = LearningSessionReport(
      id: 'sess_${DateTime.now().millisecondsSinceEpoch}',
      timestamp: DateTime.now().toIso8601String(),
      childName: profile.name,
      age: profile.age,
      grade: profile.grade,
      textbook: profile.textbook.displayName,
      location: profile.location,
      deviceBrand: device['brand'] ?? 'Unknown',
      deviceModel: device['model'] ?? 'Unknown',
      osVersion: device['osVersion'] ?? 'Unknown',
      totalQuestions: totalQuestions,
      firstTryCorrect: firstTryCorrect,
      wrongAttempts: wrongAttempts,
      rewardMinutes: rewardMinutes,
      subjectBreakdown: subjectBreakdown,
    );

    final reports = await loadLocalReports();
    reports.insert(0, report.toJson());
    if (reports.length > 200) {
      reports.removeRange(200, reports.length);
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_localReportsKey, jsonEncode(reports));

    if (profile.githubToken.trim().isNotEmpty &&
        profile.githubRepo.trim().contains('/')) {
      return _pushReportToGitHub(
        repo: profile.githubRepo.trim(),
        token: profile.githubToken.trim(),
        newSession: report.toJson(),
      );
    }
    return false;
  }

  Future<bool> _pushReportToGitHub({
    required String repo,
    required String token,
    required Map<String, dynamic> newSession,
  }) async {
    try {
      final uri = Uri.parse(
        'https://api.github.com/repos/$repo/contents/$_remoteReportPath',
      );
      final headers = {
        'Authorization': 'Bearer $token',
        'Accept': 'application/vnd.github+json',
        'Content-Type': 'application/json',
      };

      String? sha;
      List<dynamic> existingSessions = [];

      final getRes = await http.get(uri, headers: headers);
      if (getRes.statusCode == 200) {
        final body = jsonDecode(getRes.body) as Map<String, dynamic>;
        sha = body['sha'] as String?;
        final contentB64 = (body['content'] as String).replaceAll('\n', '');
        final decodedStr = utf8.decode(base64Decode(contentB64));
        final parsed = jsonDecode(decodedStr) as Map<String, dynamic>;
        existingSessions = List<dynamic>.from(
          (parsed['sessions'] as List<dynamic>?) ?? const [],
        );
      }

      existingSessions.insert(0, newSession);
      if (existingSessions.length > 500) {
        existingSessions = existingSessions.sublist(0, 500);
      }

      final updatedPayload = const JsonEncoder.withIndent('  ').convert({
        'updatedAt': DateTime.now().toIso8601String(),
        'sessions': existingSessions,
      });

      final putBody = <String, dynamic>{
        'message': 'Sync learning report for ${newSession['childName']}',
        'content': base64Encode(utf8.encode(updatedPayload)),
        if (sha != null) 'sha': sha,
      };

      final putRes = await http.put(
        uri,
        headers: headers,
        body: jsonEncode(putBody),
      );
      return putRes.statusCode == 200 || putRes.statusCode == 201;
    } catch (_) {
      return false;
    }
  }
}
