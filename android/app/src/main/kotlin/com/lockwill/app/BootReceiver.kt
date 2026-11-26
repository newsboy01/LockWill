package com.lockwill.app

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build

/**
 * Tự động khởi chạy lại UsageMonitorService ngay khi điện thoại/tablet khởi động lại.
 */
class BootReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action == Intent.ACTION_BOOT_COMPLETED) {
            val blocked = UsageMonitorService.loadBlockedPackages(context)
            if (blocked.isNotEmpty()) {
                val serviceIntent = Intent(context, UsageMonitorService::class.java).apply {
                    putStringArrayListExtra("blockedPackages", ArrayList(blocked))
                }
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                    context.startForegroundService(serviceIntent)
                } else {
                    context.startService(serviceIntent)
                }
            }
        }
    }
}
