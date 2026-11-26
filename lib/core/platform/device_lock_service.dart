import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Giao diện trừu tượng quản lý khóa ứng dụng cấp hệ điều hành.
///
/// Hiện tại triển khai cho Android (Kotlin: UsageStatsManager + Overlay).
/// Trong tương lai chỉ cần thêm triển khai Swift (iOS FamilyControls)
/// mà không cần thay đổi logic UI hay bài tập ở tầng Flutter.
abstract class DeviceLockService {
  Future<bool> hasRequiredPermissions();
  Future<void> requestRequiredPermissions();
  Future<void> startMonitoring(List<String> blockedPackages);
  Future<void> stopMonitoring();
  Future<void> lockDeviceApps();
  Future<void> unlockForMinutes(int minutes);
  Future<Map<String, String>> getDeviceInfo();
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
      // Bỏ qua khi chạy trên môi trường chưa gắn native plugin.
    } on MissingPluginException {
      // Fallback an toàn cho unit test / desktop preview.
    }
  }

  @override
  Future<void> startMonitoring(List<String> blockedPackages) async {
    if (kIsWeb) return;
    try {
      await _channel.invokeMethod<void>('startMonitoring', {
        'blockedPackages': blockedPackages,
      });
    } on PlatformException {
      // Logged in native layer.
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
      final raw = await _channel.invokeMapMethod<String, dynamic>('getDeviceInfo');
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
}
