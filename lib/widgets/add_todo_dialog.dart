
import 'package:flutter/material.dart';

import '../models/todo.dart';

class AddTodoDialog extends StatefulWidget {
  final Todo? existingTodo;

  const AddTodoDialog({super.key, this.existingTodo});

  @override
  State<AddTodoDialog> createState() => _AddTodoDialogState();
}

class _AddTodoDialogState extends State<AddTodoDialog> {
  final titleController = TextEditingController();
  final descriptionController = TextEditingController();
  int selectedPriority = 2;

  bool noDueDate = false;

  DateTime selectedDate = DateTime.now();

  TimeOfDay selectedTime = const TimeOfDay(
    hour: 23,
    minute: 59,
  );

  @override
  void initState() {
    super.initState();
    final original = widget.existingTodo;
    if (original != null) {
      titleController.text = original.title;
      descriptionController.text = original.description;
      noDueDate = original.dueDate == null;
      selectedPriority = original.priority;
      if (original.dueDate != null) {
        selectedDate = original.dueDate!;
        selectedTime = TimeOfDay.fromDateTime(original.dueDate!);
      }
    }
  }

  @override
  void dispose() {
    titleController.dispose();
    descriptionController.dispose();
    super.dispose();
  }

  String formatDate(DateTime date) {
    String pad(int value) => value.toString().padLeft(2, '0');

    return '${pad(date.day)}.${pad(date.month)}.${date.year}';
  }

  String formatTime(TimeOfDay time) {
    String pad(int value) => value.toString().padLeft(2, '0');

    return '${pad(time.hour)}:${pad(time.minute)}';
  }

  Future<void> pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (!mounted || date == null) return;

    setState(() {
      selectedDate = date;
    });
  }

  Future<void> pickTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: selectedTime,
    );

    if (!mounted || time == null) return;

    setState(() {
      selectedTime = time;
    });
  }

  void saveTodo() {
    final title = titleController.text.trim();

    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Bitte gib einen Titel ein.'),
        ),
      );
      return;
    }

    DateTime? dueDate;

    if (!noDueDate) {
      dueDate = DateTime(
        selectedDate.year,
        selectedDate.month,
        selectedDate.day,
        selectedTime.hour,
        selectedTime.minute,
      );
    }

    final todo = Todo(
      id: widget.existingTodo?.id,
      isCompleted: widget.existingTodo?.isCompleted ?? false,
      title: title,
      description: descriptionController.text.trim(),
      dueDate: dueDate,
      priority: selectedPriority,
    );

    Navigator.of(context).pop(todo);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return AlertDialog(
      title: Text(widget.existingTodo == null ? 'Neue Quest' : 'Quest bearbeiten'),

      content: SizedBox(
        width: 350,
        height: 480,

        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Titel
              TextField(
                controller: titleController,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'Titel',
                  prefixIcon: Icon(Icons.task_alt),
                ),
              ),

              const SizedBox(height: 16),

              // Beschreibung
              TextField(
                controller: descriptionController,
                minLines: 3,
                maxLines: 5,
                decoration: const InputDecoration(
                  labelText: 'Beschreibung',
                  alignLabelWithHint: true,
                  prefixIcon: Icon(Icons.notes),
                ),
              ),

              const SizedBox(height: 16),

              DropdownButtonFormField<int>(
                initialValue: selectedPriority,
                isExpanded: true,

                decoration: const InputDecoration(
                  labelText: 'Priorität',
                  prefixIcon: Icon(Icons.flag_outlined),
                ),

                items: const [
                  DropdownMenuItem(
                    value: 1,
                    child: Text(
                      '🟢 - Niedrig',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  DropdownMenuItem(
                    value: 2,
                    child: Text(
                      '🟡 - Mittel',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  DropdownMenuItem(
                    value: 3,
                    child: Text(
                      '🔴 - Hoch',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],

                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      selectedPriority = value;
                    });
                  }
                },
              ),

              const SizedBox(height: 16),

              // Checkbox: Keine Deadline
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Kein Fälligkeitsdatum'),
                value: noDueDate,
                controlAffinity:
                    ListTileControlAffinity.leading,

                onChanged: (value) {
                  setState(() {
                    noDueDate = value ?? false;
                  });
                },
              ),

              const SizedBox(height: 12),

              // Datum auswählen
              OutlinedButton.icon(
                onPressed: noDueDate ? null : pickDate,
                icon: const Icon(Icons.calendar_today),
                label: Text(
                  noDueDate
                      ? 'Datum deaktiviert'
                      : formatDate(selectedDate),
                ),
              ),

              const SizedBox(height: 8),

              // Uhrzeit auswählen
              OutlinedButton.icon(
                onPressed: noDueDate ? null : pickTime,
                icon: const Icon(Icons.access_time),
                label: Text(
                  noDueDate
                      ? 'Uhrzeit deaktiviert'
                      : formatTime(selectedTime),
                ),
              ),

              if (noDueDate) ...[
                const SizedBox(height: 8),
                Text(
                  'Diese Aufgabe hat keine Deadline.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),

      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: const Text('Abbrechen'),
        ),

        FilledButton(
          onPressed: saveTodo,
          child: const Text('Speichern'),
        ),
      ],
    );
  }
}
