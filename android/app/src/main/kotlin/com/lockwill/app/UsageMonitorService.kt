package com.lockwill.app

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.app.usage.UsageEvents
import android.app.usage.UsageStatsManager
import android.content.Context
import android.content.Intent
import android.content.pm.ServiceInfo
import android.os.Build
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import android.os.PowerManager
import org.json.JSONArray
import org.json.JSONObject
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

/**
 * Foreground Service lõi của LockWill:
 * 1. Active Usage Timer: Chỉ trừ giây khi màn hình đang bật VÀ bé thực sự mở app bị giám sát.
 * 2. App Usage Tracker: Ghi nhận đầy đủ bé đang mở app gì, mở lúc nào, tổng thời gian bao lâu cho từng app.
 * 3. Instant App Lock: Khi hết quỹ giây, lập tức kéo màn hình LockWill đè lên app bị chặn.
 */
class UsageMonitorService : Service() {
    private val handler = Handler(Looper.getMainLooper())
    private var blockedPackages: Set<String> = emptySet()
    private var lastNotificationText: String = ""
    private var lastTickMillis: Long = System.currentTimeMillis()

    companion object {
        const val PREFS_NAME = "lockwill_native_prefs"
        const val KEY_BLOCKED_PACKAGES = "blocked_packages"
        const val KEY_REMAINING_SECONDS = "remaining_unlock_seconds"
        const val KEY_USAGE_LOG_JSON = "daily_app_usage_json"
        const val KEY_USAGE_DATE = "daily_app_usage_date"
        const val KEY_CURRENT_APP = "current_active_app"
        const val KEY_CURRENT_APP_TIME = "current_active_time"
        private const val CHANNEL_ID = "lockwill_monitor_channel"
        private const val NOTIFICATION_ID = 1001

        fun todayDateStr(): String {
            return SimpleDateFormat("yyyy-MM-dd", Locale.US).format(Date())
        }

        fun saveBlockedPackages(context: Context, packages: List<String>) {
            val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            prefs.edit().putStringSet(KEY_BLOCKED_PACKAGES, packages.toSet()).apply()
        }

        fun loadBlockedPackages(context: Context): Set<String> {
            val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            return prefs.getStringSet(KEY_BLOCKED_PACKAGES, emptySet()) ?: emptySet()
        }

        fun grantMinutes(context: Context, minutes: Int) {
            val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            val current = prefs.getLong(KEY_REMAINING_SECONDS, 0L).coerceAtLeast(0L)
            prefs.edit().putLong(KEY_REMAINING_SECONDS, current + minutes * 60L).apply()
        }

        fun lockNow(context: Context) {
            val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            prefs.edit().putLong(KEY_REMAINING_SECONDS, 0L).apply()
        }

        fun getRemainingSeconds(context: Context): Long {
            val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            return prefs.getLong(KEY_REMAINING_SECONDS, 0L).coerceAtLeast(0L)
        }

        fun getUsageSummaryJson(context: Context): String {
            val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            val today = todayDateStr()
            val savedDate = prefs.getString(KEY_USAGE_DATE, "")
            val usageObj = if (savedDate == today) {
                try {
                    JSONObject(prefs.getString(KEY_USAGE_LOG_JSON, "{}") ?: "{}")
                } catch (_: Exception) {
                    JSONObject()
                }
            } else {
                JSONObject()
            }

            val appsArray = JSONArray()
            val keys = usageObj.keys()
            while (keys.hasNext()) {
                val pkg = keys.next()
                val item = usageObj.optJSONObject(pkg) ?: continue
                appsArray.put(item)
            }

            val root = JSONObject().apply {
                put("date", today)
                put("remainingSeconds", getRemainingSeconds(context))
                put("currentApp", prefs.getString(KEY_CURRENT_APP, "LockWill") ?: "LockWill")
                put("currentAppUpdatedAt", prefs.getString(KEY_CURRENT_APP_TIME, "") ?: "")
                put("apps", appsArray)
            }
            return root.toString()
        }
    }

    private val checkRunnable = object : Runnable {
        override fun run() {
            val now = System.currentTimeMillis()
            val elapsedSec = ((now - lastTickMillis) / 1000L).coerceIn(1L, 5L)
            lastTickMillis = now

            tickMonitor(elapsedSec)
            handler.postDelayed(this, 1500L)
        }
    }

    override fun onCreate() {
        super.onCreate()
        createNotificationChannel()
        startAsForeground("Đang bảo vệ thời gian học tập của bé...")
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        val list = intent?.getStringArrayListExtra("blockedPackages")
        if (list != null) {
            saveBlockedPackages(this, list)
            blockedPackages = list.toSet()
        } else {
            blockedPackages = loadBlockedPackages(this)
        }

        lastTickMillis = System.currentTimeMillis()
        updateNotificationStatus()
        handler.removeCallbacks(checkRunnable)
        handler.post(checkRunnable)
        return START_STICKY
    }

