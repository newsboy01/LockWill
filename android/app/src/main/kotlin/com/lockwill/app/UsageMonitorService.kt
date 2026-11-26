package com.lockwill.app

import android.app.Service
import android.app.usage.UsageStatsManager
import android.content.Context
import android.content.Intent
import android.os.Handler
import android.os.IBinder
import android.os.Looper

/**
 * Foreground Service theo dõi app đang chạy trên màn hình qua UsageStatsManager.
 * Khi hết quỹ giờ và phát hiện trẻ mở app giải trí nằm trong danh sách chặn,
 * dịch vụ gọi LockOverlayManager để đưa màn hình LockWill lên trước.
 */
class UsageMonitorService : Service() {
    private val handler = Handler(Looper.getMainLooper())
    private var blockedPackages: Set<String> = emptySet()

    companion object {
        @Volatile
        private var unlockUntilMillis: Long = 0L

        fun grantMinutes(minutes: Int) {
            unlockUntilMillis = System.currentTimeMillis() + minutes * 60_000L
        }
    }

    private val checkRunnable = object : Runnable {
        override fun run() {
            checkForegroundApp()
            handler.postDelayed(this, 2000L)
        }
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        val list = intent?.getStringArrayListExtra("blockedPackages") ?: arrayListOf()
        blockedPackages = list.toSet()
        handler.removeCallbacks(checkRunnable)
        handler.post(checkRunnable)
        return START_STICKY
    }

    private fun checkForegroundApp() {
        if (System.currentTimeMillis() < unlockUntilMillis) return
        val topPkg = queryTopPackageName() ?: return
        if (topPkg != packageName && blockedPackages.contains(topPkg)) {
            LockOverlayManager.bringLockScreenToFront(this)
        }
    }

    private fun queryTopPackageName(): String? {
        val usm = getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager
        val end = System.currentTimeMillis()
        val stats = usm.queryUsageStats(UsageStatsManager.INTERVAL_DAILY, end - 10_000L, end)
        return stats?.maxByOrNull { it.lastTimeUsed }?.packageName
    }

    override fun onDestroy() {
        handler.removeCallbacks(checkRunnable)
        super.onDestroy()
    }

    override fun onBind(intent: Intent?): IBinder? = null
}
