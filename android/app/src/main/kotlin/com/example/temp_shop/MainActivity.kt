// android/app/src/main/kotlin/com/example/temp_shop/MainActivity.kt
package com.example.temp_shop

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    private val overlayChannel = "com.example.temp_shop/overlay"
    private val expiryChannel  = "com.example.temp_shop/expiry"
    private var expiryMethodChannel: MethodChannel? = null

    // Receives broadcasts from OverlayService when user taps a time button
    private val expiryReceiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context?, intent: Intent?) {
            if (intent?.action != OverlayService.ACTION_SET_EXPIRY) return
            val screenshotId  = intent.getStringExtra(OverlayService.EXTRA_SCREENSHOT_ID) ?: return
            val durationMins  = intent.getIntExtra(OverlayService.EXTRA_DURATION_MINUTES, -1)

            // Forward to Flutter via MethodChannel
            expiryMethodChannel?.invokeMethod("onExpirySelected", mapOf(
                "screenshotId"    to screenshotId,
                "durationMinutes" to durationMins
            ))
        }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        // Register broadcast receiver
        val filter = IntentFilter(OverlayService.ACTION_SET_EXPIRY)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            registerReceiver(expiryReceiver, filter, RECEIVER_NOT_EXPORTED)
        } else {
            registerReceiver(expiryReceiver, filter)
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // Channel 1: Flutter asks to show overlay / check permission
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, overlayChannel)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "hasOverlayPermission" -> {
                        result.success(
                            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M)
                                Settings.canDrawOverlays(this)
                            else true
                        )
                    }
                    "requestOverlayPermission" -> {
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                            val intent = Intent(
                                Settings.ACTION_MANAGE_OVERLAY_PERMISSION,
                                Uri.parse("package:$packageName")
                            )
                            startActivity(intent)
                        }
                        result.success(null)
                    }
                    "showOverlay" -> {
                        val screenshotId = call.argument<String>("screenshotId") ?: ""
                        val serviceIntent = Intent(this, OverlayService::class.java).apply {
                            putExtra(OverlayService.EXTRA_SCREENSHOT_ID, screenshotId)
                        }
                        startService(serviceIntent)
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }

        // Channel 2: Sends expiry selection back to Flutter
        expiryMethodChannel = MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger, expiryChannel
        )
    }

    override fun onDestroy() {
        unregisterReceiver(expiryReceiver)
        super.onDestroy()
    }
}