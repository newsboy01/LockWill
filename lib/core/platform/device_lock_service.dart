import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class InstalledAppInfo {
  const InstalledAppInfo({
    required this.packageName,
    required this.appName,
  });

  final String packageName;
  final String appName;
}

/// Giao diện trừu tượng quản lý khóa ứng dụng cấp hệ điều hành.
///
/// Hiện tại triển khai cho Android (Kotlin: UsageStatsManager + ForegroundService + BootReceiver).
/// Trong tương lai chỉ cần thêm triển khai Swift (iOS FamilyControls)
/// mà không cần thay đổi logic UI hay bài tập ở tầng Flutter.
abstract class DeviceLockService {
  Future<bool> hasRequiredPermissions();
  Future<void> requestRequiredPermissions();
  Future<bool> isDeviceAdminActive();
  Future<void> requestDeviceAdmin();
  Future<void> requestIgnoreBatteryOptimization();
  Future<void> startMonitoring(List<String> blockedPackages);
  Future<void> stopMonitoring();
  Future<void> lockDeviceApps();
  Future<void> unlockForMinutes(int minutes);
  Future<int> getRemainingUnlockSeconds();
  Future<bool> launchApp(String packageName);
  Future<List<InstalledAppInfo>> getInstalledApps();
  Future<Map<String, dynamic>> getUsageHistory();
  Future<Map<String, String>> getDeviceInfo();
  Future<int> getAppVersionCode();
  Future<String> downloadAndInstallApk(String apkUrl);
}

class MethodChannelDeviceLockService implements DeviceLockService {
  static const MethodChannel _channel =
      MethodChannel('com.lockwill.app/device_lock');

  @override
  Future<bool> hasRequiredPermissions() async {
    if (kIsWeb) return true;
    try {
      final result = await _channel.invokeMethod<bool>('hasRequiredPermissions');
      return result ?? false;
    } on PlatformException {
      return false;
    } on MissingPluginException {
      return false;
    }
  }

  @override
  Future<void> requestRequiredPermissions() async {
    if (kIsWeb) return;
    try {
      await _channel.invokeMethod<void>('requestRequiredPermissions');
    } on PlatformException {
      // Safe fallback.
    } on MissingPluginException {
      // Safe fallback.
    }
  }

