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

                              final date = (widget.periodTitle == "Today")
                                  ? DateTime(
                                      DateTime.now().year,
                                      DateTime.now().month,
                                      DateTime.now().day,
                                    )
                                  : (selectedDate ?? DateTime.now());

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
      setState(() {
        _goals.add(newGoal);
        _checked.add(false);
      });
    }
  }

  Future<void> _editGoal(BuildContext context, int index) async {
    final goal = _goals[index];
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
                      if (widget.periodTitle != "Today")
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

    if (editedGoal != null && editedGoal['delete'] == true) {
      setState(() {
        _goals.removeAt(index);
        _checked.removeAt(index);
      });
      return;
    }

    if (editedGoal != null && editedGoal['title'] != null) {
      setState(() => _goals[index] = editedGoal);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormatter = DateFormat('EEE, MMM d');

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
            if (_goals.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text("No goals yet."),
              ),
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
