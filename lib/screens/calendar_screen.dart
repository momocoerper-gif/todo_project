import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import '../database/database_helper.dart';
import '../models/calendar_event.dart';
import 'day_screen.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});
  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime focusedDay = DateTime.now();
  List<CalendarEvent> events = [];

  @override
  void initState() {
    super.initState();
    loadEvents();
  }

  Future<void> loadEvents() async {
    final first = DateTime(focusedDay.year, focusedDay.month - 1, 1);
    final last = DateTime(focusedDay.year, focusedDay.month + 2, 0);
    final result = await DatabaseHelper.instance.getEventsForRange(first, last);
    if (!mounted) return;
    setState(() => events = result);
  }

  List<CalendarEvent> eventsForDay(DateTime day) {
    final key = CalendarEvent.dateKey(day);
    return events.where((e) => CalendarEvent.dateKey(e.date) == key).toList();
  }

  Future<void> openDay(DateTime day) async {
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => DayScreen(date: day)));
    if (!mounted) return;
    await loadEvents();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(child: Padding(
          padding: const EdgeInsets.all(12),
          child: TableCalendar<CalendarEvent>(
            locale: 'de_DE',
            firstDay: DateTime(2000), lastDay: DateTime(2100),
            focusedDay: focusedDay,
            startingDayOfWeek: StartingDayOfWeek.monday,
            calendarFormat: CalendarFormat.month,
            availableGestures: AvailableGestures.horizontalSwipe,
            eventLoader: eventsForDay,
            selectedDayPredicate: (day) => isSameDay(day, DateTime.now()),
            onDaySelected: (selectedDay, newFocusedDay) {
              focusedDay = newFocusedDay;
              openDay(selectedDay);
            },
            onPageChanged: (day) {
              focusedDay = day;
              loadEvents();
            },
            headerStyle: const HeaderStyle(formatButtonVisible: false, titleCentered: true),
            calendarStyle: CalendarStyle(
              todayDecoration: BoxDecoration(color: colors.primaryContainer, shape: BoxShape.circle),
              todayTextStyle: TextStyle(color: colors.onPrimaryContainer),
              markerDecoration: BoxDecoration(color: colors.primary, shape: BoxShape.circle),
              weekendTextStyle: TextStyle(color: colors.onSurface),
              outsideTextStyle: TextStyle(color: colors.onSurfaceVariant),
            ),
          ),
        )),
        const SizedBox(height: 16),
        Text('Tippe auf einen Tag, um seine Termine zu sehen.',
          textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyMedium),
      ],
    );
  }
}
