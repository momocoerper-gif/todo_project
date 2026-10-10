import 'package:flutter/material.dart';

import '../database/database_helper.dart';
import '../models/calendar_event.dart';
import '../models/todo.dart';
import '../theme/app_theme.dart';
import '../theme/finance_colors.dart';
import '../widgets/add_event_dialog.dart';
import '../widgets/add_todo_dialog.dart';
import '../widgets/finance/purchase_dialog.dart';
import '../widgets/todo_tile.dart';
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

  Widget sectionCard({
    required String title,
    required IconData icon,
    required Widget child,
    VoidCallback? onOpen,
  }) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(children: [
              Icon(icon, color: scheme.primary),
              const SizedBox(width: 8),
              Expanded(child: Text(title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              )),
              if (onOpen != null) IconButton(
                tooltip: 'Bereich öffnen',
                onPressed: onOpen,
                icon: const Icon(Icons.chevron_right),
              ),
            ]),
            const SizedBox(height: 8),
            child,
          ],
        ),
      ),
    );
  }

  Widget summaryTile(IconData icon, String label, int count, Color color) {
    return Expanded(
      child: Card(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 3),
          child: Column(children: [
            Icon(icon, color: color),
            const SizedBox(height: 4),
            Text('$count', style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            )),
            Text(label, textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.labelSmall),
          ]),
        ),
      ),
    );
  }

  Widget quickActions() {
    Widget action(String label, IconData icon, VoidCallback handler) {
      return OutlinedButton.icon(
        onPressed: handler,
        icon: Icon(icon, size: 19),
        label: Text(label),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
        ),
      );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        action('Neue Quest', Icons.add_task, addTodo),
        action('Neuer Termin', Icons.event_available_outlined, addEvent),
        action('Neuer Kauf', Icons.shopping_bag_outlined, addPurchase),
      ],
    );
  }

  Widget financeCard() {
    final scheme = Theme.of(context).colorScheme;
    final data = finance;
    if (data == null) return const SizedBox.shrink();
    final budget = data['budget'] as int;
    final fixed = data['fixed'] as int;
    final spent = data['spent'] as int;
    final remaining = data['remaining'] as int;
    final used = fixed + spent;
    final fraction = budget > 0 ? (used / budget).clamp(0.0, 1.0) : 0.0;
    final percent = budget > 0 ? (100 * used / budget).toStringAsFixed(1).replaceAll('.', ',') : null;

    return sectionCard(
      title: 'Deine Schatzkammer',
      icon: Icons.account_balance_wallet_outlined,
      onOpen: widget.onOpenFinance,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Verfügbares Monatsbudget',
            style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 4),
          Text(euros(remaining),
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: remaining < 0 ? scheme.error : scheme.primary,
            )),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: fraction,
            minHeight: 12,
            borderRadius: BorderRadius.circular(7),
            color: remaining < 0 ? scheme.error : scheme.primary,
            backgroundColor: scheme.surfaceContainerHighest,
          ),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(child: Text(
              percent == null ? 'Kein Budget festgelegt' : '$percent % verbraucht',
              style: Theme.of(context).textTheme.bodySmall,
            )),
            Text('Budget: ${euros(budget)}',
              style: Theme.of(context).textTheme.bodySmall),
          ]),
          const Divider(height: 24),
          Row(children: [
            const Expanded(child: Text('Fixkosten')),
            Text(euros(fixed)),
          ]),
          const SizedBox(height: 5),
          Row(children: [
            const Expanded(child: Text('Käufe diesen Monat')),
            Text(euros(spent)),
          ]),
          if (remaining < 0) Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text('Dein Monatsbudget ist überschritten.',
              style: TextStyle(color: scheme.error)),
          ),
        ],
      ),
    );
  }

  Widget todoList(List<Todo> items, String emptyText) {
    if (items.isEmpty) return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(emptyText),
    );
    return Column(
      children: items.map((todo) {
        final key = 'todo:${todo.id}';
        return TodoTile(
          key: ValueKey(key),
          todo: todo,
          isExpanded: expandedItemKey == key,
          onTap: () => toggleExpanded(key),
          onCompletedChanged: (done) => toggleTodo(todo, done),
          onDelete: () => confirmDeleteTodo(todo),
        );
      }).toList(),
    );
  }

  Widget eventList() {
    if (events.isEmpty) return const Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Text('Heute stehen keine Termine an.'),
    );

    // Wiederholungen werden bereits durch getEventsForDay aufgelöst.
    // Änderungen und Löschen einzelner Wiederholungen erfolgen im DayScreen.
    return Column(children: events.map((event) {
      final key = 'event:${event.id}:${CalendarEvent.dateKey(event.occurrenceDate ?? event.date)}';
      final expanded = expandedItemKey == key;
      final scheme = Theme.of(context).colorScheme;
      return Container(
        margin: const EdgeInsets.only(bottom: 9),
        decoration: BoxDecoration(
          color: TodoTileStyle.backgroundColor(context),
          borderRadius: BorderRadius.circular(TodoTileStyle.borderRadius),
          border: Border.all(
            color: TodoTileStyle.borderColor(context),
            width: TodoTileStyle.borderWidth,
          ),
        ),
        child: Column(children: [
          ListTile(
            onTap: () => toggleExpanded(key),
            leading: Icon(event.isAllDay ? Icons.wb_sunny_outlined : Icons.event_outlined,
              color: scheme.primary),
            title: Text(event.title),
            subtitle: Text(event.timeLabel),
            trailing: Icon(expanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 200),
            child: expanded ? Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Divider(),
                if (event.location.isNotEmpty) Row(children: [
                  const Icon(Icons.location_on_outlined, size: 18),
                  const SizedBox(width: 8),
                  Expanded(child: Text(event.location)),
                ]),
                if (event.description.isNotEmpty) Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(event.description),
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: openTodayCalendar,
                    icon: const Icon(Icons.edit_calendar_outlined),
                    label: const Text('Im Tageskalender verwalten'),
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

    final scheme = Theme.of(context).colorScheme;
    final todayText = MaterialLocalizations.of(context).formatMediumDate(DateTime.now());
    return RefreshIndicator(
      onRefresh: loadDashboard,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: [
          Text(todayText, style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: scheme.onSurfaceVariant,
          )),
          const SizedBox(height: 4),
          Text('$greeting 🌻',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
            )),
          const SizedBox(height: 4),
          const Text('Schauen wir, was heute in deinem Dorf ansteht.'),
          const SizedBox(height: 18),
          Text('Schnellaktionen', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          quickActions(),
          const SizedBox(height: 18),
          Row(children: [
            summaryTile(Icons.checklist, 'Quests', todaysTodos.length, scheme.primary),
            const SizedBox(width: 8),
            summaryTile(Icons.warning_amber_rounded, 'Überfällig', overdueTodos.length, scheme.error),
            const SizedBox(width: 8),
            summaryTile(Icons.calendar_month, 'Termine', events.length, scheme.secondary),
          ]),
          const SizedBox(height: 16),
          financeCard(),
          if (overdueTodos.isNotEmpty) sectionCard(
            title: 'Noch offene Quests',
            icon: Icons.warning_amber_rounded,
            onOpen: widget.onOpenTodos,
            child: todoList(overdueTodos, ''),
          ),
          sectionCard(
            title: 'Deine heutigen Quests',
            icon: Icons.task_alt,
            onOpen: widget.onOpenTodos,
            child: todoList(todaysTodos, 'Heute sind keine Aufgaben fällig. 🌿'),
          ),
          sectionCard(
            title: 'Heute im Kalender',
            icon: Icons.calendar_month_outlined,
            onOpen: openTodayCalendar,
            child: eventList(),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}
