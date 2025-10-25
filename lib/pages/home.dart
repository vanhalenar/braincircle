import 'package:brain_circle/widgets/friend_card_big.dart';
import 'package:flutter/material.dart';

import 'package:provider/provider.dart';
import 'package:brain_circle/auth/auth_controller.dart';
import 'package:brain_circle/auth/auth_gate.dart';
import 'package:brain_circle/homepage.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text('Home'),
          actions: [
            IconButton(
              tooltip: 'Sign out',
              icon: const Icon(Icons.logout),
              onPressed: () async {
                await context.read<AuthController>().logout();
                if (!context.mounted) return;

                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(
                    builder: (_) => const AuthGate(home: Homepage()),
                  ),
                  (_) => false,
                );
              },
            ),
          ],
      ),

      body: Column(
        children: [
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
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
                        onPressed: enterFocusMode,
                        icon: Icon(Icons.play_arrow),
                        iconSize: 70,
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

  void enterFocusMode() {}
}
