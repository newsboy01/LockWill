package com.lockwill.app

import android.app.admin.DeviceAdminReceiver
import android.content.Context
import android.content.Intent

/**
 * Device Admin Receiver giúp ngăn trẻ tự ý gỡ cài đặt ứng dụng LockWill
 * khi phụ huynh chưa tắt quyền quản trị thiết bị.
 */
class LockWillAdminReceiver : DeviceAdminReceiver() {
    override fun onDisableRequested(context: Context, intent: Intent): CharSequence {
        return "Cần có sự đồng ý của Phụ huynh trước khi tắt bảo vệ LockWill."
    }
}
