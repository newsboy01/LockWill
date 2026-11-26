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

/**
 * Foreground Service bền bỉ theo dõi ứng dụng đang mở qua UsageStatsManager.
 * - Có Notification cố định hiển thị trạng thái khóa / thời gian còn lại.
 * - Lưu danh sách app bị chặn và hạn mở khóa vào SharedPreferences để không mất khi restart.
 * - Khi hết giờ mà trẻ mở app nằm trong danh sách khóa, tự kéo màn hình LockWill đè lên ngay.
 */
class UsageMonitorService : Service() {
    private val handler = Handler(Looper.getMainLooper())
    private var blockedPackages: Set<String> = emptySet()
    private var lastNotificationText: String = ""

    companion object {
        const val PREFS_NAME = "lockwill_native_prefs"
        const val KEY_BLOCKED_PACKAGES = "blocked_packages"
        const val KEY_UNLOCK_UNTIL = "unlock_until_millis"
        private const val CHANNEL_ID = "lockwill_monitor_channel"
        private const val NOTIFICATION_ID = 1001

        fun saveBlockedPackages(context: Context, packages: List<String>) {
            val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            prefs.edit().putStringSet(KEY_BLOCKED_PACKAGES, packages.toSet()).apply()
        }

        fun loadBlockedPackages(context: Context): Set<String> {
            val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            return prefs.getStringSet(KEY_BLOCKED_PACKAGES, emptySet()) ?: emptySet()
        }

        fun grantMinutes(context: Context, minutes: Int) {
            val until = System.currentTimeMillis() + minutes * 60_000L
            val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            prefs.edit().putLong(KEY_UNLOCK_UNTIL, until).apply()
        }

        fun lockNow(context: Context) {
            val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            prefs.edit().putLong(KEY_UNLOCK_UNTIL, 0L).apply()
        }

        fun getUnlockUntil(context: Context): Long {
            val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            return prefs.getLong(KEY_UNLOCK_UNTIL, 0L)
        }
    }

    private val checkRunnable = object : Runnable {
        override fun run() {
            checkForegroundApp()
            handler.postDelayed(this, 1200L)
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

        updateNotificationStatus()
        handler.removeCallbacks(checkRunnable)
        handler.post(checkRunnable)
        return START_STICKY
    }

    private fun checkForegroundApp() {
        val now = System.currentTimeMillis()
        val unlockUntil = getUnlockUntil(this)
        updateNotificationStatus()

        if (now < unlockUntil) return
        if (blockedPackages.isEmpty()) return

        val topPkg = queryTopPackageName() ?: return
        if (topPkg != packageName && blockedPackages.contains(topPkg)) {
            LockOverlayManager.bringLockScreenToFront(this)
        }
    }

    private fun queryTopPackageName(): String? {
        val usm = getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager
        val end = System.currentTimeMillis()
        val start = end - 10_000L

        // Ưu tiên UsageEvents (chính xác theo thời gian thực khi vừa chuyển app).
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

        // Fallback dùng queryUsageStats nếu không có sự kiện chuyển app trong 10 giây qua.
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
        val remainingMs = getUnlockUntil(this) - System.currentTimeMillis()
        val text = if (remainingMs > 0) {
            val mins = ((remainingMs + 59_999L) / 60_000L).toInt()
            "⏳ Còn lại ~$mins phút giải trí (Đang giám sát ${blockedPackages.size} app)"
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