    private fun tickMonitor(elapsedSec: Long) {
        val pm = getSystemService(Context.POWER_SERVICE) as PowerManager
        if (!pm.isInteractive) {
            // Màn hình đang tắt -> Bảo lưu thời gian giải trí của bé, không trừ!
            return
        }

        val topPkg = queryTopPackageName() ?: return
        val appLabel = resolveAppLabel(topPkg)
        recordAppUsage(topPkg, appLabel, elapsedSec)

        if (topPkg != packageName && blockedPackages.contains(topPkg)) {
            val remaining = getRemainingSeconds(this)
            if (remaining > 0L) {
                val nextRemaining = (remaining - elapsedSec).coerceAtLeast(0L)
                val prefs = getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
                prefs.edit().putLong(KEY_REMAINING_SECONDS, nextRemaining).apply()
                if (nextRemaining <= 0L) {
                    LockOverlayManager.bringLockScreenToFront(this)
                }
            } else {
                LockOverlayManager.bringLockScreenToFront(this)
            }
        }

        updateNotificationStatus()
    }

    private fun recordAppUsage(pkg: String, appName: String, elapsedSec: Long) {
        val prefs = getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        val today = todayDateStr()
        val savedDate = prefs.getString(KEY_USAGE_DATE, "")
        val usageObj = if (savedDate == today) {
            try {
                JSONObject(prefs.getString(KEY_USAGE_LOG_JSON, "{}") ?: "{}")
            } catch (_: Exception) {
                JSONObject()
            }
        } else {
            JSONObject()
        }

        val nowIso = SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss", Locale.US).format(Date())
        val entry = usageObj.optJSONObject(pkg) ?: JSONObject().apply {
            put("packageName", pkg)
            put("appName", appName)
            put("seconds", 0L)
            put("isBlockedApp", blockedPackages.contains(pkg))
        }
        entry.put("appName", appName)
        entry.put("seconds", entry.optLong("seconds", 0L) + elapsedSec)
        entry.put("lastUsedAt", nowIso)
        entry.put("isBlockedApp", blockedPackages.contains(pkg))
        usageObj.put(pkg, entry)

        prefs.edit()
            .putString(KEY_USAGE_DATE, today)
            .putString(KEY_USAGE_LOG_JSON, usageObj.toString())
            .putString(KEY_CURRENT_APP, appName)
            .putString(KEY_CURRENT_APP_TIME, nowIso)
            .apply()
    }

    private fun resolveAppLabel(pkg: String): String {
        return try {
            val ai = packageManager.getApplicationInfo(pkg, 0)
            packageManager.getApplicationLabel(ai).toString()
        } catch (_: Exception) {
            pkg
        }
    }

    private fun queryTopPackageName(): String? {
        val usm = getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager
        val end = System.currentTimeMillis()
        val start = end - 10_000L

        val events = usm.queryEvents(start, end)
        val event = UsageEvents.Event()
        var lastResumedPkg: String? = null
        while (events.hasNextEvent()) {
            events.getNextEvent(event)
            if (event.eventType == UsageEvents.Event.ACTIVITY_RESUMED ||
                event.eventType == UsageEvents.Event.MOVE_TO_FOREGROUND
            ) {
                lastResumedPkg = event.packageName
            }
        }
        if (lastResumedPkg != null) return lastResumedPkg

        val stats = usm.queryUsageStats(UsageStatsManager.INTERVAL_DAILY, end - 60_000L, end)
        return stats?.maxByOrNull { it.lastTimeUsed }?.packageName
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                "LockWill Giám sát thời gian",
                NotificationManager.IMPORTANCE_LOW
            ).apply {
                description = "Hiển thị trạng thái khóa ứng dụng và thời gian giải trí còn lại"
            }
            val nm = getSystemService(NotificationManager::class.java)
            nm.createNotificationChannel(channel)
        }
    }

    private fun buildNotification(text: String): Notification {
        val openIntent = Intent(this, MainActivity::class.java)
        val pendingFlags = PendingIntent.FLAG_UPDATE_CURRENT or
            (if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) PendingIntent.FLAG_IMMUTABLE else 0)
        val pendingIntent = PendingIntent.getActivity(this, 0, openIntent, pendingFlags)

        val builder = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            Notification.Builder(this, CHANNEL_ID)
        } else {
            @Suppress("DEPRECATION")
            Notification.Builder(this)
        }

        return builder
            .setContentTitle("LockWill đang bảo vệ bé")
            .setContentText(text)
            .setSmallIcon(android.R.drawable.ic_lock_idle_lock)
            .setOngoing(true)
            .setContentIntent(pendingIntent)
            .build()
    }

    private fun startAsForeground(text: String) {
        lastNotificationText = text
        val notification = buildNotification(text)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
            startForeground(
                NOTIFICATION_ID,
                notification,
                ServiceInfo.FOREGROUND_SERVICE_TYPE_SPECIAL_USE
            )
        } else {
            startForeground(NOTIFICATION_ID, notification)
        }
    }

    private fun updateNotificationStatus() {
        val remSec = getRemainingSeconds(this)
        val text = if (remSec > 0L) {
            val mins = ((remSec + 59L) / 60L).toInt()
            "⏳ Còn lại ~$mins phút dùng app giải trí (Bảo lưu khi tắt màn hình)"
        } else {
            "🔒 Đang khóa ${blockedPackages.size} app giải trí — Làm bài để mở thêm giờ"
        }

        if (text != lastNotificationText) {
            lastNotificationText = text
            val nm = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            nm.notify(NOTIFICATION_ID, buildNotification(text))
        }
    }

    override fun onDestroy() {
        handler.removeCallbacks(checkRunnable)
        super.onDestroy()
    }

    override fun onBind(intent: Intent?): IBinder? = null
}
