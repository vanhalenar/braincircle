package com.example.brain_circle

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.content.BroadcastReceiver
import android.os.Build
import androidx.core.app.NotificationCompat

class TimerNotificationManager(private val context: Context) {
    companion object {
        private const val CHANNEL_ID = "timer_channel"
        private const val NOTIFICATION_ID = 42
    }

    private val notificationManager =
        context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager

    init {
        createNotificationChannel()
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                "Focus Timer",
                NotificationManager.IMPORTANCE_LOW
            ).apply {
                description = "Focus timer notifications"
            }
            notificationManager.createNotificationChannel(channel)
        }
    }

    fun showRunningTimer(elapsedSeconds: Int) {
        val baseTime = System.currentTimeMillis() - (elapsedSeconds * 1000L)
        
        val playPauseIntent = Intent(context, TimerActionReceiver::class.java).apply {
            action = "TIMER_PAUSE"
        }
        val playPausePendingIntent = PendingIntent.getBroadcast(
            context,
            1,
            playPauseIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        val resetIntent = Intent(context, TimerActionReceiver::class.java).apply {
            action = "TIMER_RESET"
        }
        val resetPendingIntent = PendingIntent.getBroadcast(
            context,
            2,
            resetIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        val notification = NotificationCompat.Builder(context, CHANNEL_ID)
            .setContentTitle("Studying!")
            .setContentText("Timer running")
            .setSmallIcon(android.R.drawable.ic_dialog_info)
            .setWhen(baseTime)
            .setUsesChronometer(true)
            .setOngoing(true)
            .setAutoCancel(false)
            .build()

        notificationManager.notify(NOTIFICATION_ID, notification)
    }

    fun showPausedTimer(elapsedSeconds: Int) {
        val playIntent = Intent(context, TimerActionReceiver::class.java).apply {
            action = "TIMER_PLAY"
        }
        val playPendingIntent = PendingIntent.getBroadcast(
            context,
            1,
            playIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        val resetIntent = Intent(context, TimerActionReceiver::class.java).apply {
            action = "TIMER_RESET"
        }
        val resetPendingIntent = PendingIntent.getBroadcast(
            context,
            2,
            resetIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        val notification = NotificationCompat.Builder(context, CHANNEL_ID)
            .setContentTitle("Chilling!")
            .setContentText("Timer paused - ${formatTime(elapsedSeconds)}")
            .setSmallIcon(android.R.drawable.ic_dialog_info)
            .setUsesChronometer(false)
            .setOngoing(false)
            .setAutoCancel(true)
            .build()

        notificationManager.notify(NOTIFICATION_ID, notification)
    }

    fun cancelNotification() {
        notificationManager.cancel(NOTIFICATION_ID)
    }

    private fun formatTime(seconds: Int): String {
        val h = seconds / 3600
        val m = (seconds % 3600) / 60
        val s = seconds % 60
        return String.format("%02d:%02d:%02d", h, m, s)
    }
}

class TimerActionReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        val action = intent.action
        when (action) {
            "TIMER_PLAY" -> {
                MainActivity.timerChannel?.invokeMethod("onTimerAction", mapOf("action" to "play"))
            }
            "TIMER_PAUSE" -> {
                MainActivity.timerChannel?.invokeMethod("onTimerAction", mapOf("action" to "pause"))
            }
            "TIMER_RESET" -> {
                MainActivity.timerChannel?.invokeMethod("onTimerAction", mapOf("action" to "reset"))
            }
        }
    }
}
