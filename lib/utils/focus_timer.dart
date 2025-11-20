import 'dart:async';
import 'package:flutter/foundation.dart';
import 'chronometer_notification.dart';


class FocusTimer {
  FocusTimer._();
  static final FocusTimer instance = FocusTimer._();

  final ValueNotifier<Duration> elapsed = ValueNotifier(Duration.zero);
  final ValueNotifier<bool> running = ValueNotifier(false);

  Timer? _timer;
  bool _disposed = false;

  Future<void> start() async {
    if (running.value) return;
    _timer?.cancel();
    running.value = true;

    await ChronometerNotification.showRunning(elapsed.value.inSeconds);

    // Single timer: increment local counter every second
    // The native chronometer display handles the visual increment independently
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!_disposed) {
        elapsed.value += const Duration(seconds: 1);
      }
    });
  }

  Future<void> pause() async {
    if (!running.value) return;
    _timer?.cancel();
    running.value = false;

    await ChronometerNotification.showPaused(elapsed.value.inSeconds);
  }

  Future<void> toggle() async {
    if (running.value) {
      await pause();
    } else {
      await start();
    }
  }

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
  
  void setInitialDuration(Duration d) {
    elapsed.value = d;
  }

  void dispose() {
    _disposed = true;
    _timer?.cancel();
    elapsed.dispose();
    running.dispose();
  }
}
