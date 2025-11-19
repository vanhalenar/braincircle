import 'package:brain_circle/extra/roll_down_page_route.dart';
import 'package:brain_circle/pages/focus_page.dart';
import 'package:brain_circle/utils/focus_timer.dart';
import 'package:brain_circle/widgets/friend_card_big.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:brain_circle/repo/user_repository.dart';

class Home extends StatefulWidget {
  Home({super.key});

  final userRepository = UserRepository.instance;
  static const List<String> names = ['Lesana', 'Mark', 'Nina', 'Teodor'];

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  late FocusTimer _focusTimer;

  final db = FirebaseFirestore.instance;
  final user = FirebaseAuth.instance.currentUser;
  late final dynamic userDoc;
  Map<String, dynamic>? userData;

  @override
  void initState() {
    super.initState();
    _focusTimer = FocusTimer.instance;
    userDoc = db.collection('users').doc(user!.uid);
    userDoc.get().then((snapshot) {
      setState(() {
        userData = snapshot.data();
      });
    });
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
          StreamBuilder(
            stream: widget.userRepository.getFriends(),
            builder: (context, asyncSnapshot) {
              if (asyncSnapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator());
              }

              if (asyncSnapshot.hasError) {
                return Text("Error: ${asyncSnapshot.error}");
              }

              if (!asyncSnapshot.hasData) {
                return Text("No data");
              }
              final friendDocs = asyncSnapshot.data!;
              return Hero(
                tag: 'friends',
                child: Padding(
                  padding: EdgeInsetsGeometry.fromLTRB(10, 10, 10, 30),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      spacing: 10,
                      children: friendDocs.map((doc) {
                        final data = doc.data() as Map<String, dynamic>;
                        return FriendCardBig(name: data['name'], working: data['studying'], userID: doc.id);
                      }).toList(),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  void enterFocusMode() {}
}
