import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';

/// FocusTimer encapsulates a stopwatch that uses the foreground task as the
/// authoritative timer on Android. The UI listens to messages from the
/// background isolate (via `FlutterForegroundTask.receivePort`) and updates
/// its state accordingly. On non-Android platforms we fall back to a local
/// Timer.
class FocusTimer {
  final ValueNotifier<Duration> elapsed = ValueNotifier(Duration.zero);
  final ValueNotifier<bool> running = ValueNotifier(false);

  Timer? _localTimer;
  StreamSubscription? _receiveSub;

  String _two(int n) => n.toString().padLeft(2, '0');

  String formatDuration(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    final s = d.inSeconds.remainder(60);
    return '${_two(h)}:${_two(m)}:${_two(s)}';
  }

  /// Start the timer. If already running, this does nothing.
  Future<void> start() async {
    if (running.value) return;

    if (Platform.isAndroid) {
      try {
        // first register receive port so background handler can find our SendPort
        final rp = FlutterForegroundTask.receivePort;
        _receiveSub = rp?.listen((message) {
          if (message is Map && message['type'] == 'tick') {
            final int seconds = message['elapsed'] ?? 0;
            final bool runningFlag = message['running'] ?? true;
            elapsed.value = Duration(seconds: seconds);
            running.value = runningFlag;
          }
          debugPrint('ReceivePort: $rp');

        });

        // Tell background handler to run
        await FlutterForegroundTask.saveData(key: 'command', value: 'play');
        await FlutterForegroundTask.startService(
          notificationTitle: 'Focus timer running',
          notificationText: formatDuration(elapsed.value),
        );
        debugPrint('************************Foreground service started successfully');

        // Mark running true (background will also send ticks)
        running.value = true;
      } catch (e) {
        debugPrint('Foreground start failed, falling back to local timer: $e');
        // fallback to local timer
        _localTimer = Timer.periodic(const Duration(seconds: 1), (_) {
          elapsed.value = elapsed.value + const Duration(seconds: 1);
        });
        running.value = true;
      }
    } else {
      // Non-Android fallback
      _localTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        elapsed.value = elapsed.value + const Duration(seconds: 1);
      });
      running.value = true;
    }
  }

  /// Pause the timer. Keeps the notification visible (service stays alive).
  Future<void> pause() async {
    if (!running.value) return;

    if (Platform.isAndroid) {
      try {
        await FlutterForegroundTask.saveData(key: 'command', value: 'pause');
        // UI will receive running=false from background tick messages
        running.value = false;
      } catch (e) {
        debugPrint('Foreground pause saveData failed: $e');
        // fallback
        _receiveSub?.cancel();
        _receiveSub = null;
        running.value = false;
      }
    } else {
      _localTimer?.cancel();
      _localTimer = null;
      running.value = false;
    }
  }

  /// Toggle start/pause.
  Future<void> toggle() async {
    if (running.value) {
      await pause();
    } else {
      await start();
    }
  }

  /// Reset elapsed to zero.
  Future<void> reset() async {
    elapsed.value = Duration.zero;
    if (Platform.isAndroid) {
      try {
        await FlutterForegroundTask.saveData(key: 'command', value: 'reset');
      } catch (e) {
        debugPrint('Foreground reset saveData failed: $e');
      }
    } else {
      _localTimer?.cancel();
      _localTimer = null;
      running.value = false;
    }
  }

  void dispose() {
    _localTimer?.cancel();
    _receiveSub?.cancel();
    elapsed.dispose();
    running.dispose();
  }
}
