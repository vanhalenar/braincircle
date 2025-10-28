import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class GoalsCard extends StatefulWidget {
  final String periodTitle;
  final List<Map<String, dynamic>> goals;
  final VoidCallback? onViewAllPressed;

  const GoalsCard({
    super.key,
    required this.periodTitle,
    required this.goals,
    this.onViewAllPressed,
  });

  @override
  State<GoalsCard> createState() => _GoalsCardState();
}

class _GoalsCardState extends State<GoalsCard> {
  late List<Map<String, dynamic>> _goals;
  late List<bool> _checked;

  @override
  void initState() {
    super.initState();
    _goals = List.from(widget.goals);
    _checked = List.generate(widget.goals.length, (_) => false);
  }

  Future<void> _editGoal(BuildContext context, int index) async {
    final goal = _goals[index];
    final controller = TextEditingController(text: goal['title']);
    String selectedVisibility = goal['visibility'] ?? 'Everyone';
    DateTime selectedDate = goal['date'] ?? DateTime.now();
    TimeOfDay? selectedTime = goal['time'];

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

          Future<void> pickTime() async {
            final picked = await showTimePicker(
              context: context,
              initialTime: selectedTime ?? TimeOfDay.now(),
            );
            if (picked != null) setDialogState(() => selectedTime = picked);
          }

          return AlertDialog(
            title: const Text('Edit goal'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: controller,
                    autofocus: true,
                    decoration: const InputDecoration(
                      hintText: 'Enter goal name',
                      border: OutlineInputBorder(),
                    ),
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
                        child: Text('Private (Only me)'),
                      ),
                    ],
                    onChanged: (value) {
                      setDialogState(
                        () => selectedVisibility = value ?? 'Everyone',
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  if (widget.periodTitle != "Today") ...[
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.calendar_today_outlined),
                            label: Text(
                              DateFormat.yMMMMd().format(selectedDate),
                            ),
                            onPressed: pickDate,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.access_time),
                            label: Text(
                              selectedTime?.format(context) ??
                                  'Select time (optional)',
                            ),
                            onPressed: pickTime,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              // Delete button
              TextButton(
                onPressed: () {
                  Navigator.pop(context, {'delete': true});
                },
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

                  DateTime finalDate = selectedDate;
                  if (selectedTime != null) {
                    finalDate = DateTime(
                      finalDate.year,
                      finalDate.month,
                      finalDate.day,
                      selectedTime!.hour,
                      selectedTime!.minute,
                    );
                  }

                  Navigator.pop(context, {
                    'title': text,
                    'visibility': selectedVisibility,
                    'date': finalDate,
                    'time': selectedTime,
                  });
                },
                child: const Text('Save'),
              ),
            ],
          );
        },
      ),
    );

    // Handle delete
    if (editedGoal != null && editedGoal['delete'] == true) {
      setState(() {
        _goals.removeAt(index);
        _checked.removeAt(index);
      });
      return;
    }

    // Handle save/edit
    if (editedGoal != null && editedGoal['title'] != null) {
      setState(() => _goals[index] = editedGoal);
    }
  }

  Future<void> _addGoal(BuildContext context) async {
    final controller = TextEditingController();
    String selectedVisibility = 'Everyone';
    DateTime? selectedDate;
    TimeOfDay? selectedTime;

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
            if (picked != null) {
              setDialogState(() => selectedDate = picked);
            }
          }

          Future<void> pickTime() async {
            final picked = await showTimePicker(
              context: context,
              initialTime: TimeOfDay.now(),
            );
            if (picked != null) {
              setDialogState(() => selectedTime = picked);
            }
          }

          return AlertDialog(
            title: Text('Add a new goal for ${widget.periodTitle}'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: controller,
                    autofocus: true,
                    decoration: const InputDecoration(
                      hintText: 'Enter goal name',
                      border: OutlineInputBorder(),
                    ),
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
                  if (widget.periodTitle != "Today") ...[
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.calendar_today_outlined),
                            label: Text(
                              selectedDate == null
                                  ? 'Select date'
                                  : DateFormat.yMMMMd().format(selectedDate!),
                            ),
                            onPressed: pickDate,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.access_time),
                            label: Text(
                              selectedTime == null
                                  ? 'Select time (optional)'
                                  : selectedTime!.format(context),
                            ),
                            onPressed: pickTime,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  final text = controller.text.trim();
                  if (text.isEmpty) return;

                  DateTime finalDate;
                  if (widget.periodTitle == "Today") {
                    finalDate = DateTime.now();
                  } else if (selectedDate == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please select a date.')),
                    );
                    return;
                  } else {
                    finalDate = selectedDate!;
                  }

                  if (selectedTime != null) {
                    finalDate = DateTime(
                      finalDate.year,
                      finalDate.month,
                      finalDate.day,
                      selectedTime!.hour,
                      selectedTime!.minute,
                    );
                  }

                  Navigator.pop(context, {
                    'title': text,
                    'visibility': selectedVisibility,
                    'date': finalDate,
                  });
                },
                child: const Text('Add'),
              ),
            ],
          );
        },
      ),
    );

    if (newGoal != null && newGoal['title']!.isNotEmpty) {
      setState(() {
        _goals.add(newGoal);
        _checked.add(false);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormatter = DateFormat('EEE, MMM d, h:mm a');

    return Card(
      color: const Color(0xFFF7FAF7),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header bar
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

            // Empty state
            if (_goals.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text("No goals yet."),
              ),

            // Goals list
            ...List.generate(_goals.length, (index) {
              final goal = _goals[index];
              final date = goal['date'] as DateTime;
              final visibility = goal['visibility'] ?? 'Everyone';

              if (index >= _checked.length) _checked.add(false);

              return InkWell(
                onLongPress: () => _editGoal(context, index),
                child: CheckboxListTile(
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
                  controlAffinity: ListTileControlAffinity.leading,
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
