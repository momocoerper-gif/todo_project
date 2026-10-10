import 'package:flutter/material.dart';
import '../models/calendar_event.dart';

class AddEventDialog extends StatefulWidget {
  final DateTime date;
  final CalendarEvent? existingEvent;
  final bool allowRecurrence;

  const AddEventDialog({
    super.key,
    required this.date,
    this.existingEvent,
    this.allowRecurrence = true,
  });

  @override
  State<AddEventDialog> createState() => _AddEventDialogState();
}

class _AddEventDialogState extends State<AddEventDialog> {
  final titleController = TextEditingController();
  final locationController = TextEditingController();
  final descriptionController = TextEditingController();

  late DateTime selectedDate;
  DateTime? recurrenceUntil;
  String recurrence = 'none';
  bool isAllDay = false;
  TimeOfDay startTime = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay endTime = const TimeOfDay(hour: 10, minute: 0);
  String? error;

  @override
  void initState() {
    super.initState();
    final previous = widget.existingEvent;
    selectedDate = CalendarEvent.onlyDate(previous?.date ?? widget.date);
    if (previous != null) {
      titleController.text = previous.title;
      locationController.text = previous.location;
      descriptionController.text = previous.description;
      isAllDay = previous.isAllDay;
      startTime = TimeOfDay(hour: (previous.startMinute ?? 540) ~/ 60,
          minute: (previous.startMinute ?? 540) % 60);
      endTime = TimeOfDay(hour: (previous.endMinute ?? 600) ~/ 60,
          minute: (previous.endMinute ?? 600) % 60);
      if (widget.allowRecurrence) {
        recurrence = previous.recurrence;
        recurrenceUntil = previous.recurrenceUntil;
      }
    }
  }

  @override
  void dispose() {
    titleController.dispose();
    locationController.dispose();
    descriptionController.dispose();
    super.dispose();
  }

  int minutes(TimeOfDay t) => t.hour * 60 + t.minute;

  Future<void> pickDate() async {
    final result = await showDatePicker(
      context: context, initialDate: selectedDate,
      firstDate: DateTime(2000), lastDate: DateTime(2100),
    );
    if (!mounted || result == null) return;
    setState(() {
      selectedDate = result;
      if (recurrenceUntil != null && recurrenceUntil!.isBefore(selectedDate)) {
        recurrenceUntil = null;
      }
    });
  }

  Future<void> pickUntil() async {
    final result = await showDatePicker(
      context: context, initialDate: recurrenceUntil ?? selectedDate,
      firstDate: selectedDate, lastDate: DateTime(2100),
    );
    if (!mounted || result == null) return;
    setState(() => recurrenceUntil = result);
  }

  Future<void> pickTime({required bool start}) async {
    final result = await showTimePicker(
      context: context, initialTime: start ? startTime : endTime,
    );
    if (!mounted || result == null) return;
    setState(() {
      if (start) { startTime = result; } else { endTime = result; }
    });
  }

  void save() {
    final title = titleController.text.trim();
    if (title.isEmpty) {
      setState(() => error = 'Bitte einen Titel eingeben.');
      return;
    }
    if (!isAllDay && minutes(endTime) <= minutes(startTime)) {
      setState(() => error = 'Die Endzeit muss nach der Startzeit liegen.');
      return;
    }
    if (recurrence != 'none' && recurrenceUntil != null &&
        recurrenceUntil!.isBefore(selectedDate)) {
      setState(() => error = 'Das Wiederholungsende darf nicht vor dem Termin liegen.');
      return;
    }
    final existing = widget.existingEvent;
    Navigator.of(context).pop(CalendarEvent(
      id: existing?.id,
      title: title,
      description: descriptionController.text.trim(),
      location: locationController.text.trim(),
      date: selectedDate,
      isAllDay: isAllDay,
      startMinute: isAllDay ? null : minutes(startTime),
      endMinute: isAllDay ? null : minutes(endTime),
      recurrence: widget.allowRecurrence ? recurrence : 'none',
      recurrenceUntil: widget.allowRecurrence && recurrence != 'none'
          ? recurrenceUntil : null,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final dateText = MaterialLocalizations.of(context).formatMediumDate(selectedDate);
    final untilText = recurrenceUntil == null ? 'Kein Enddatum'
        : MaterialLocalizations.of(context).formatMediumDate(recurrenceUntil!);
    return AlertDialog(
      title: Text(widget.existingEvent == null ? 'Neuer Termin' : 'Termin bearbeiten'),
      content: SizedBox(
        width: 350,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(controller: titleController, autofocus: true,
                decoration: const InputDecoration(labelText: 'Titel', prefixIcon: Icon(Icons.event))),
              const SizedBox(height: 12),
              TextField(controller: locationController,
                decoration: const InputDecoration(labelText: 'Ort', prefixIcon: Icon(Icons.location_on_outlined))),
              const SizedBox(height: 12),
              TextField(controller: descriptionController, minLines: 2, maxLines: 4,
                decoration: const InputDecoration(labelText: 'Beschreibung', prefixIcon: Icon(Icons.notes))),
              const SizedBox(height: 12),
              OutlinedButton.icon(onPressed: pickDate,
                icon: const Icon(Icons.calendar_today), label: Text('Datum: $dateText')),
              CheckboxListTile(contentPadding: EdgeInsets.zero,
                title: const Text('Ganztägiger Termin'), value: isAllDay,
                controlAffinity: ListTileControlAffinity.leading,
                onChanged: (v) => setState(() => isAllDay = v ?? false)),
              if (!isAllDay) ...[
                OutlinedButton.icon(onPressed: () => pickTime(start: true),
                  icon: const Icon(Icons.schedule), label: Text('Beginn: ${startTime.format(context)}')),
                const SizedBox(height: 8),
                OutlinedButton.icon(onPressed: () => pickTime(start: false),
                  icon: const Icon(Icons.schedule_outlined), label: Text('Ende: ${endTime.format(context)}')),
              ],
              if (widget.allowRecurrence) ...[
                const SizedBox(height: 14),
                DropdownButtonFormField<String>(
                  initialValue: recurrence,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Wiederholung', prefixIcon: Icon(Icons.repeat)),
                  items: const [
                    DropdownMenuItem(value: 'none', child: Text('Keine')),
                    DropdownMenuItem(value: 'daily', child: Text('Täglich')),
                    DropdownMenuItem(value: 'weekly', child: Text('Wöchentlich')),
                    DropdownMenuItem(value: 'biweekly', child: Text('Alle 2 Wochen')),
                    DropdownMenuItem(value: 'monthly', child: Text('Monatlich')),
                    DropdownMenuItem(value: 'yearly', child: Text('Jährlich')),
                  ],
                  onChanged: (v) => setState(() => recurrence = v ?? 'none'),
                ),
                if (recurrence != 'none') ...[
                  const SizedBox(height: 8),
                  OutlinedButton.icon(onPressed: pickUntil,
                    icon: const Icon(Icons.event_busy), label: Text('Wiederholen bis: $untilText')),
                  if (recurrenceUntil != null)
                    TextButton(onPressed: () => setState(() => recurrenceUntil = null),
                      child: const Text('Enddatum entfernen')),
                ],
              ],
              if (error != null) ...[
                const SizedBox(height: 8),
                Text(error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Abbrechen')),
        FilledButton(onPressed: save, child: const Text('Speichern')),
      ],
    );
  }
}
