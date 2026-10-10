import 'package:flutter/material.dart';

import '../database/database_helper.dart';
import '../models/calendar_event.dart';
import '../models/todo.dart';
import '../widgets/add_event_dialog.dart';
import '../widgets/add_todo_dialog.dart';
import '../widgets/finance/purchase_dialog.dart';
import 'day_screen.dart';

class HomeScreen extends StatefulWidget {
  final VoidCallback? onOpenTodos;
  final VoidCallback? onOpenCalendar;
  final VoidCallback? onOpenFinance;

  const HomeScreen({
    super.key,
    this.onOpenTodos,
    this.onOpenCalendar,
    this.onOpenFinance,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final db = DatabaseHelper.instance;
  List<Todo> todos = [];
  List<CalendarEvent> events = [];
  Map<String, Object?>? finance;
  bool isLoading = true;
  String? errorMessage;
  String? expandedItemKey;

  @override
  void initState() {
    super.initState();
    loadDashboard();
  }

  Future<void> loadDashboard() async {
    try {
      final today = DateTime.now();
      final loadedTodos = await db.getTodos();
      final loadedEvents = await db.getEventsForDay(today);
      final loadedFinance = await db.getFinanceOverview(today);
      if (!mounted) return;
      setState(() {
        todos = loadedTodos;
        events = loadedEvents;
        finance = loadedFinance;
        errorMessage = null;
        isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        errorMessage = error.toString();
        isLoading = false;
      });
    }
  }

  bool sameDate(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  List<Todo> get todaysTodos {
    final today = DateTime.now();
    final list = todos.where((todo) =>
        !todo.isCompleted &&
        todo.dueDate != null &&
        sameDate(todo.dueDate!, today)).toList();
    list.sort((a, b) {
      final comparison = a.dueDate!.compareTo(b.dueDate!);
      return comparison != 0 ? comparison : b.priority.compareTo(a.priority);
    });
    return list;
  }

  List<Todo> get overdueTodos {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day);
    final list = todos.where((todo) =>
        !todo.isCompleted &&
        todo.dueDate != null &&
        todo.dueDate!.isBefore(start)).toList();
    list.sort((a, b) => a.dueDate!.compareTo(b.dueDate!));
    return list;
  }

  String get greeting {
    final hour = DateTime.now().hour;
    if (hour < 11) return 'Guten Morgen!';
    if (hour < 18) return 'Guten Tag!';
    return 'Guten Abend!';
  }

  String euros(int cents) {
    final sign = cents < 0 ? '−' : '';
    final abs = cents.abs();
    final whole = (abs ~/ 100).toString();
    final grouped = whole.replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (_) => '.',
    );
    return '$sign$grouped,${(abs % 100).toString().padLeft(2, '0')} €';
  }

  void toggleExpanded(String key) {
    setState(() {
      expandedItemKey = expandedItemKey == key ? null : key;
    });
  }

  Future<void> addTodo() async {
    final value = await showDialog<Todo>(
      context: context,
      builder: (_) => const AddTodoDialog(),
    );
    if (!mounted || value == null) return;
    await db.insertTodo(value);
    await loadDashboard();
  }

  Future<void> addEvent() async {
    final value = await showDialog<CalendarEvent>(
      context: context,
      builder: (_) => AddEventDialog(date: DateTime.now()),
    );
    if (!mounted || value == null) return;
    await db.insertEvent(value);
    await loadDashboard();
  }

  Future<void> addPurchase() async {
    final value = await showDialog<PurchaseResult>(
      context: context,
      builder: (_) => const PurchaseDialog(),
    );
    if (!mounted || value == null) return;
    await db.addFinancePurchase(
      title: value.title,
      amountCents: value.cents,
      category: value.category,
      date: DateTime.now(),
    );
    await loadDashboard();
  }

  Future<void> toggleTodo(Todo todo, bool completed) async {
    if (todo.id == null) return;
    await db.updateTodo(todo.copyWith(isCompleted: completed));
    if (!mounted) return;
    await loadDashboard();
  }

  Future<void> confirmDeleteTodo(Todo todo) async {
    if (todo.id == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Quest löschen?'),
        content: Text('Möchtest du „${todo.title}“ wirklich löschen?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Abbrechen'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Löschen'),
          ),
        ],
      ),
    );
    if (!mounted || confirmed != true) return;
    await db.deleteTodo(todo.id!);
    if (!mounted) return;
    expandedItemKey = null;
    await loadDashboard();
  }

  Future<void> openTodayCalendar() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => DayScreen(date: DateTime.now())),
    );
    if (!mounted) return;
    await loadDashboard();
  }

  // Alle Inhalte kommen weiterhin live aus SQLite. Die Pixel-Art ist nur
  // Dekoration: Rahmen skalieren, Icons bleiben unverzerrt.
  static const _ink = Color(0xFF4A2E1D);
  static const _mutedInk = Color(0xFF76543C);
  static const _gold = Color(0xFFBF8A42);
  static const _paper = Color(0xFFF3DEB2);
  static const _darkGreen = Color(0xFF345D35);

  Widget _sprite(String file, {double size = 42}) => Image.asset(
    'assets/images/questbook/ui/$file.png',
    width: size, height: size,
    fit: BoxFit.contain,
    filterQuality: FilterQuality.none,
  );

  // Kein Vollbild-Stretching der gemalten Rahmen: dynamisch wachsende
  // Pergamentfläche mit einzeln positionierten Pixel-Art-Verzierungen.
  Widget _framed({required Widget child, EdgeInsets padding =
      const EdgeInsets.fromLTRB(17, 17, 17, 18)}) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF8E8C7),
        border: Border.all(color: const Color(0xFF704525), width: 3),
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(color: Color(0x44352213), offset: Offset(2, 3)),
        ],
      ),
      child: Stack(children: [
        Padding(padding: padding, child: child),
        Positioned(top: 0, left: 0,
          child: IgnorePointer(child: _corner('scroll', 19))),
        Positioned(top: 0, right: 0,
          child: IgnorePointer(child: _corner('star', 19))),
      ]),
    );
  }

  Widget _corner(String file, double size) => Opacity(
    opacity: 0.75, child: _sprite(file, size: size));

  String _dateLabel(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}.'
      '${date.month.toString().padLeft(2, '0')}.'
      '${date.year}  '
      '${date.hour.toString().padLeft(2, '0')}:'
      '${date.minute.toString().padLeft(2, '0')}';

  String _iconForSection(String title) {
    if (title.contains('Schatzkammer')) return 'coins';
    if (title.contains('Kalender')) return 'calendar';
    if (title.contains('offene')) return 'warning';
    return 'scroll';
  }

  Widget sectionCard({
    required String title,
    required IconData icon,
    required Widget child,
    VoidCallback? onOpen,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: _framed(child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(children: [
            _sprite(_iconForSection(title), size: 43),
            const SizedBox(width: 6),
            Expanded(child: Text(title,
              style: const TextStyle(fontSize: 16, height: 1.2,
                  fontWeight: FontWeight.w800, color: _ink))),
            if (onOpen != null) IconButton(
              tooltip: 'Bereich öffnen',
              onPressed: onOpen,
              icon: const Icon(Icons.chevron_right, color: _ink),
              constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
            ),
          ]),
          const SizedBox(height: 6),
          const Divider(height: 13, color: _gold),
          child,
        ],
      )),
    );
  }

  Widget summaryTile(String sprite, String label, int count) {
    return Expanded(child: Container(
      padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 3),
      decoration: BoxDecoration(
        color: const Color(0xFFF5E5C4),
        border: Border.all(color: _gold, width: 2),
        borderRadius: BorderRadius.circular(9),
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        _sprite(sprite, size: 37),
        Text('$count', style: const TextStyle(fontSize: 22,
          fontWeight: FontWeight.w900, color: _ink)),
        FittedBox(fit: BoxFit.scaleDown, child: Text(label,
          maxLines: 1, style: const TextStyle(fontSize: 11,
          fontWeight: FontWeight.w700, color: _mutedInk))),
      ]),
    ));
  }

  Widget quickActions() {
    Widget action(String text, String sprite, VoidCallback onTap) =>
      Material(color: _darkGreen, borderRadius: BorderRadius.circular(9),
        child: InkWell(onTap: onTap, borderRadius: BorderRadius.circular(9),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              border: Border.all(color: _gold, width: 2),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              _sprite(sprite, size: 29),
              const SizedBox(width: 7),
              Text(text, style: const TextStyle(color: Color(0xFFFFF0C8),
                fontWeight: FontWeight.bold)),
            ]),
          ),
        ),
      );
    return Wrap(spacing: 8, runSpacing: 8, children: [
      action('Neue Quest', 'scroll', addTodo),
      action('Neuer Termin', 'calendar', addEvent),
      action('Neuer Kauf', 'pouch', addPurchase),
    ]);
  }

  Widget financeCard() {
    final data = finance;
    if (data == null) return const SizedBox.shrink();
    final budget = data['budget'] as int;
    final fixed = data['fixed'] as int;
    final spent = data['spent'] as int;
    final remaining = data['remaining'] as int;
    final used = fixed + spent;
    final fraction = budget > 0 ? (used / budget).clamp(0.0, 1.0) : 0.0;
    final percent = budget > 0
      ? (100 * used / budget).toStringAsFixed(1).replaceAll('.', ',')
      : null;
    final negative = remaining < 0;

    return sectionCard(
      title: 'Deine Schatzkammer',
      icon: Icons.account_balance_wallet_outlined,
      onOpen: widget.onOpenFinance,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Verfügbares Monatsbudget', style: TextStyle(color: _mutedInk)),
        const SizedBox(height: 4),
        Text(euros(remaining), style: const TextStyle(fontSize: 26,
          fontWeight: FontWeight.w900, color: _darkGreen).copyWith(
          color: negative ? const Color(0xFFAF4D38) : _darkGreen)),
        const SizedBox(height: 12),
        // Der Füllstand ist live und wird NICHT aus einem statischen PNG genommen.
        ClipRRect(borderRadius: BorderRadius.circular(4),
          child: Container(
            decoration: BoxDecoration(border: Border.all(
              color: const Color(0xFF875A31), width: 2)),
            child: LinearProgressIndicator(
              value: fraction, minHeight: 13,
              color: negative ? const Color(0xFFB74B39) : const Color(0xFF4B8A42),
              backgroundColor: const Color(0xFFC7A77C),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Wrap(spacing: 8, runSpacing: 4, children: [
          Text(percent == null ? 'Kein Budget festgelegt' : '$percent % verbraucht',
              style: const TextStyle(color: _mutedInk)),
          Text('Budget: ${euros(budget)}', style: const TextStyle(color: _mutedInk)),
        ]),
        const Divider(height: 24, color: _gold),
        Row(children: [const Expanded(child: Text('Fixkosten')),
          Flexible(child: Text(euros(fixed), textAlign: TextAlign.end))]),
        const SizedBox(height: 6),
        Row(children: [const Expanded(child: Text('Käufe diesen Monat')),
          Flexible(child: Text(euros(spent), textAlign: TextAlign.end))]),
        if (negative) const Padding(
          padding: EdgeInsets.only(top: 8),
          child: Text('Dein Monatsbudget ist überschritten.',
            style: TextStyle(color: Color(0xFFAF4D38))),
        ),
      ]),
    );
  }

  Widget todoList(List<Todo> items, String emptyText) {
    if (items.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Text(emptyText, style: const TextStyle(color: _mutedInk)),
      );
    }
    return Column(
      children: items.map((todo) {
        final key = 'todo:${todo.id}';
        final expanded = expandedItemKey == key;
        final overdue = todo.dueDate != null &&
            todo.dueDate!.isBefore(DateTime.now()) && !todo.isCompleted;
        final accent = overdue
            ? const Color(0xFFAE4B38)
            : todo.priority == 3
                ? const Color(0xFFA45839)
                : todo.priority == 2
                    ? const Color(0xFFA67B36)
                    : const Color(0xFF467343);

        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF1D5),
            border: Border.all(color: const Color(0xFF9C6C3C), width: 2),
            borderRadius: BorderRadius.circular(9),
          ),
          child: Column(children: [
            InkWell(
              borderRadius: BorderRadius.circular(7),
              onTap: () => toggleExpanded(key),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 9, 8, 9),
                child: Row(children: [
                  SizedBox(width: 42, height: 46,
                    child: Center(child: Checkbox(
                      value: todo.isCompleted,
                      activeColor: _darkGreen,
                      onChanged: (value) =>
                          toggleTodo(todo, value ?? false),
                    ))),
                  const SizedBox(width: 4),
                  _sprite(overdue ? 'warning' : 'scroll', size: 33),
                  const SizedBox(width: 8),
                  Expanded(child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(todo.title, softWrap: true,
                        style: TextStyle(
                          color: _ink, fontWeight: FontWeight.w800,
                          fontSize: 14,
                          decoration: todo.isCompleted
                              ? TextDecoration.lineThrough : null,
                        )),
                      if (todo.dueDate != null) ...[
                        const SizedBox(height: 4),
                        Text(_dateLabel(todo.dueDate!),
                          style: TextStyle(fontSize: 11, color: accent)),
                      ],
                    ],
                  )),
                  const SizedBox(width: 2),
                  Icon(expanded
                      ? Icons.keyboard_arrow_up
                      : Icons.keyboard_arrow_down, color: _ink),
                ]),
              ),
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 200),
              child: expanded
                  ? Padding(
                      padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Divider(color: _gold),
                          Text(todo.description.isEmpty
                              ? 'Keine Beschreibung vorhanden.'
                              : todo.description,
                              style: const TextStyle(color: _ink)),
                          Align(
                            alignment: Alignment.centerRight,
                            child: IconButton(
                              tooltip: 'Quest löschen',
                              onPressed: () => confirmDeleteTodo(todo),
                              icon: const Icon(Icons.delete_outline,
                                  color: Color(0xFF97452E)),
                            ),
                          ),
                        ],
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          ]),
        );
      }).toList(),
    );
  }

  Widget eventList() {
    if (events.isEmpty) return const Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Text('Heute stehen keine Termine an.',
        style: TextStyle(color: _mutedInk)),
    );
    // getEventsForDay löst wiederkehrende Termine bereits auf.
    return Column(children: events.map((event) {
      final key = 'event:${event.id}:${CalendarEvent.dateKey(event.occurrenceDate ?? event.date)}';
      final expanded = expandedItemKey == key;
      return Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFF9EACD),
          border: Border.all(color: const Color(0xFFB58D55), width: 2),
          borderRadius: BorderRadius.circular(9),
        ),
        child: Column(children: [
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 10),
            onTap: () => toggleExpanded(key),
            leading: _sprite('calendar', size: 38),
            title: Text(event.title, style: const TextStyle(color: _ink,
              fontWeight: FontWeight.bold)),
            subtitle: Text(event.timeLabel, style: const TextStyle(color: _mutedInk)),
            trailing: Icon(expanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
              color: _ink),
          ),
          AnimatedSize(duration: const Duration(milliseconds: 200),
            child: expanded ? Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Divider(color: _gold),
                if (event.location.isNotEmpty) Row(children: [
                  const Icon(Icons.location_on_outlined, color: _ink, size: 18),
                  const SizedBox(width: 8),
                  Expanded(child: Text(event.location,
                    style: const TextStyle(color: _ink))),
                ]),
                if (event.description.isNotEmpty) Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(event.description,
                    style: const TextStyle(color: _ink))),
                Align(alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: openTodayCalendar,
                    icon: const Icon(Icons.edit_calendar_outlined),
                    label: const Text('Im Tageskalender verwalten', softWrap: true),
                  ),
                ),
              ]),
            ) : const SizedBox.shrink(),
          ),
        ]),
      );
    }).toList());
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) return const Center(child: CircularProgressIndicator());
    if (errorMessage != null) return Center(child: Padding(
      padding: const EdgeInsets.all(20),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Text('Fehler beim Laden:\n$errorMessage', textAlign: TextAlign.center),
        const SizedBox(height: 12),
        OutlinedButton(onPressed: loadDashboard, child: const Text('Erneut versuchen')),
      ]),
    ));

    final todayText = MaterialLocalizations.of(context)
        .formatMediumDate(DateTime.now());
    return Theme(
      data: Theme.of(context).copyWith(
        textTheme: Theme.of(context).textTheme.apply(
          bodyColor: _ink, displayColor: _ink),
        iconTheme: const IconThemeData(color: _ink),
      ),
      child: ColoredBox(color: _paper,
        child: RefreshIndicator(
          onRefresh: loadDashboard,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(17, 18, 17, 32),
            children: [
              Center(child: Text(todayText, style: const TextStyle(
                color: _mutedInk, fontWeight: FontWeight.bold))),
              const SizedBox(height: 7),
              Center(child: Image.asset(
                'assets/images/questbook/questbook_open.png',
                height: 90, fit: BoxFit.contain,
                filterQuality: FilterQuality.none,
              )),
              const SizedBox(height: 5),
              Text('$greeting 🌻', style: const TextStyle(
                fontSize: 25, color: _ink, fontWeight: FontWeight.w900)),
              const Text('Schauen wir, was heute in deinem Dorf ansteht.',
                style: TextStyle(color: _mutedInk)),
              const SizedBox(height: 18),
              const Text('Schnellaktionen', style: TextStyle(
                fontSize: 17, color: _ink, fontWeight: FontWeight.w800)),
              const SizedBox(height: 9),
              quickActions(),
              const SizedBox(height: 16),
              Row(children: [
                summaryTile('scroll', 'Quests', todaysTodos.length),
                const SizedBox(width: 6),
                summaryTile('warning', 'Überfällig', overdueTodos.length),
                const SizedBox(width: 6),
                summaryTile('calendar', 'Termine', events.length),
              ]),
              const SizedBox(height: 18),
              financeCard(),
              if (overdueTodos.isNotEmpty) sectionCard(
                title: 'Noch offene Quests', icon: Icons.warning_amber_rounded,
                onOpen: widget.onOpenTodos,
                child: todoList(overdueTodos, ''),
              ),
              sectionCard(
                title: 'Deine heutigen Quests', icon: Icons.task_alt,
                onOpen: widget.onOpenTodos,
                child: todoList(todaysTodos,
                  'Heute sind keine Aufgaben fällig. 🌿'),
              ),
              sectionCard(
                title: 'Heute im Kalender', icon: Icons.calendar_month_outlined,
                onOpen: openTodayCalendar, child: eventList(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
