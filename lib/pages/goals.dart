import 'package:flutter/material.dart';
import 'package:brain_circle/widgets/goals_card.dart';

class Goals extends StatelessWidget {
  const Goals({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEFF6EF),
      body: SingleChildScrollView(
        child: Column(
          children: [
            GoalsCard(
              periodTitle: 'Today',
              goals: [
                {
                  'title': 'Study Algorithms',
                  'visibility': 'Everyone',
                  'date': DateTime.now(),
                },
                {
                  'title': 'Study for midterm',
                  'visibility': 'Private',
                  'date': DateTime.now(),
                },
              ],
            ),
            GoalsCard(
              periodTitle: 'This Week',
              goals: [
                {
                  'title': 'Finish TAMa essay slides',
                  'visibility': 'Everyone',
                  'date': DateTime(2025, 10, 31),
                },
                {
                  'title': 'Start Image Processing Project',
                  'visibility': 'Friends',
                  'date': DateTime(2025, 11, 2, 18, 0),
                },
                {
                  'title': 'Determine an idea for Database Systems Project',
                  'visibility': 'Private',
                  'date': DateTime(2025, 11, 3),
                },
              ],
            ),
            GoalsCard(
              periodTitle: 'This Month',
              goals: [
                {
                  'title': 'Finish PDI project',
                  'visibility': 'Everyone',
                  'date': DateTime(2025, 11, 15),
                },
                {
                  'title': 'Finish Image Processing project',
                  'visibility': 'Friends',
                  'date': DateTime(2025, 11, 25, 12, 0),
                },
                {
                  'title': 'Submit all assignments before deadline',
                  'visibility': 'Private',
                  'date': DateTime(2025, 11, 28),
                },
              ],
            ),
          ],
        ),
      ),
    );
  }
}
