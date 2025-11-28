import 'package:flutter/material.dart';
import 'package:brain_circle/widgets/goals_card.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class Goals extends StatelessWidget {
  const Goals({super.key});

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return const SizedBox.shrink();

    return Scaffold(
      backgroundColor: const Color(0xFFEFF6EF),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .collection('goals')
            .orderBy('date')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No goals yet."));
          }

          final now = DateTime.now();
          final today = DateTime(now.year, now.month, now.day);
          final startOfWeek = today.subtract(Duration(days: today.weekday - 1));
          final endOfWeek = startOfWeek.add(const Duration(days: 6));
          final startOfMonth = DateTime(today.year, today.month, 1);
          final endOfMonth = DateTime(today.year, today.month + 1, 0);

          List<Map<String, dynamic>> todayGoals = [];
          List<Map<String, dynamic>> weekGoals = [];
          List<Map<String, dynamic>> monthGoals = [];

          for (var doc in snapshot.data!.docs) {
            final data = doc.data() as Map<String, dynamic>;
            final date = (data['date'] as Timestamp).toDate();
            final goal = {
              'id': doc.id,
              'title': data['title'],
              'visibility': data['visibility'] ?? 'Everyone',
              'date': date,
              'completed': data['completed'] ?? false,
            };

            if (_isSameDay(date, today)) {
              todayGoals.add(goal);
            } else if (date.isAfter(today.subtract(const Duration(days: 1))) &&
                date.isBefore(endOfWeek.add(const Duration(days: 1)))) {
              weekGoals.add(goal);
            } else if (date.isAfter(endOfWeek) &&
                date.isBefore(endOfMonth.add(const Duration(days: 1)))) {
              monthGoals.add(goal);
            }
          }

          return SingleChildScrollView(
            child: Column(
              children: [
                GoalsCard(periodTitle: 'Today', goals: todayGoals),
                GoalsCard(periodTitle: 'This Week', goals: weekGoals),
                GoalsCard(periodTitle: 'This Month', goals: monthGoals),
              ],
            ),
          );
        },
      ),
    );
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}
