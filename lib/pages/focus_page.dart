import 'package:flutter/material.dart';

class FocusPage extends StatelessWidget {
  const FocusPage({super.key});

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
                          //Navigator.pop(context);
                          Navigator.of(context).pop();
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
