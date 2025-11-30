import 'package:brain_circle/repo/user_repository.dart';
import 'package:brain_circle/util/formatter.dart';
import 'package:flutter/material.dart';

class FriendCardBig extends StatelessWidget {
  String name;
  bool working;
  String userID;
  final userRepository = UserRepository.instance;
  FriendCardBig({
    super.key,
    required this.name,
    this.working = false,
    required this.userID,
  });
  
  @override
  Widget build(BuildContext context) {
    String workingText = working ? 'Working' : 'Away';
    return SizedBox(
      width: 170,
      child: Card(
        //color: Theme.of(context).colorScheme.secondaryContainer,
        //color: Theme.of(context).colorScheme.surface,
        //color: Theme.of(context).cardColor,
        color: working
            ? Theme.of(context).colorScheme.secondaryContainer
            : null,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: EdgeInsets.fromLTRB(0, 30, 0, 50),
              child: CircleAvatar(
                backgroundImage: AssetImage('assets/placeholder.png'),
                radius: 45,
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(10, 0, 0, 0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(name, style: Theme.of(context).textTheme.bodyLarge),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(10, 0, 0, 0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  workingText,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: Colors.grey),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(10, 10, 0, 0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: StreamBuilder(
                  stream: userRepository.getTotalStudyTime(userID),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return Text("00:00:00");
                    }

                    final seconds = Formatter.format(snapshot.data);
                    return Text(seconds);
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
