import 'dart:async';
import 'package:flutter/foundation.dart';

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
    // Tick every second
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      elapsed.value = elapsed.value + const Duration(seconds: 1);
    });
    running.value = true;
  }

  /// Pause the timer. Keeps elapsed value.
  void pause() {
    if (!running.value) return;
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
