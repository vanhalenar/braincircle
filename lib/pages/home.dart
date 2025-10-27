import 'package:brain_circle/extra/roll_down_page_route.dart';
import 'package:brain_circle/pages/focus_page.dart';
import 'package:brain_circle/widgets/friend_card_big.dart';
import 'package:flutter/material.dart';

class Home extends StatefulWidget {
  const Home({super.key});
  static const List<String> names = ['Lesana', 'Mark', 'Nina', 'Teodor'];

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
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
                          child: Text(
                            "00:00:00",
                            style: Theme.of(context).textTheme.displayLarge,
                          ),
                        ),
                      ),
                      IconButton.filledTonal(
                        onPressed: () {
                          Navigator.of(context).push(
                            RollDownPageRoute(
                              page: FocusPage(),
                              appBarColor: Theme.of(
                                context,
                              ).colorScheme.inversePrimary,
                            ),
                          );
                        },
                        icon: Icon(Icons.play_arrow),
                        iconSize: 70,
                      ),
                    ],
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
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                spacing: 10,
                children: [
                  FriendCardBig(name: "Lesana"),
                  FriendCardBig(name: "Mark", working: true,),
                  FriendCardBig(name: "Nina"),
                  FriendCardBig(name: "Teodor"),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void enterFocusMode() {}
}
