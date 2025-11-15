import 'dart:async';
import 'dart:io';
import 'dart:isolate';

import 'package:flutter/foundation.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';

/// Compact foreground timer: background handler + UI controller singleton.
@pragma('vm:entry-point')
void startCallback() {
  FlutterForegroundTask.setTaskHandler(ForegroundTimerHandler());
}

@pragma('vm:entry-point')
class ForegroundTimerHandler extends TaskHandler {
  Timer? _timer;
  int _elapsedSeconds = 0;
  bool _isPaused = false;

  @override
  Future<void> onStart(DateTime timestamp, SendPort? sendPort) async {
    debugPrint('onStart triggered00000000000000000000000000000000');
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) async {
      try {
        final cmd = await FlutterForegroundTask.getData<String>(key: 'command');
        _isPaused = (cmd == 'pause');
        if (cmd == 'reset') _elapsedSeconds = 0;
      } catch (_) {}

      if (!_isPaused) _elapsedSeconds++;

      if (Platform.isAndroid) {
        try {
          await FlutterForegroundTask.updateService(
            notificationTitle: _isPaused ? 'Focus timer paused' : 'Focus timer running',
            notificationText: _format(_elapsedSeconds),
          );
        } catch (e) {
          debugPrint('Background updateService failed: $e');
        }
      }

      try {
        // persist authoritative elapsed seconds so main isolate can read it
        await FlutterForegroundTask.saveData(key: 'elapsed_seconds', value: _elapsedSeconds.toString());
        // also attempt to send via provided sendPort; include a timestamp so the
        // main isolate can ignore stale messages that predate a user command.
        sendPort?.send({
          'type': 'tick',
          'elapsed': _elapsedSeconds,
          'running': !_isPaused,
          'ts': DateTime.now().millisecondsSinceEpoch,
        });
      } catch (_) {}
    });
  }

  @override
  Future<void> onDestroy(DateTime timestamp, SendPort? sendPort) async {
    _timer?.cancel();
  }

  @override
  Future<void> onRepeatEvent(DateTime timestamp, SendPort? sendPort) async {}

  void onButtonPressed(String id) {
    final nowTs = DateTime.now().millisecondsSinceEpoch.toString();
    if (id == 'pause') {
      FlutterForegroundTask.saveData(key: 'command', value: 'pause');
      FlutterForegroundTask.saveData(key: 'command_ts', value: nowTs);
    } else if (id == 'play') {
      FlutterForegroundTask.saveData(key: 'command', value: 'play');
      FlutterForegroundTask.saveData(key: 'command_ts', value: nowTs);
    } else if (id == 'reset') {
      FlutterForegroundTask.saveData(key: 'command', value: 'reset');
      FlutterForegroundTask.saveData(key: 'command_ts', value: nowTs);
    }
  }

  @override
  void onNotificationPressed() => FlutterForegroundTask.launchApp();

  String _format(int seconds) {
    final h = seconds ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    final s = seconds % 60;
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(h)}:${two(m)}:${two(s)}';
  }
}

class ForegroundTimerController {
  ForegroundTimerController._();
  static final ForegroundTimerController instance = ForegroundTimerController._();

  final ValueNotifier<Duration> elapsed = ValueNotifier(Duration.zero);
  final ValueNotifier<bool> running = ValueNotifier(false);

  StreamSubscription? _sub;
  Timer? _pollTimer;

  // Keep track of last message time to decide whether polling is needed
  DateTime? _lastTickReceived;
  // Keep track of the last time the user issued a command (play/pause/reset)
  // so we can ignore stale ticks produced before that command.
  DateTime? _lastCommandAt;
  // Suppress incoming ticks for a short time after the user issues a command
  // to avoid out-of-order updates that can flip the UI. Tunable value.
  final Duration _suppressWindow = const Duration(milliseconds: 700);

  void startListening() {
    if (_sub != null) return;
    final rp = FlutterForegroundTask.receivePort;
    _sub = rp?.listen((message) {
      if (message is Map && message['type'] == 'tick') {
        // ignore ticks that were generated before the user's last explicit
        // command (play/pause/reset) to avoid transient UI flips caused by
        // out-of-order or delayed messages.
        final int? ts = message['ts'] is int ? message['ts'] as int : null;
        if (_lastCommandAt != null && ts != null) {
          final tickAt = DateTime.fromMillisecondsSinceEpoch(ts);
          // ignore ticks produced before the command
          if (tickAt.isBefore(_lastCommandAt!)) {
            debugPrint('foreground_timer: ignoring stale tick (tickAt=${tickAt.toIso8601String()} < lastCommandAt=${_lastCommandAt!.toIso8601String()})');
            return;
          }
          // also ignore ticks that arrive within the short suppression window
          // after a command; this is a defensive measure against tight races.
          if (DateTime.now().difference(_lastCommandAt!) < _suppressWindow) {
            debugPrint('foreground_timer: suppressing tick (within ${_suppressWindow.inMilliseconds}ms of command)');
            return;
          }
        }

        final int seconds = message['elapsed'] ?? 0;
        elapsed.value = Duration(seconds: seconds);
        running.value = message['running'] ?? true;
        _lastTickReceived = DateTime.now();
      }
    });

    // start a lightweight poll to read persisted elapsed_seconds in case
    // receivePort messages are not delivered (race or platform issues).
    _pollTimer ??= Timer.periodic(const Duration(seconds: 1), (_) async {
      // if we received a tick recently (within 2s) skip polling
      if (_lastTickReceived != null && DateTime.now().difference(_lastTickReceived!) < const Duration(seconds: 2)) {
        return;
      }
      try {
        final s = await FlutterForegroundTask.getData<String>(key: 'elapsed_seconds');
        if (s != null) {
          final int secs = int.tryParse(s) ?? 0;
          elapsed.value = Duration(seconds: secs);
        }

        // also read command timestamp saved by the background handler when
        // the notification buttons are used, so we can ignore stale ticks.
        final tsStr = await FlutterForegroundTask.getData<String>(key: 'command_ts');
        if (tsStr != null) {
          final tsInt = int.tryParse(tsStr);
          if (tsInt != null) _lastCommandAt = DateTime.fromMillisecondsSinceEpoch(tsInt);
        }
      } catch (e) {
        // ignore
      }
    });
  }

  Future<void> start() async {
    startListening();
    try {
      _lastCommandAt = DateTime.now();
      await FlutterForegroundTask.saveData(key: 'command', value: 'play');
    await FlutterForegroundTask.startService(
      notificationTitle: 'Focus timer running',
      notificationText: _formatDuration(elapsed.value),
      callback: startCallback,
    );
    running.value = true;
    } catch (e) {
      debugPrint('start error: $e');
    }
  }

  Future<void> pause() async {
    try {
      _lastCommandAt = DateTime.now();
      await FlutterForegroundTask.saveData(key: 'command', value: 'pause');
      running.value = false;
    } catch (e) {
      debugPrint('pause error: $e');
    }
  }

  Future<void> toggle() async {
    if (running.value) return pause();
    return start();
  }

  String _formatDuration(Duration d) {
    String two(int n) => n.toString().padLeft(2, '0');
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    final s = d.inSeconds.remainder(60);
    return '${two(h)}:${two(m)}:${two(s)}';
  }

  // helper removed — controller uses _formatDuration directly

  void dispose() {
    _sub?.cancel();
    _pollTimer?.cancel();
  }
}
