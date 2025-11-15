import 'dart:async';
import 'package:flutter/foundation.dart';
import 'chronometer_notification.dart';

/// FocusTimer encapsulates a stopwatch-style timer using native chronometer notification.
///
/// It exposes two ValueNotifiers:
/// - elapsed: Duration since start (pauses when stopped)
/// - running: bool whether the timer is currently running
///
/// Features:
/// - Single timer running in main isolate
/// - Native Android chronometer notification (auto-increments on native side)
/// - No background service needed
/// - Notification updates only on state changes (play/pause/reset)
class FocusTimer {
  final ValueNotifier<Duration> elapsed = ValueNotifier(Duration.zero);
  final ValueNotifier<bool> running = ValueNotifier(false);

  Timer? _timer;
  bool _disposed = false;

  /// Start the timer. If already running, this does nothing.
  Future<void> start() async {
    if (running.value) return;
    _timer?.cancel();
    running.value = true;

    // Show running notification with native chronometer
    // The chronometer auto-increments on the native side without Dart loop
    await ChronometerNotification.showRunning(elapsed.value.inSeconds);

    // Single timer: increment local counter every second
    // The native chronometer display handles the visual increment independently
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!_disposed) {
        elapsed.value += const Duration(seconds: 1);
      }
    });
  }

  /// Pause the timer. Keeps elapsed value.
  Future<void> pause() async {
    if (!running.value) return;
    _timer?.cancel();
    running.value = false;

    // Show paused notification with static time (stops chronometer)
    await ChronometerNotification.showPaused(elapsed.value.inSeconds);
  }

  /// Toggle between start and pause.
  Future<void> toggle() async {
    if (running.value) {
      await pause();
    } else {
      await start();
    }
  }

  /// Reset elapsed to zero and hide notification.
  Future<void> reset() async {
    _timer?.cancel();
    running.value = false;
    elapsed.value = Duration.zero;
    await ChronometerNotification.cancel();
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
    _disposed = true;
    _timer?.cancel();
    elapsed.dispose();
    running.dispose();
  }
}
