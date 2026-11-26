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
    required this.appUsageSnapshot,
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
  final Map<String, dynamic> appUsageSnapshot;

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
        'appUsageSnapshot': appUsageSnapshot,
      };
}

/// Lưu lịch sử học tập + toàn bộ lịch sử sử dụng ứng dụng trên điện thoại
/// và đồng bộ lên GitHub (docs/reports/learning_data.json) cho trang Web Giám Sát Phụ Huynh.
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
    final usageSnapshot = await deviceLockService.getUsageHistory();

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
      appUsageSnapshot: usageSnapshot,
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
      return _pushToGitHub(
        repo: profile.githubRepo.trim(),
        token: profile.githubToken.trim(),
        newSession: report.toJson(),
        deviceMonitorRecord: _buildDeviceMonitorRecord(profile, device, usageSnapshot),
      );
    }
    return false;
  }

  /// Đồng bộ riêng trạng thái thiết bị hiện tại (đang mở app gì, dùng từng app bao lâu) lên GitHub.
  /// Trả về chuỗi thông báo kết quả rõ ràng (hoặc mã lỗi HTTP nếu thất bại).
  Future<String> syncDeviceUsageNow({
    required ChildProfile profile,
    required DeviceLockService deviceLockService,
    String? overrideRepo,
    String? overrideToken,
  }) async {
    final repo = (overrideRepo ?? profile.githubRepo).trim();
    final token = (overrideToken ?? profile.githubToken).trim();
    if (token.isEmpty || !repo.contains('/')) {
      return 'Chưa nhập GitHub Repo hoặc GitHub Token hợp lệ.';
    }
    final device = await deviceLockService.getDeviceInfo();
    final usageSnapshot = await deviceLockService.getUsageHistory();
    return _pushToGitHubWithStatus(
      repo: repo,
      token: token,
      newSession: null,
      deviceMonitorRecord: _buildDeviceMonitorRecord(profile, device, usageSnapshot),
    );
  }

  Map<String, dynamic> _buildDeviceMonitorRecord(
    ChildProfile profile,
    Map<String, String> device,
    Map<String, dynamic> usageSnapshot,
  ) {
    return {
      'deviceKey': '${profile.name}_${device['brand']}_${device['model']}',
      'childName': profile.name,
      'age': profile.age,
      'grade': profile.grade,
      'location': profile.location,
      'deviceBrand': device['brand'] ?? 'Unknown',
      'deviceModel': device['model'] ?? 'Unknown',
      'osVersion': device['osVersion'] ?? 'Unknown',
      'currentApp': usageSnapshot['currentApp'] ?? 'LockWill',
      'lastSeenAt': usageSnapshot['currentAppUpdatedAt'] ??
          DateTime.now().toIso8601String(),
      'remainingSeconds': usageSnapshot['remainingSeconds'] ?? 0,
      'apps': usageSnapshot['apps'] ?? const [],
    };
  }

  Future<bool> _pushToGitHub({
    required String repo,
    required String token,
    required Map<String, dynamic>? newSession,
    required Map<String, dynamic> deviceMonitorRecord,
  }) async {
    final msg = await _pushToGitHubWithStatus(
      repo: repo,
      token: token,
      newSession: newSession,
      deviceMonitorRecord: deviceMonitorRecord,
    );
    return msg.startsWith('OK:');
  }

  Future<String> _pushToGitHubWithStatus({
    required String repo,
    required String token,
    required Map<String, dynamic>? newSession,
    required Map<String, dynamic> deviceMonitorRecord,
  }) async {
    try {
      final uri = Uri.parse(
        'https://api.github.com/repos/$repo/contents/$_remoteReportPath',
      );
      final headers = {
        'Authorization': 'Bearer $token',
        'Accept': 'application/vnd.github+json',
        'User-Agent': 'LockWill-App',
        'Content-Type': 'application/json',
      };

      String? sha;
      List<dynamic> existingSessions = [];
      List<dynamic> existingMonitors = [];

      final getRes = await http
          .get(uri, headers: headers)
          .timeout(const Duration(seconds: 12));
      if (getRes.statusCode == 200) {
        final body = jsonDecode(getRes.body) as Map<String, dynamic>;
        sha = body['sha'] as String?;
        final contentB64 = (body['content'] as String).replaceAll('\n', '');
        final decodedStr = utf8.decode(base64Decode(contentB64));
        final parsed = jsonDecode(decodedStr) as Map<String, dynamic>;
        existingSessions = List<dynamic>.from(
          (parsed['sessions'] as List<dynamic>?) ?? const [],
        );
        existingMonitors = List<dynamic>.from(
          (parsed['deviceMonitors'] as List<dynamic>?) ?? const [],
        );
      } else if (getRes.statusCode != 404) {
        return 'Lỗi đọc GitHub (HTTP ${getRes.statusCode}). Kiểm tra lại Token hoặc quyền Contents.';
      }

      if (newSession != null) {
        existingSessions.insert(0, newSession);
        if (existingSessions.length > 500) {
          existingSessions = existingSessions.sublist(0, 500);
        }
      }

      final key = deviceMonitorRecord['deviceKey'];
      existingMonitors.removeWhere((m) => (m as Map)['deviceKey'] == key);
      existingMonitors.insert(0, deviceMonitorRecord);

      final updatedPayload = const JsonEncoder.withIndent('  ').convert({
        'updatedAt': DateTime.now().toIso8601String(),
        'deviceMonitors': existingMonitors,
        'sessions': existingSessions,
      });

      final putBody = <String, dynamic>{
        'message': 'Sync learning & device usage for ${deviceMonitorRecord['childName']}',
        'content': base64Encode(utf8.encode(updatedPayload)),
        if (sha != null) 'sha': sha,
      };

      final putRes = await http
          .put(uri, headers: headers, body: jsonEncode(putBody))
          .timeout(const Duration(seconds: 12));
      if (putRes.statusCode == 200 || putRes.statusCode == 201) {
        return 'OK: Đã đồng bộ lịch sử lên trang Giám sát thành công!';
      }
      return 'Lỗi ghi GitHub (HTTP ${putRes.statusCode}). Đảm bảo Token có quyền Contents: Read and write.';
    } catch (e) {
      return 'Lỗi kết nối mạng: $e';
    }
  }
}
