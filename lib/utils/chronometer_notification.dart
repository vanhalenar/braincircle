import 'package:flutter/services.dart';

/// Dart wrapper for native Android chronometer notification.
/// Shows a live increasing timer without requiring a background service.
class ChronometerNotification {
  static const _channel = MethodChannel('com.example.brain_circle/timer');

  static Function(String action)? _onTimerAction;

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

  /// The notification will display an increasing timer
  static Future<void> showRunning(int elapsedSeconds) async {
    try {
      await _channel.invokeMethod('showRunningTimer', {
        'elapsedSeconds': elapsedSeconds,
      });
    } catch (e) {
      print('[ChronometerNotification] Error showing running timer: $e');
    }
  }

  /// Stops the chronometer and displays the elapsed time as static text.
  static Future<void> showPaused(int elapsedSeconds) async {
    try {
      await _channel.invokeMethod('showPausedTimer', {
        'elapsedSeconds': elapsedSeconds,
      });
    } catch (e) {
      print('[ChronometerNotification] Error showing paused timer: $e');
    }
  }

  static Future<void> cancel() async {
    try {
      await _channel.invokeMethod('cancelNotification');
    } catch (e) {
      print('[ChronometerNotification] Error canceling notification: $e');
    }
  }

  static Future<bool> isScreenLockedOrOff() async {
    try {
      final res = await _channel.invokeMethod('isScreenLockedOrOff');
      return res == true;
    } catch (e) {
      print('[ChronometerNotification] Error checking screen state: $e');
      return false;
    }
  }
}
