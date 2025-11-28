import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class GoalsCard extends StatefulWidget {
  final String periodTitle;
  final List<Map<String, dynamic>> goals;

  const GoalsCard({super.key, required this.periodTitle, required this.goals});

  @override
  State<GoalsCard> createState() => _GoalsCardState();
}

class _GoalsCardState extends State<GoalsCard> {
  late List<bool> _checked;

  @override
  void initState() {
    super.initState();
    _checked = List.generate(widget.goals.length, (_) => false);
  }

  @override
  void didUpdateWidget(covariant GoalsCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    _checked = List.generate(widget.goals.length, (_) => false);
  }

  Future<void> _addGoal(BuildContext context) async {
    final controller = TextEditingController();
    String selectedVisibility = 'Everyone';
    DateTime? selectedDate;

    final newGoal = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          Future<void> pickDate() async {
            final picked = await showDatePicker(
              context: context,
              initialDate: DateTime.now(),
              firstDate: DateTime.now(),
              lastDate: DateTime.now().add(const Duration(days: 365)),
            );
            if (picked != null) setDialogState(() => selectedDate = picked);
          }

          return Dialog(
            insetPadding: const EdgeInsets.symmetric(horizontal: 12),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width - 24,
              ),
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Add a new goal for ${widget.periodTitle}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: controller,
                        autofocus: true,
                        decoration: const InputDecoration(
                          hintText: 'Enter goal name',
                          border: OutlineInputBorder(),
                        ),
                        maxLines: null,
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: selectedVisibility,
                        decoration: const InputDecoration(
                          labelText: 'Visibility',
                          border: OutlineInputBorder(),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'Everyone',
                            child: Text('Everyone'),
                          ),
                          DropdownMenuItem(
                            value: 'Friends',
                            child: Text('Friends'),
                          ),
                          DropdownMenuItem(
                            value: 'Private',
                            child: Text('Private'),
                          ),
                        ],
                        onChanged: (value) {
                          setDialogState(
                            () => selectedVisibility = value ?? 'Everyone',
                          );
                        },
                      ),
                      const SizedBox(height: 16),
                      if (widget.periodTitle != "Today")
                        OutlinedButton.icon(
                          icon: const Icon(Icons.calendar_today_outlined),
                          label: Text(
                            selectedDate == null
                                ? 'Select date'
                                : DateFormat.yMMMMd().format(selectedDate!),
                          ),
                          onPressed: pickDate,
                        ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Cancel'),
                          ),
                          ElevatedButton(
                            onPressed: () {
                              final text = controller.text.trim();
                              if (text.isEmpty) return;

                              final date = selectedDate ?? DateTime.now();

                              Navigator.pop(context, {
                                'title': text,
                                'visibility': selectedVisibility,
                                'date': date,
                              });
                            },
                            child: const Text('Add'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );

    if (newGoal != null && newGoal['title']!.isNotEmpty) {
      final userId = FirebaseAuth.instance.currentUser!.uid;
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('goals')
          .add({
            'title': newGoal['title'],
            'visibility': newGoal['visibility'],
            'date': Timestamp.fromDate(newGoal['date']),
            'completed': false,
          });
    }
  }

  Future<void> _editGoal(
    BuildContext context,
    Map<String, dynamic> goal,
  ) async {
    final controller = TextEditingController(text: goal['title']);
    String selectedVisibility = goal['visibility'] ?? 'Everyone';
    DateTime selectedDate = goal['date'] ?? DateTime.now();

    final editedGoal = await showDialog<Map<String, dynamic>?>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          Future<void> pickDate() async {
            final picked = await showDatePicker(
              context: context,
              initialDate: selectedDate,
              firstDate: DateTime.now(),
              lastDate: DateTime.now().add(const Duration(days: 365)),
            );
            if (picked != null) setDialogState(() => selectedDate = picked);
          }

          return Dialog(
            insetPadding: const EdgeInsets.symmetric(horizontal: 12),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width - 24,
              ),
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Edit goal',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: controller,
                        autofocus: true,
                        decoration: const InputDecoration(
                          hintText: 'Enter goal name',
                          border: OutlineInputBorder(),
                        ),
                        maxLines: null,
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: selectedVisibility,
                        decoration: const InputDecoration(
                          labelText: 'Visibility',
                          border: OutlineInputBorder(),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'Everyone',
                            child: Text('Everyone'),
                          ),
                          DropdownMenuItem(
                            value: 'Friends',
                            child: Text('Friends'),
                          ),
                          DropdownMenuItem(
                            value: 'Private',
                            child: Text('Private'),
                          ),
                        ],
                        onChanged: (value) {
                          setDialogState(
                            () => selectedVisibility = value ?? 'Everyone',
                          );
                        },
                      ),
                      const SizedBox(height: 16),
                      OutlinedButton.icon(
                        icon: const Icon(Icons.calendar_today_outlined),
                        label: Text(DateFormat.yMMMMd().format(selectedDate)),
                        onPressed: pickDate,
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () =>
                                Navigator.pop(context, {'delete': true}),
                            child: const Text(
                              'Delete',
                              style: TextStyle(color: Colors.red),
                            ),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Cancel'),
                          ),
                          ElevatedButton(
                            onPressed: () {
                              final text = controller.text.trim();
                              if (text.isEmpty) return;

                              Navigator.pop(context, {
                                'title': text,
                                'visibility': selectedVisibility,
                                'date': selectedDate,
                              });
                            },
                            child: const Text('Save'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );

    if (editedGoal != null) {
      final userId = FirebaseAuth.instance.currentUser!.uid;
      final docRef = FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('goals')
          .doc(goal['id']);

      if (editedGoal['delete'] == true) {
        await docRef.delete();
      } else {
        await docRef.update({
          'title': editedGoal['title'],
          'visibility': editedGoal['visibility'],
          'date': Timestamp.fromDate(editedGoal['date']),
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormatter = DateFormat('EEE, MMM d');

    return Card(
      color: const Color(0xFFF7FAF7),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 2,
      margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  widget.periodTitle,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add_circle_outline),
                  onPressed: () => _addGoal(context),
                ),
              ],
            ),
            const SizedBox(height: 4),
            if (widget.goals.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text("No goals yet."),
              ),
            ...List.generate(widget.goals.length, (index) {
              final goal = widget.goals[index];
              final date = goal['date'] as DateTime;
              final visibility = goal['visibility'] ?? 'Everyone';

              if (index >= _checked.length) _checked.add(false);

              return InkWell(
                onLongPress: () => _editGoal(context, goal),
                child: CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  visualDensity: VisualDensity.compact,
                  title: Text(goal['title'] ?? ''),
                  subtitle: Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: '$visibility',
                          style: const TextStyle(
                            fontSize: 13,
                            color: Colors.lightGreen,
                          ),
                        ),
                        const TextSpan(
                          text: '  •  ',
                          style: TextStyle(fontSize: 13, color: Colors.black),
                        ),
                        TextSpan(
                          text: dateFormatter.format(date),
                          style: const TextStyle(
                            fontSize: 13,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                  value: _checked[index],
                  onChanged: (value) {
                    setState(() => _checked[index] = value ?? false);
                  },
                  controlAffinity: ListTileControlAffinity.trailing,
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
