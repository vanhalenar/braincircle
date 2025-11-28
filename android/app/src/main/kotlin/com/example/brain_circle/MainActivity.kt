package com.example.brain_circle

import android.app.KeyguardManager
import android.content.Context
import android.os.Build
import android.os.PowerManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    companion object {
        const val TIMER_CHANNEL = "com.example.brain_circle/timer"
        var timerChannel: MethodChannel? = null
    }

    private lateinit var notificationManager: TimerNotificationManager

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        notificationManager = TimerNotificationManager(this)

        timerChannel = MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            TIMER_CHANNEL
        )

        timerChannel?.setMethodCallHandler { call, result ->
            when (call.method) {
                "showRunningTimer" -> {
                    val elapsedSeconds = call.argument<Int>("elapsedSeconds") ?: 0
                    notificationManager.showRunningTimer(elapsedSeconds)
                    result.success(null)
                }
                "showPausedTimer" -> {
                    val elapsedSeconds = call.argument<Int>("elapsedSeconds") ?: 0
                    notificationManager.showPausedTimer(elapsedSeconds)
                    result.success(null)
                }
                "cancelNotification" -> {
                    notificationManager.cancelNotification()
                    result.success(null)
                }
                "isScreenLockedOrOff" -> {
                    // Determine if screen is off or device is locked
                    val pm = getSystemService(Context.POWER_SERVICE) as PowerManager
                    val isInteractive = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.KITKAT_WATCH) {
                        pm.isInteractive
                    } else {
                        @Suppress("DEPRECATION")
                        pm.isScreenOn
                    }

                    val km = getSystemService(Context.KEYGUARD_SERVICE) as KeyguardManager
                    val isLocked = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
                        km.isKeyguardLocked
                    } else {
                        km.inKeyguardRestrictedInputMode()
                    }

                    // If screen is NOT interactive (off) OR keyguard is locked -> treat as locked/off
                    val lockedOrOff = (!isInteractive) || isLocked
                    result.success(lockedOrOff)
                }
                else -> result.notImplemented()
            }
        }
    }
}
