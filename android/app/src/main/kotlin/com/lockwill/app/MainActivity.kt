package com.lockwill.app

import android.app.AppOpsManager
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.Process
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val channelName = "com.lockwill.app/device_lock"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "hasRequiredPermissions" -> {
                        result.success(hasUsageStatsPermission() && Settings.canDrawOverlays(this))
                    }
                    "requestRequiredPermissions" -> {
                        requestMissingPermissions()
                        result.success(null)
                    }
                    "startMonitoring" -> {
                        val packages = call.argument<List<String>>("blockedPackages") ?: emptyList()
                        val intent = Intent(this, UsageMonitorService::class.java).apply {
                            putStringArrayListExtra("blockedPackages", ArrayList(packages))
                        }
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                            startForegroundService(intent)
                        } else {
                            startService(intent)
                        }
                        result.success(null)
                    }
                    "stopMonitoring" -> {
                        stopService(Intent(this, UsageMonitorService::class.java))
                        result.success(null)
                    }
                    "lockDeviceApps" -> {
                        LockOverlayManager.bringLockScreenToFront(this)
                        result.success(null)
                    }
                    "unlockForMinutes" -> {
                        val minutes = call.argument<Int>("minutes") ?: 15
                        UsageMonitorService.grantMinutes(minutes)
                        result.success(null)
                    }
                    "getDeviceInfo" -> {
                        val info = mapOf(
                            "brand" to Build.BRAND,
                            "manufacturer" to Build.MANUFACTURER,
                            "model" to Build.MODEL,
                            "osVersion" to "Android ${Build.VERSION.RELEASE} (SDK ${Build.VERSION.SDK_INT})"
                        )
                        result.success(info)
                    }
                    else -> result.notImplemented()
                }
            }
    }

    private fun hasUsageStatsPermission(): Boolean {
        val appOps = getSystemService(Context.APP_OPS_SERVICE) as AppOpsManager
        val mode = appOps.unsafeCheckOpNoThrow(
            AppOpsManager.OPSTR_GET_USAGE_STATS,
            Process.myUid(),
            packageName
        )
        return mode == AppOpsManager.MODE_ALLOWED
    }

    private fun requestMissingPermissions() {
        if (!hasUsageStatsPermission()) {
            startActivity(Intent(Settings.ACTION_USAGE_ACCESS_SETTINGS))
            return
        }
        if (!Settings.canDrawOverlays(this)) {
            val intent = Intent(
                Settings.ACTION_MANAGE_OVERLAY_PERMISSION,
                Uri.parse("package:$packageName")
            )
            startActivity(intent)
        }
    }
}
