package com.lockwill.app

import android.Manifest
import android.app.AppOpsManager
import android.app.admin.DevicePolicyManager
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.os.PowerManager
import android.os.Process
import android.provider.Settings
import androidx.core.content.FileProvider
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.net.HttpURLConnection
import java.net.URL

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
                    "requestDeviceAdmin" -> {
                        requestDeviceAdminPermission()
                        result.success(null)
                    }
                    "isDeviceAdminActive" -> {
                        result.success(isDeviceAdminEnabled())
                    }
                    "requestIgnoreBatteryOptimization" -> {
                        requestBatteryOptimizationExclusion()
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
                        LockOverlayManager.hideOverlay(this)
                        result.success(null)
                    }
                    "getRemainingUnlockSeconds" -> {
                        result.success(UsageMonitorService.getRemainingSeconds(this).toInt())
                    }
                    "launchApp" -> {
                        val pkg = call.argument<String>("packageName") ?: ""
                        val launchIntent = packageManager.getLaunchIntentForPackage(pkg)
                        if (launchIntent != null) {
                            launchIntent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                            startActivity(launchIntent)
                            result.success(true)
                        } else {
                            result.success(false)
                        }
                    }
                    "getUsageHistoryJson" -> {
                        result.success(UsageMonitorService.getUsageSummaryJson(this))
                    }
                    "getInstalledApps" -> {
                        result.success(queryLaunchableApps())
                    }
                    "getAppVersionCode" -> {
                        val pInfo = packageManager.getPackageInfo(packageName, 0)
                        val code = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
                            pInfo.longVersionCode.toInt()
                        } else {
                            @Suppress("DEPRECATION")
                            pInfo.versionCode
                        }
                        result.success(code)
                    }
                    "downloadAndInstallApk" -> {
                        val url = call.argument<String>("apkUrl") ?: ""
                        if (url.isEmpty()) {
                            result.success("Thiếu đường dẫn file APK.")
                        } else {
                            downloadAndInstallApk(url, result)
                        }
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

    private fun downloadAndInstallApk(apkUrl: String, result: MethodChannel.Result) {
        Thread {
            try {
                val outFile = File(cacheDir, "lockwill_update.apk")
                val conn = (URL(apkUrl).openConnection() as HttpURLConnection).apply {
                    instanceFollowRedirects = true
                    connectTimeout = 15000
                    readTimeout = 60000
                }
                conn.inputStream.use { input ->
                    outFile.outputStream().use { output ->
                        input.copyTo(output)
                    }
                }
                val apkUri = FileProvider.getUriForFile(
                    this,
                    "$packageName.fileprovider",
                    outFile
                )
                val installIntent = Intent(Intent.ACTION_VIEW).apply {
                    setDataAndType(apkUri, "application/vnd.android.package-archive")
                    addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_GRANT_READ_URI_PERMISSION)
                }
                runOnUiThread {
                    startActivity(installIntent)
                    result.success("OK: Đã tải xong! Hãy bấm Cài đặt/Cập nhật trên màn hình.")
                }
            } catch (e: Exception) {
                runOnUiThread {
                    result.success("Lỗi tải bản cập nhật: ${e.message}")
                }
            }
        }.start()
    }

    private fun isDeviceAdminEnabled(): Boolean {
        val dpm = getSystemService(Context.DEVICE_POLICY_SERVICE) as DevicePolicyManager
        val comp = ComponentName(this, LockWillAdminReceiver::class.java)
        return dpm.isAdminActive(comp)
    }

    private fun requestDeviceAdminPermission() {
        val comp = ComponentName(this, LockWillAdminReceiver::class.java)
        val intent = Intent(DevicePolicyManager.ACTION_ADD_DEVICE_ADMIN).apply {
            putExtra(DevicePolicyManager.EXTRA_DEVICE_ADMIN, comp)
            putExtra(
                DevicePolicyManager.EXTRA_ADD_EXPLANATION,
                "Bật quyền này giúp ngăn bé tự ý gỡ cài đặt ứng dụng LockWill."
            )
        }
        startActivity(intent)
    }

    private fun requestBatteryOptimizationExclusion() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            val pm = getSystemService(Context.POWER_SERVICE) as PowerManager
            if (!pm.isIgnoringBatteryOptimizations(packageName)) {
                val intent = Intent(
                    Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS,
                    Uri.parse("package:$packageName")
                )
                startActivity(intent)
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
