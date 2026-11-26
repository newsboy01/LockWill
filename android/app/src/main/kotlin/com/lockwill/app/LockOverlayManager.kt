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
 * Hiển thị màn hình khóa phủ toàn màn hình (TYPE_APPLICATION_OVERLAY) thích ứng theo DPI (dp)
 * cho mọi kích thước điện thoại và máy tính bảng (Android 8-15, OPPO ColorOS, Xiaomi, Samsung).
 */
object LockOverlayManager {
    private val mainHandler = Handler(Looper.getMainLooper())
    private var overlayView: View? = null

    private fun Context.dp(value: Int): Int =
        (value * resources.displayMetrics.density).toInt()

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
                setPadding(appCtx.dp(24), appCtx.dp(24), appCtx.dp(24), appCtx.dp(24))
                isClickable = true
                isFocusable = true
            }

            val cardBg = GradientDrawable().apply {
                setColor(Color.WHITE)
                cornerRadius = appCtx.dp(24).toFloat()
            }

            val screenWidthPx = appCtx.resources.displayMetrics.widthPixels
            val maxCardWidth = minOf(screenWidthPx - appCtx.dp(40), appCtx.dp(440))

            val card = LinearLayout(appCtx).apply {
                orientation = LinearLayout.VERTICAL
                gravity = Gravity.CENTER
                background = cardBg
                setPadding(appCtx.dp(24), appCtx.dp(28), appCtx.dp(24), appCtx.dp(28))
                layoutParams = LinearLayout.LayoutParams(
                    maxCardWidth,
                    LinearLayout.LayoutParams.WRAP_CONTENT
                )
            }

            val owlEmoji = TextView(appCtx).apply {
                text = "🦉🔒"
                textSize = 56f
                gravity = Gravity.CENTER
            }

            val title = TextView(appCtx).apply {
                text = "Hết giờ giải trí rồi!"
                textSize = 24f
                setTypeface(null, Typeface.BOLD)
                setTextColor(Color.parseColor("#1E293B"))
                gravity = Gravity.CENTER
                setPadding(0, appCtx.dp(14), 0, appCtx.dp(8))
            }

            val subtitle = TextView(appCtx).apply {
                text = "Ứng dụng \"$blockedAppName\" đang bị LockWill khóa.\nHãy làm bài tập để nhận thêm thời gian nhé!"
                textSize = 16f
                setTextColor(Color.parseColor("#475569"))
                gravity = Gravity.CENTER
                setPadding(0, 0, 0, appCtx.dp(24))
            }

            val btnBg = GradientDrawable().apply {
                setColor(Color.parseColor("#FF8C42"))
                cornerRadius = appCtx.dp(20).toFloat()
            }

            val unlockBtn = Button(appCtx).apply {
                text = "Làm bài tập mở khóa ngay 🚀"
                textSize = 17f
                isAllCaps = false
                setTypeface(null, Typeface.BOLD)
                setTextColor(Color.WHITE)
                background = btnBg
                setPadding(appCtx.dp(24), appCtx.dp(14), appCtx.dp(24), appCtx.dp(14))
                layoutParams = LinearLayout.LayoutParams(
                    LinearLayout.LayoutParams.MATCH_PARENT,
                    LinearLayout.LayoutParams.WRAP_CONTENT
                )
                setOnClickListener {
                    hideOverlay(appCtx)
                    bringLockScreenToFront(appCtx)
                }
            }

            card.addView(owlEmoji)
            card.addView(title)
            card.addView(subtitle)
            card.addView(unlockBtn)
            root.addView(card)

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
