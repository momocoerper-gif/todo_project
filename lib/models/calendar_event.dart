class CalendarEvent {
  final int? id;
  final String title;
  final String description;
  final String location;
  final DateTime date;
  final int? startMinute;
  final int? endMinute;
  final bool isAllDay;
  // none, daily, weekly, biweekly, monthly, yearly
  final String recurrence;
  final DateTime? recurrenceUntil;
  // Ursprünglicher Tag einer einzelnen Serien-Wiederholung.
  final DateTime? occurrenceDate;

  const CalendarEvent({
    this.id,
    required this.title,
    this.description = '',
    this.location = '',
    required this.date,
    this.startMinute,
    this.endMinute,
    this.isAllDay = false,
    this.recurrence = 'none',
    this.recurrenceUntil,
    this.occurrenceDate,
  });

  static String dateKey(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  static DateTime onlyDate(DateTime date) => DateTime(date.year, date.month, date.day);

  Map<String, Object?> toMap() => {
    'id': id,
    'title': title,
    'description': description,
    'location': location,
    'event_date': dateKey(date),
    'start_minute': isAllDay ? null : startMinute,
    'end_minute': isAllDay ? null : endMinute,
    'is_all_day': isAllDay ? 1 : 0,
    'recurrence': recurrence,
    'recurrence_until': recurrenceUntil == null ? null : dateKey(recurrenceUntil!),
  };

  factory CalendarEvent.fromMap(Map<String, Object?> map) => CalendarEvent(
    id: map['id'] as int?,
    title: map['title'] as String,
    description: map['description'] as String? ?? '',
    location: map['location'] as String? ?? '',
    date: DateTime.parse(map['event_date'] as String),
    startMinute: map['start_minute'] as int?,
    endMinute: map['end_minute'] as int?,
    isAllDay: map['is_all_day'] == 1,
    recurrence: map['recurrence'] as String? ?? 'none',
    recurrenceUntil: map['recurrence_until'] == null
        ? null : DateTime.parse(map['recurrence_until'] as String),
  );

  CalendarEvent at(DateTime shownDate, {DateTime? originalDate}) => CalendarEvent(
    id: id,
    title: title,
    description: description,
    location: location,
    date: shownDate,
    startMinute: startMinute,
    endMinute: endMinute,
    isAllDay: isAllDay,
    recurrence: recurrence,
    recurrenceUntil: recurrenceUntil,
    occurrenceDate: originalDate,
  );

  bool occursOn(DateTime day) {
    final start = onlyDate(date);
    final target = onlyDate(day);
    if (target.isBefore(start)) return false;
    if (recurrenceUntil != null && target.isAfter(onlyDate(recurrenceUntil!))) return false;
    if (recurrence == 'none') return target == start;
    final difference = DateTime.utc(target.year, target.month, target.day)
        .difference(DateTime.utc(start.year, start.month, start.day)).inDays;
    switch (recurrence) {
      case 'daily': return true;
      case 'weekly': return difference % 7 == 0;
      case 'biweekly': return difference % 14 == 0;
      case 'monthly': return target.day == start.day;
      case 'yearly': return target.day == start.day && target.month == start.month;
      default: return false;
    }
  }

  String get recurrenceLabel {
    switch (recurrence) {
      case 'daily': return 'Täglich';
      case 'weekly': return 'Wöchentlich';
      case 'biweekly': return 'Alle 2 Wochen';
      case 'monthly': return 'Monatlich';
      case 'yearly': return 'Jährlich';
      default: return 'Keine Wiederholung';
    }
  }

  String get timeLabel {
    if (isAllDay) return 'Ganztägig';
    String format(int? minutes) => minutes == null ? '--:--'
        : '${(minutes ~/ 60).toString().padLeft(2, '0')}:${(minutes % 60).toString().padLeft(2, '0')}';
    return '${format(startMinute)}–${format(endMinute)}';
  }
}
