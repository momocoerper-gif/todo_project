
import 'package:flutter/material.dart';

import '../database/database_helper.dart';
import '../models/calendar_event.dart';
import '../widgets/add_event_dialog.dart';

class DayScreen extends StatefulWidget {
  final DateTime date;

  const DayScreen({
    super.key,
    required this.date,
  });

  @override
  State<DayScreen> createState() => _DayScreenState();
}

class _DayScreenState extends State<DayScreen> {
  List<CalendarEvent> events = [];
  int? expandedEventId;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadEvents();
  }

  Future<void> loadEvents() async {
    final data = await DatabaseHelper.instance
        .getEventsForDay(widget.date);

    if (!mounted) return;

    setState(() {
      events = data;
      isLoading = false;
    });
  }

  Future<void> addEvent() async {
    final newEvent = await showDialog<CalendarEvent>(
      context: context,
      builder: (context) => AddEventDialog(
        date: widget.date,
      ),
    );

    if (newEvent == null) return;

    await DatabaseHelper.instance.insertEvent(newEvent);
    await loadEvents();
  }

  // Entscheiden, ob eine einzelne Wiederholung oder die ganze Serie gemeint ist.
  Future<bool?> chooseScope(String action) async {
    return showDialog<bool>(context: context, builder: (dialogContext) => AlertDialog(
      title: Text('Wiederkehrenden Termin $action'),
      content: const Text('Soll nur dieser Termin oder die gesamte Serie geändert werden?'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Abbrechen')),
        TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Nur diesen')),
        FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('Gesamte Serie')),
      ],
    ));
  }

  Future<void> editEvent(CalendarEvent occurrence) async {
    final isSeries = occurrence.recurrence != 'none';
    final bool editSeries;
    if (isSeries) {
      final choice = await chooseScope('bearbeiten');
      if (choice == null || !mounted) return;
      editSeries = choice;
    } else {
      editSeries = true;
    }

    final CalendarEvent? source = editSeries
        ? await DatabaseHelper.instance.getSeriesEvent(occurrence.id!)
        : occurrence;
    if (!mounted || source == null) return;

    final changed = await showDialog<CalendarEvent>(
      context: context,
      builder: (_) => AddEventDialog(
        date: source.date,
        existingEvent: source,
        allowRecurrence: editSeries,
      ),
    );
    if (changed == null || !mounted) return;

    if (editSeries) {
      final ruleChanged = source.recurrence != changed.recurrence ||
          CalendarEvent.dateKey(source.date) != CalendarEvent.dateKey(changed.date) ||
          (source.recurrenceUntil == null ? null : CalendarEvent.dateKey(source.recurrenceUntil!)) !=
          (changed.recurrenceUntil == null ? null : CalendarEvent.dateKey(changed.recurrenceUntil!));
      if (source.recurrence != 'none' && ruleChanged) {
        final proceed = await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text('Wiederholung ändern?'),
            content: const Text('Bei einer Änderung des Startdatums oder der Wiederholungsregel werden bisherige Ausnahmen der Serie zurückgesetzt.'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Abbrechen')),
              FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('Änderung übernehmen')),
            ],
          ),
        );
        if (proceed != true || !mounted) return;
      }
      await DatabaseHelper.instance.updateEvent(changed);
    } else {
      await DatabaseHelper.instance.updateEventOccurrence(occurrence, changed);
    }
    if (!mounted) return;
    await loadEvents();
  }

  Future<void> deleteEvent(CalendarEvent occurrence) async {
    final isSeries = occurrence.recurrence != 'none';
    final bool deleteSeries;
    if (isSeries) {
      final choice = await chooseScope('löschen');
      if (choice == null || !mounted) return;
      deleteSeries = choice;
    } else {
      deleteSeries = true;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Termin löschen?'),
        content: Text(deleteSeries && isSeries
            ? 'Möchtest du die gesamte Terminserie wirklich löschen?'
            : 'Möchtest du diesen Termin wirklich löschen?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Abbrechen')),
          FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('Löschen')),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    if (deleteSeries) {
      await DatabaseHelper.instance.deleteEvent(occurrence.id!);
    } else {
      await DatabaseHelper.instance.deleteEventOccurrence(occurrence);
    }
    if (!mounted) return;
    setState(() => expandedEventId = null);
    await loadEvents();
  }

  void toggleEvent(int? id) {
    setState(() {
      expandedEventId =
          expandedEventId == id ? null : id;
    });
  }

  Widget buildEventTile(CalendarEvent event) {
    final colors = Theme.of(context).colorScheme;
    final isExpanded = expandedEventId == event.id;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        children: [
          ListTile(
            onTap: () => toggleEvent(event.id),

            leading: Icon(
              event.isAllDay
                  ? Icons.wb_sunny_outlined
                  : Icons.event,
              color: colors.primary,
            ),

            title: Text(event.title),

            subtitle: Text(event.timeLabel),

            trailing: Icon(
              isExpanded
                  ? Icons.keyboard_arrow_up
                  : Icons.keyboard_arrow_down,
            ),
          ),

          AnimatedSize(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            child: isExpanded
                ? Padding(
                    padding: const EdgeInsets.fromLTRB(
                      16, 0, 16, 12,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Divider(),

                        const SizedBox(height: 8),

                        Row(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.location_on_outlined),
                            const SizedBox(width: 8),

                            Expanded(
                              child: Text(
                                event.location.isEmpty
                                    ? 'Kein Ort angegeben'
                                    : event.location,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 12),

                        Row(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.notes),
                            const SizedBox(width: 8),

                            Expanded(
                              child: Text(
                                event.description.isEmpty
                                    ? 'Keine Beschreibung vorhanden'
                                    : event.description,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 12),

                         if (event.recurrence != 'none') ...[
                           Row(children: [
                             const Icon(Icons.repeat),
                             const SizedBox(width: 8),
                             Expanded(child: Text(event.recurrenceLabel)),
                           ]),
                           const SizedBox(height: 8),
                         ],
                         Align(
                           alignment: Alignment.centerRight,
                           child: Row(
                             mainAxisSize: MainAxisSize.min,
                             children: [
                               IconButton(
                                 tooltip: 'Termin bearbeiten',
                                 icon: const Icon(Icons.edit_outlined),
                                 onPressed: event.id == null ? null : () => editEvent(event),
                               ),
                               IconButton(
                                 tooltip: 'Termin löschen',
                                 icon: const Icon(Icons.delete_outline),
                                 onPressed: event.id == null ? null : () => deleteEvent(event),
                               ),
                             ],
                           ),
                         ),
                      ],
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dateText =
        MaterialLocalizations.of(context).formatMediumDate(
          widget.date,
        );

    return Scaffold(
      appBar: AppBar(
        title: Text(
          dateText,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            shadows: [
              Shadow(
                color: Colors.black,
                blurRadius: 6,
              ),
            ],
          ),
        ),

        foregroundColor: Colors.white,

        flexibleSpace: Builder(
          builder: (context) {
            final isDark =
                Theme.of(context).brightness == Brightness.dark;

            return Stack(
              fit: StackFit.expand,
              children: [
                Image.asset(
                  isDark
                      ? 'assets/images/city_night.png'
                      : 'assets/images/city_day.png',
                  fit: BoxFit.cover,
                  alignment: Alignment.center,
                  filterQuality: FilterQuality.none,
                ),

                Container(
                  color: Colors.black.withValues(alpha: 0.25),
                ),
              ],
            );
          },
        ),

        toolbarHeight: 85,
      ),

      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : events.isEmpty
              ? const Center(
                  child: Text(
                    'Für diesen Tag gibt es noch keine Termine.',
                    textAlign: TextAlign.center,
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: events.map(buildEventTile).toList(),
                ),

      floatingActionButton: FloatingActionButton(
        onPressed: addEvent,
        tooltip: 'Neuen Termin erstellen',
        child: const Icon(Icons.add),
      ),
    );
  }
}
