package com.example.brain_circle

import android.os.Build
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
                else -> result.notImplemented()
            }
        }
    }
}
