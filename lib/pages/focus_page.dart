import 'package:brain_circle/utils/focus_timer.dart';
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
    // Get the singleton instance
    _focusTimer = FocusTimer.instance;
    // Start the timer when entering focus page
    _focusTimer.start();
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
                          // Pause the timer and return to home
                          await _focusTimer.pause();
                          if (mounted) {
                            Navigator.of(context).pop();
                          }
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
}
