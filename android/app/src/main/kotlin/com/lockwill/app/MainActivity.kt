package com.lockwill.app

import android.Manifest
import android.app.AppOpsManager
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
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
                        UsageMonitorService.saveBlockedPackages(this, packages)
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
                        UsageMonitorService.lockNow(this)
                        LockOverlayManager.bringLockScreenToFront(this)
                        result.success(null)
                    }
                    "unlockForMinutes" -> {
                        val minutes = call.argument<Int>("minutes") ?: 15
                        UsageMonitorService.grantMinutes(this, minutes)
                        result.success(null)
                    }
                    "getInstalledApps" -> {
                        result.success(queryLaunchableApps())
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

    private fun queryLaunchableApps(): List<Map<String, String>> {
        val pm = packageManager
        val mainIntent = Intent(Intent.ACTION_MAIN, null).apply {
            addCategory(Intent.CATEGORY_LAUNCHER)
        }
        val resolveInfos = pm.queryIntentActivities(mainIntent, 0)
        val seen = HashSet<String>()
        val apps = ArrayList<Map<String, String>>()

        for (ri in resolveInfos) {
            val pkg = ri.activityInfo.packageName
            if (pkg == packageName || seen.contains(pkg)) continue
            seen.add(pkg)
            val label = ri.loadLabel(pm)?.toString() ?: pkg
            apps.add(mapOf("packageName" to pkg, "appName" to label))
        }
        apps.sortBy { it["appName"]?.lowercase() }
        return apps
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
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            if (checkSelfPermission(Manifest.permission.POST_NOTIFICATIONS) != PackageManager.PERMISSION_GRANTED) {
                requestPermissions(arrayOf(Manifest.permission.POST_NOTIFICATIONS), 2001)
            }
        }
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
