import 'package:brain_circle/widgets/friend_card_big.dart';
// import 'package:brain_circle/utils/focus_timer.dart';
import 'package:flutter/material.dart';
import 'package:brain_circle/utils/foreground_timer.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final controller = ForegroundTimerController.instance;

  @override
  void initState() {
    super.initState();
    controller.startListening();
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
                Container(
                  padding: EdgeInsets.fromLTRB(0, 40, 0, 20),
                  child: Center(
                    child: ValueListenableBuilder<Duration>(
                        valueListenable: controller.elapsed,
                        builder: (_, elapsed, __) => Text(
                          // local formatting
                          '${elapsed.inHours.toString().padLeft(2, '0')}:${(elapsed.inMinutes % 60).toString().padLeft(2, '0')}:${(elapsed.inSeconds % 60).toString().padLeft(2, '0')}',
                        style: Theme.of(context).textTheme.displayLarge,
                      ),
                    ),
                  ),
                ),
                ValueListenableBuilder<bool>(
                  valueListenable: controller.running,
                  builder: (_, running, __) => IconButton.filledTonal(
                    onPressed: controller.toggle,
                    icon: Icon(running ? Icons.pause : Icons.play_arrow),
                    iconSize: 70,
                  ),
                ),
              ],
            ),
          ),
          
          Padding(
            padding: EdgeInsetsGeometry.fromLTRB(10, 0, 0, 0), 
            child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Friends',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                ),
          ),
          Padding(
            padding: EdgeInsetsGeometry.fromLTRB(10, 10, 10, 30), 
            child: SizedBox(
              height: 260,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemBuilder: (_, _) => FriendCardBig(),
                separatorBuilder: (_, _) => Divider(indent: 10),
                itemCount: 5,
              ),
            ),
          ),
        ],
      ),
    );
  }


  @override
  void dispose() {
    // stop listening when the widget is disposed
    controller.dispose();
    super.dispose();
  }
}
