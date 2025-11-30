import 'package:brain_circle/utils/focus_timer.dart';
//import 'package:brain_circle/repo/user_repository.dart';
import 'package:flutter/material.dart';

class FocusPage extends StatefulWidget {
  const FocusPage({super.key});

  @override
  State<FocusPage> createState() => _FocusPageState();
}

class _FocusPageState extends State<FocusPage> {
  late FocusTimer _focusTimer;

  @override
  void initState() {
    super.initState();
    _focusTimer = FocusTimer.instance;
    _focusTimer.start();
    // If the timer gets paused (by lifecycle or notification), close this page
    _focusTimer.running.addListener(_onRunningChanged);
  }

  void _onRunningChanged() {
    if (!_focusTimer.running.value) {
      if (mounted) {
        Navigator.of(context).maybePop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Hero(
                  tag: 'timer',
                  child: Column(
                    children: [
                      Container(
                        padding: EdgeInsets.fromLTRB(0, 40, 0, 20),
                        child: Center(
                          child: ValueListenableBuilder<Duration>(
                            valueListenable: _focusTimer.elapsed,
                            builder: (_, elapsed, __) => Text(
                              _focusTimer.formatDuration(elapsed),
                              style: Theme.of(context).textTheme.displayLarge,
                            ),
                          ),
                        ),
                      ),
                      IconButton.filledTonal(
                        onPressed: () async {
                          await _focusTimer.pause();
                        },
                        icon: Icon(Icons.pause),
                        iconSize: 70,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _focusTimer.running.removeListener(_onRunningChanged);
    super.dispose();
  }
}
