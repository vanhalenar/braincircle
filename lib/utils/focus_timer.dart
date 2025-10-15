import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';


/// FocusTimer encapsulates a simple stopwatch-style timer.
///
/// It exposes two ValueNotifiers:
/// - elapsed: Duration since start (pauses when stopped)
/// - running: bool whether the timer is currently running
class FocusTimer {
  final ValueNotifier<Duration> elapsed = ValueNotifier(Duration.zero);
  final ValueNotifier<bool> running = ValueNotifier(false);

  Timer? _timer;

  /// Start the timer. If already running, this does nothing.
  void start() {
    if (running.value) return;
    // NOTE: start the foreground service/task here so the notification keeps
    // updating while the app is backgrounded. Example (depends on plugin API):
    if (Platform.isAndroid) {
      try {
        FlutterForegroundTask.startService(
          notificationTitle: 'Focus timer running',
          notificationText: formatDuration(elapsed.value),
        );
      } catch (e) {
        // If the plugin isn't available (MissingPluginException) we'll still
        // update the UI while the app is foregrounded. The catch prevents the
        // app from pausing on the exception.
        debugPrint('Foreground start failed: $e');
      }
    }
    // For now, we start a local timer to update UI while app is foregrounded.
    _timer = Timer.periodic(const Duration(seconds: 1), (_) async {
      elapsed.value += const Duration(seconds: 1);

      // Update notification with current elapsed time.
      if (Platform.isAndroid) {
        try {
          await FlutterForegroundTask.updateService(
            notificationTitle: 'Focus timer running',
            notificationText: formatDuration(elapsed.value),
          );
        } catch (e) {
          debugPrint('Foreground update failed: $e');
        }
      }
    });

    running.value = true;
  }

  /// Pause the timer. Keeps elapsed value.
  void pause() {
    if (!running.value) return;
    // NOTE: stop the foreground service/task here so background notification
    // updates stop. Example (depends on plugin API):
    if (Platform.isAndroid) {
      try {
        FlutterForegroundTask.stopService();
      } catch (e) {
        debugPrint('Foreground stop failed: $e');
      }
    }

    _timer?.cancel();
    _timer = null;
    running.value = false;
  }

  /// Toggle between start and pause.
  void toggle() {
    if (running.value) {
      pause();
    } else {
      start();
    }
  }

  /// Reset elapsed to zero. Does not change running state.
  void reset() {
    elapsed.value = Duration.zero;
  }

  String formatDuration(Duration d) {
    String two(int n) => n.toString().padLeft(2, '0');
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    final s = d.inSeconds.remainder(60);
    return "${two(h)}:${two(m)}:${two(s)}";
  }

  /// Dispose internal resources.
  void dispose() {
    _timer?.cancel();
    elapsed.dispose();
    running.dispose();
  }
}
