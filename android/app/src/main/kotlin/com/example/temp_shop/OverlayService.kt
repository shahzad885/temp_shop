// android/app/src/main/kotlin/com/example/temp_shop/OverlayService.kt
package com.example.temp_shop

import android.app.Service
import android.content.Intent
import android.graphics.PixelFormat
import android.os.IBinder
import android.view.Gravity
import android.view.LayoutInflater
import android.view.MotionEvent
import android.view.View
import android.view.WindowManager
import android.widget.Button
import android.widget.TextView

class OverlayService : Service() {

    private lateinit var windowManager: WindowManager
    private lateinit var overlayView: View
    private var screenshotId: String = ""

    companion object {
        const val EXTRA_SCREENSHOT_ID = "screenshot_id"
        const val ACTION_SET_EXPIRY = "com.example.temp_shop.SET_EXPIRY"
        const val EXTRA_DURATION_MINUTES = "duration_minutes"  // -1 = keep forever
    }

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onCreate() {
        super.onCreate()
        windowManager = getSystemService(WINDOW_SERVICE) as WindowManager
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        screenshotId = intent?.getStringExtra(EXTRA_SCREENSHOT_ID) ?: ""
        showOverlay()
        return START_NOT_STICKY
    }

    private fun showOverlay() {
        // Inflate a simple overlay layout built programmatically
        overlayView = buildOverlayView()

        val params = WindowManager.LayoutParams(
            WindowManager.LayoutParams.WRAP_CONTENT,
            WindowManager.LayoutParams.WRAP_CONTENT,
            WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY,
            WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE,
            PixelFormat.TRANSLUCENT
        ).apply {
            gravity = Gravity.BOTTOM or Gravity.CENTER_HORIZONTAL
            y = 200  // offset from bottom
        }

        windowManager.addView(overlayView, params)

        // Auto-dismiss after 15 seconds if user ignores it
        overlayView.postDelayed({ dismissOverlay() }, 15_000)
    }

    private fun buildOverlayView(): View {
        val container = android.widget.LinearLayout(this).apply {
            orientation = android.widget.LinearLayout.VERTICAL
            setPadding(24, 16, 24, 16)
            setBackgroundColor(0xE6141414.toInt())  // dark semi-transparent
            background = android.graphics.drawable.GradientDrawable().apply {
                setColor(0xE6141414.toInt())
                cornerRadius = 24f
            }
        }

        val label = TextView(this).apply {
            text = "📸 How long to keep this screenshot?"
            setTextColor(0xFFFFFFFF.toInt())
            textSize = 13f
            setPadding(0, 0, 0, 12)
        }
        container.addView(label)

        val buttonRow = android.widget.LinearLayout(this).apply {
            orientation = android.widget.LinearLayout.HORIZONTAL
        }

        val options = listOf(
            "5m" to 5,
            "30m" to 30,
            "1h" to 60,
            "24h" to 1440,
            "Keep" to -1
        )

        options.forEach { (label, minutes) ->
            val btn = Button(this).apply {
                text = label
                textSize = 11f
                setTextColor(if (minutes == -1) 0xFFFFFFFF.toInt() else 0xFFFFFFFF.toInt())
                setBackgroundColor(if (minutes == -1) 0xFF2A2A2A.toInt() else 0xFFE50914.toInt())
                background = android.graphics.drawable.GradientDrawable().apply {
                    setColor(if (minutes == -1) 0xFF2A2A2A.toInt() else 0xFFE50914.toInt())
                    cornerRadius = 20f
                }
                val lp = android.widget.LinearLayout.LayoutParams(
                    android.widget.LinearLayout.LayoutParams.WRAP_CONTENT,
                    android.widget.LinearLayout.LayoutParams.WRAP_CONTENT
                ).apply { setMargins(6, 0, 6, 0) }
                layoutParams = lp
                setPadding(20, 8, 20, 8)
                setOnClickListener {
                    sendExpiryToFlutter(minutes)
                    dismissOverlay()
                }
            }
            buttonRow.addView(btn)
        }

        container.addView(buttonRow)
        return container
    }

    private fun sendExpiryToFlutter(durationMinutes: Int) {
        // Broadcast to Flutter via a BroadcastReceiver registered in MainActivity
        val intent = Intent(ACTION_SET_EXPIRY).apply {
            putExtra(EXTRA_SCREENSHOT_ID, screenshotId)
            putExtra(EXTRA_DURATION_MINUTES, durationMinutes)
            setPackage(packageName)
        }
        sendBroadcast(intent)
    }

    private fun dismissOverlay() {
        try {
            if (overlayView.isAttachedToWindow) {
                windowManager.removeView(overlayView)
            }
        } catch (_: Exception) {}
        stopSelf()
    }

    override fun onDestroy() {
        dismissOverlay()
        super.onDestroy()
    }
}