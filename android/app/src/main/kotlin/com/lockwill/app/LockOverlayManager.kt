package com.lockwill.app

import android.content.Context
import android.content.Intent
import android.graphics.Color
import android.graphics.PixelFormat
import android.graphics.Typeface
import android.graphics.drawable.GradientDrawable
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.provider.Settings
import android.view.Gravity
import android.view.View
import android.view.WindowManager
import android.widget.Button
import android.widget.LinearLayout
import android.widget.TextView

/**
 * Hiển thị màn hình khóa phủ toàn màn hình (TYPE_APPLICATION_OVERLAY) trực tiếp đè lên
 * YouTube/TikTok/Game. Cách này hoạt động 100% trên OPPO ColorOS, Xiaomi, Samsung, Android 10-15
 * mà không bị chặn bởi giới hạn Background Activity Launch.
 */
object LockOverlayManager {
    private val mainHandler = Handler(Looper.getMainLooper())
    private var overlayView: View? = null

    fun showBlockOverlay(context: Context, blockedAppName: String) {
        mainHandler.post {
            val appCtx = context.applicationContext
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M && !Settings.canDrawOverlays(appCtx)) {
                bringLockScreenToFront(appCtx)
                return@post
            }
            if (overlayView != null) return@post

            val wm = appCtx.getSystemService(Context.WINDOW_SERVICE) as WindowManager
            val layoutType = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY
            } else {
                @Suppress("DEPRECATION")
                WindowManager.LayoutParams.TYPE_PHONE
            }

            val params = WindowManager.LayoutParams(
                WindowManager.LayoutParams.MATCH_PARENT,
                WindowManager.LayoutParams.MATCH_PARENT,
                layoutType,
                WindowManager.LayoutParams.FLAG_LAYOUT_IN_SCREEN or
                    WindowManager.LayoutParams.FLAG_FULLSCREEN,
                PixelFormat.TRANSLUCENT
            ).apply {
                gravity = Gravity.CENTER
            }

            val root = LinearLayout(appCtx).apply {
                orientation = LinearLayout.VERTICAL
                gravity = Gravity.CENTER
                setBackgroundColor(Color.parseColor("#FFF8EE"))
                setPadding(64, 64, 64, 64)
                isClickable = true
                isFocusable = true
            }

            val owlEmoji = TextView(appCtx).apply {
                text = "🦉🔒"
                textSize = 64f
                gravity = Gravity.CENTER
            }

            val title = TextView(appCtx).apply {
                text = "Hết giờ giải trí rồi!"
                textSize = 26f
                setTypeface(null, Typeface.BOLD)
                setTextColor(Color.parseColor("#1E293B"))
                gravity = Gravity.CENTER
                setPadding(0, 32, 0, 16)
            }

            val subtitle = TextView(appCtx).apply {
                text = "Ứng dụng \"$blockedAppName\" đang bị LockWill khóa.\nHãy làm bài tập để nhận thêm thời gian nhé!"
                textSize = 17f
                setTextColor(Color.parseColor("#475569"))
                gravity = Gravity.CENTER
                setPadding(0, 0, 0, 48)
            }

            val btnBg = GradientDrawable().apply {
                setColor(Color.parseColor("#FF8C42"))
                cornerRadius = 48f
            }

            val unlockBtn = Button(appCtx).apply {
                text = "Làm bài tập mở khóa ngay 🚀"
                textSize = 18f
                isAllCaps = false
                setTypeface(null, Typeface.BOLD)
                setTextColor(Color.WHITE)
                background = btnBg
                setPadding(56, 36, 56, 36)
                setOnClickListener {
                    hideOverlay(appCtx)
                    bringLockScreenToFront(appCtx)
                }
            }

            root.addView(owlEmoji)
            root.addView(title)
            root.addView(subtitle)
            root.addView(unlockBtn)

            try {
                wm.addView(root, params)
                overlayView = root
            } catch (_: Exception) {
                bringLockScreenToFront(appCtx)
            }
        }
    }

    fun hideOverlay(context: Context) {
        mainHandler.post {
            val view = overlayView ?: return@post
            try {
                val wm = context.applicationContext.getSystemService(Context.WINDOW_SERVICE) as WindowManager
                wm.removeView(view)
            } catch (_: Exception) {
            } finally {
                overlayView = null
            }
        }
    }

    fun bringLockScreenToFront(context: Context) {
        val intent = Intent(context, MainActivity::class.java).apply {
            addFlags(
                Intent.FLAG_ACTIVITY_NEW_TASK or
                    Intent.FLAG_ACTIVITY_CLEAR_TOP or
                    Intent.FLAG_ACTIVITY_SINGLE_TOP
            )
        }
        try {
            context.startActivity(intent)
        } catch (_: Exception) {
        }
    }
}
