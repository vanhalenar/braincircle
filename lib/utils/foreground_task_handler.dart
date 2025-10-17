import 'dart:async';
import 'dart:isolate';

import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';

/// A simple TaskHandler that keeps a counter and updates the foreground
/// notification every second. It also sends the elapsed seconds to the main
/// isolate via FlutterForegroundTask.updateService (available as sendData).

class ForegroundTimerHandler extends TaskHandler {
  Timer? _timer;
  int _elapsedSeconds = 0;
  SendPort? _mainSendPort;
  bool _paused = false;

  @override
  Future<void> onStart(DateTime timestamp, SendPort? sendPort) async {
    _mainSendPort = sendPort;
    debugPrint('Background handler started, sendPort: $_mainSendPort');

    // Start ticking
    _timer = Timer.periodic(const Duration(seconds: 1), (_) async {
      // Check command saved by main isolate (play/pause)
      try {
        final cmd = await FlutterForegroundTask.getData<String>(key: 'command');
        _paused = (cmd == 'pause');
      } catch (_) {}

      if (!_paused) {
        _elapsedSeconds++;
      }
      // Update notification (protect with try/catch in case plugin isn't
      // registered in this isolate).
      if (Platform.isAndroid) {
        try {
          await FlutterForegroundTask.updateService(
            notificationTitle: 'Focus timer running',
            notificationText: _formatDuration(_elapsedSeconds),
          );
        } catch (e) {
          debugPrint('Background updateService failed: $e');
        }
      }
      // Optionally notify main isolate; protect it as well.
      try {
        _mainSendPort?.send({
          'type': 'tick',
          'elapsed': _elapsedSeconds,
          'running': !_paused,
        });
      } catch (_) {}
    });
  }

  // Some plugin versions use onRepeatEvent instead of a manual timer. If your
  // plugin version supports onRepeatEvent, you can implement it similarly to
  // the periodic timer above. We keep the manual timer and implement onDestroy
  // for cleanup.
  @override
  Future<void> onDestroy(DateTime timestamp, SendPort? sendPort) async {
    _timer?.cancel();
  }

  Future<void> onButtonPressed(String id) async {
    // Handle notification button presses: pause/play
    if (id == 'pause') {
      _timer?.cancel();
      _paused = true;
      try {
        await FlutterForegroundTask.saveData(key: 'command', value: 'pause');
      } catch (_) {}
      // update notification to show paused state but keep service alive
      if (Platform.isAndroid) {
        try {
          await FlutterForegroundTask.updateService(
            notificationTitle: 'Focus timer paused',
            notificationText: _formatDuration(_elapsedSeconds),
          );
        } catch (e) {
          debugPrint('Update on pause failed: $e');
        }
      }
    } else if (id == 'play') {
      // resume
      _paused = false;
      try {
        await FlutterForegroundTask.saveData(key: 'command', value: 'play');
      } catch (_) {}

      _timer ??= Timer.periodic(const Duration(seconds: 1), (_) async {
        _elapsedSeconds++;
        if (Platform.isAndroid) {
          try {
            await FlutterForegroundTask.updateService(
              notificationTitle: 'Focus timer running',
              notificationText: _formatDuration(_elapsedSeconds),
            );
          } catch (e) {
            debugPrint('Update on play failed: $e');
          }
        }
      });
    }
  }

  // Some versions expect onRepeatEvent - implement as a no-op because we
  // already use a Dart Timer inside this handler.
  @override
  Future<void> onRepeatEvent(DateTime timestamp, SendPort? sendPort) async {}
  // If your plugin version supports additional callbacks (onButtonPressed,
  // onReceiveData, onEvent/onRepeatEvent), add them here matching the exact
  // signatures from your installed package.

  String _formatDuration(int seconds) {
    final h = seconds ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    final s = seconds % 60;
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(h)}:${two(m)}:${two(s)}';
  }
}