  @override
  Future<bool> isDeviceAdminActive() async {
    if (kIsWeb) return false;
    try {
      return (await _channel.invokeMethod<bool>('isDeviceAdminActive')) ?? false;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<void> requestDeviceAdmin() async {
    if (kIsWeb) return;
    try {
      await _channel.invokeMethod<void>('requestDeviceAdmin');
    } catch (_) {}
  }

  @override
  Future<void> requestIgnoreBatteryOptimization() async {
    if (kIsWeb) return;
    try {
      await _channel.invokeMethod<void>('requestIgnoreBatteryOptimization');
    } catch (_) {}
  }

  @override
  Future<Map<String, dynamic>> getUsageHistory() async {
    if (kIsWeb) {
      return {
        'date': DateTime.now().toIso8601String().substring(0, 10),
        'remainingSeconds': 0,
        'currentApp': 'LockWill Web Demo',
        'currentAppUpdatedAt': DateTime.now().toIso8601String(),
        'apps': [
          {
            'packageName': 'com.google.android.youtube',
            'appName': 'YouTube',
            'seconds': 1080,
            'isBlockedApp': true,
            'lastUsedAt': DateTime.now().toIso8601String(),
          },
          {
            'packageName': 'com.lockwill.app',
            'appName': 'LockWill',
            'seconds': 540,
            'isBlockedApp': false,
            'lastUsedAt': DateTime.now().toIso8601String(),
          },
        ],
      };
    }
    try {
      final raw = await _channel.invokeMethod<String>('getUsageHistoryJson');
      if (raw != null && raw.isNotEmpty) {
        return Map<String, dynamic>.from(jsonDecode(raw) as Map);
      }
    } catch (_) {}
    return const {'apps': []};
  }

  @override
  Future<void> startMonitoring(List<String> blockedPackages) async {
    if (kIsWeb) return;
    try {
      await _channel.invokeMethod<void>('startMonitoring', {
        'blockedPackages': blockedPackages,
      });
    } on PlatformException {
      // Safe fallback.
    } on MissingPluginException {
      // Safe fallback.
    }
  }

  @override
  Future<void> stopMonitoring() async {
    if (kIsWeb) return;
    try {
      await _channel.invokeMethod<void>('stopMonitoring');
    } on PlatformException {
      // Safe fallback.
    } on MissingPluginException {
      // Safe fallback.
    }
  }

  @override
  Future<void> lockDeviceApps() async {
    if (kIsWeb) return;
    try {
      await _channel.invokeMethod<void>('lockDeviceApps');
    } on PlatformException {
      // Safe fallback.
    } on MissingPluginException {
      // Safe fallback.
    }
  }

  @override
  Future<void> unlockForMinutes(int minutes) async {
    if (kIsWeb) return;
    try {
      await _channel.invokeMethod<void>('unlockForMinutes', {
        'minutes': minutes,
      });
    } on PlatformException {
      // Safe fallback.
    } on MissingPluginException {
      // Safe fallback.
    }
  }

  @override
  Future<int> getRemainingUnlockSeconds() async {
    if (kIsWeb) return 0;
    try {
      return (await _channel.invokeMethod<int>('getRemainingUnlockSeconds')) ?? 0;
    } catch (_) {
      return 0;
    }
  }

  @override
  Future<bool> launchApp(String packageName) async {
    if (kIsWeb) return false;
    try {
      return (await _channel.invokeMethod<bool>('launchApp', {
            'packageName': packageName,
          })) ??
          false;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<List<InstalledAppInfo>> getInstalledApps() async {
    if (kIsWeb) {
      return const [
        InstalledAppInfo(
            packageName: 'com.google.android.youtube', appName: 'YouTube'),
        InstalledAppInfo(
            packageName: 'com.zhiliaoapp.musically', appName: 'TikTok'),
        InstalledAppInfo(
            packageName: 'com.roblox.client', appName: 'Roblox'),
        InstalledAppInfo(
            packageName: 'com.facebook.katana', appName: 'Facebook'),
      ];
    }
    try {
      final raw = await _channel.invokeListMethod<dynamic>('getInstalledApps');
      if (raw != null) {
        return raw.map((item) {
          final map = Map<String, dynamic>.from(item as Map);
          return InstalledAppInfo(
            packageName: (map['packageName'] ?? '').toString(),
            appName: (map['appName'] ?? '').toString(),
          );
        }).toList();
      }
    } catch (_) {}
    return const [
      InstalledAppInfo(
          packageName: 'com.google.android.youtube', appName: 'YouTube'),
      InstalledAppInfo(
          packageName: 'com.zhiliaoapp.musically', appName: 'TikTok'),
    ];
  }

  @override
  Future<Map<String, String>> getDeviceInfo() async {
    if (kIsWeb) {
      return const {
        'brand': 'Web',
        'manufacturer': 'Browser',
        'model': 'Web Demo',
        'osVersion': 'Browser',
      };
    }
    try {
      final raw =
          await _channel.invokeMapMethod<String, dynamic>('getDeviceInfo');
      if (raw != null) {
        return raw.map((k, v) => MapEntry(k, v.toString()));
      }
    } catch (_) {}
    return const {
      'brand': 'Android',
      'manufacturer': 'Unknown',
      'model': 'Android Device',
      'osVersion': 'Android',
    };
  }

  @override
  Future<int> getAppVersionCode() async {
    if (kIsWeb) return 9999;
    try {
      return (await _channel.invokeMethod<int>('getAppVersionCode')) ?? 1;
    } catch (_) {
      return 1;
    }
  }

  @override
  Future<String> downloadAndInstallApk(String apkUrl) async {
    if (kIsWeb) return 'Bản Web luôn tự động là phiên bản mới nhất!';
    try {
      return (await _channel.invokeMethod<String>('downloadAndInstallApk', {
            'apkUrl': apkUrl,
          })) ??
          'Không thể khởi chạy bộ cài đặt.';
    } catch (e) {
      return 'Lỗi cập nhật: $e';
    }
  }
}
