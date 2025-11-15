import 'package:flutter/services.dart';

/// Dart wrapper for native Android chronometer notification.
/// Shows a live increasing timer without requiring a background service.
class ChronometerNotification {
  static const _channel = MethodChannel('com.example.brain_circle/timer');

  static Function(String action)? _onTimerAction;

  /// Initialize the notification handler (call this once in main()).
  static Future<void> initialize(Function(String action) onAction) async {
    _onTimerAction = onAction;
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'onTimerAction') {
        final action = call.arguments['action'] as String?;
        if (action != null) {
          _onTimerAction?.call(action);
        }
      }
    });
  }

  /// Show a running timer notification with chronometer.
  /// The notification will display an increasing timer without any Dart code running.
  /// [elapsedSeconds] is the starting point for the chronometer.
  static Future<void> showRunning(int elapsedSeconds) async {
    try {
      await _channel.invokeMethod('showRunningTimer', {
        'elapsedSeconds': elapsedSeconds,
      });
    } catch (e) {
      print('Error showing running timer: $e');
    }
  }

  /// Show a paused timer notification.
  /// Stops the chronometer and displays the elapsed time as static text.
  /// [elapsedSeconds] is the total elapsed time to display.
  static Future<void> showPaused(int elapsedSeconds) async {
    try {
      await _channel.invokeMethod('showPausedTimer', {
        'elapsedSeconds': elapsedSeconds,
      });
    } catch (e) {
      print('Error showing paused timer: $e');
    }
  }

  /// Cancel and remove the notification.
  static Future<void> cancel() async {
    try {
      await _channel.invokeMethod('cancelNotification');
    } catch (e) {
      print('Error canceling notification: $e');
    }
  }
}
