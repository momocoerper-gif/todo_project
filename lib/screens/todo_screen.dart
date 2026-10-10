
import 'package:flutter/material.dart';

import '../database/database_helper.dart';
import '../models/todo.dart';
import '../widgets/add_todo_dialog.dart';
import '../widgets/todo_tile.dart';

enum TodoSortMode {
  recommended,
  priority,
  dueDate,
  alphabetical,
}

class TodoScreen extends StatefulWidget {
  const TodoScreen({super.key});

  @override
  State<TodoScreen> createState() => _TodoScreenState();
}

class _TodoScreenState extends State<TodoScreen> {
  final db = DatabaseHelper.instance;
  TodoSortMode sortMode = TodoSortMode.recommended;
  bool showCompleted = true;

  List<Todo> todos = [];
  bool isLoading = true;

  // ID der aktuell ausgeklappten Aufgabe
  int? expandedTodoId;

  @override
  void initState() {
    super.initState();
    loadTodos();
  }

  //sortieren der To-Dos
  List<Todo> get sortedTodos {
    final result = todos.where((todo) {
      return showCompleted || !todo.isCompleted;
    }).toList();

    final now = DateTime.now();

    int compareDate(Todo a, Todo b) {
      if (a.dueDate == null && b.dueDate == null) return 0;
      if (a.dueDate == null) return 1;
      if (b.dueDate == null) return -1;

      return a.dueDate!.compareTo(b.dueDate!);
    }

    int comparePriority(Todo a, Todo b) {
      return b.priority.compareTo(a.priority);
    }

    bool isOverdue(Todo todo) {
      return !todo.isCompleted &&
          todo.dueDate != null &&
          todo.dueDate!.isBefore(now);
    }

    result.sort((a, b) {
      // Erledigte Quests stehen grundsätzlich unten.
      if (a.isCompleted != b.isCompleted) {
        return a.isCompleted ? 1 : -1;
      }

      int comparison = 0;

      switch (sortMode) {
        case TodoSortMode.recommended:
          // Zuerst überfällige Quests
          final aOverdue = isOverdue(a);
          final bOverdue = isOverdue(b);

          if (aOverdue != bOverdue) {
            return aOverdue ? -1 : 1;
          }

          // Danach chronologisch
          comparison = compareDate(a, b);

          if (comparison == 0) {
            comparison = comparePriority(a, b);
          }

        case TodoSortMode.priority:
          comparison = comparePriority(a, b);

          if (comparison == 0) {
            comparison = compareDate(a, b);
          }

        case TodoSortMode.dueDate:
          comparison = compareDate(a, b);

          if (comparison == 0) {
            comparison = comparePriority(a, b);
          }

        case TodoSortMode.alphabetical:
          comparison = a.title.toLowerCase().compareTo(
            b.title.toLowerCase(),
          );
      }

      // Stabiler Tie-Breaker
      if (comparison == 0) {
        comparison = a.title.toLowerCase().compareTo(
          b.title.toLowerCase(),
        );
      }

      if (comparison == 0) {
        comparison = (a.id ?? 0).compareTo(b.id ?? 0);
      }

      return comparison;
    });

    return result;
  }
  
  Widget buildSortControls() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DropdownButtonFormField<TodoSortMode>(
            initialValue: sortMode,
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: 'Quests sortieren nach',
              prefixIcon: Icon(Icons.sort),
            ),
            items: const [
              DropdownMenuItem(
                value: TodoSortMode.recommended,
                child: Text('Empfohlen'),
              ),
              DropdownMenuItem(
                value: TodoSortMode.priority,
                child: Text('Priorität'),
              ),
              DropdownMenuItem(
                value: TodoSortMode.dueDate,
                child: Text('Fälligkeit'),
              ),
              DropdownMenuItem(
                value: TodoSortMode.alphabetical,
                child: Text('Alphabetisch'),
              ),
            ],
            onChanged: (value) {
              if (value == null) return;

              setState(() {
                sortMode = value;
              });
            },
          ),

          const SizedBox(height: 8),

          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Erledigte Quests anzeigen'),
            value: showCompleted,
            onChanged: (value) {
              setState(() {
                showCompleted = value;
              });
            },
          ),
        ],
      ),
    );
  }

  // Datum und Uhrzeit formatieren
  String formatDate(DateTime date) {
    String pad(int value) => value.toString().padLeft(2, '0');

    return '${pad(date.day)}.${pad(date.month)}.${date.year} '
        '${pad(date.hour)}:${pad(date.minute)}';
  }

  // Aufgaben aus SQLite laden
  Future<void> loadTodos() async {
    final data = await db.getTodos();

    if (!mounted) return;

    setState(() {
      todos = data;
      isLoading = false;
    });
  }

  // Dialog öffnen und neue Aufgabe speichern
  Future<void> addTodo() async {
    final newTodo = await showDialog<Todo>(
      context: context,
      builder: (context) => const AddTodoDialog(),
    );

    // Bei Abbrechen wird null zurückgegeben.
    if (newTodo == null) return;

    await db.insertTodo(newTodo);
    await loadTodos();
  }

  // Vorhandene Quest bearbeiten und unter derselben ID speichern.
  Future<void> editTodo(Todo todo) async {
    final editedTodo = await showDialog<Todo>(
      context: context,
      builder: (context) => AddTodoDialog(existingTodo: todo),
    );

    if (!mounted || editedTodo == null) return;

    await db.updateTodo(editedTodo);
    await loadTodos();
  }

  // Erledigt-Status verändern
  Future<void> toggleTodo(
    Todo todo,
    bool completed,
  ) async {
    final updatedTodo = todo.copyWith(
      isCompleted: completed,
    );

    await db.updateTodo(updatedTodo);

    if (!mounted) return;
    await loadTodos();
  }

  // Aufgabe löschen
  Future<void> confirmDeleteTodo(Todo todo) async {
    if (todo.id == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.delete_outline),
              SizedBox(width: 8),
              Text('Quest löschen?'),
            ],
          ),

          content: Text(
            'Möchtest du die Quest "${todo.title}" '
            'wirklich löschen?\n\n'
            'Diese Aktion kann nicht rückgängig gemacht werden.',
          ),

          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
              child: const Text('Abbrechen'),
            ),

            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor:
                    Theme.of(dialogContext).colorScheme.error,
                foregroundColor:
                    Theme.of(dialogContext).colorScheme.onError,
              ),
              onPressed: () {
                Navigator.of(dialogContext).pop(true);
              },
              child: const Text('Löschen'),
            ),
          ],
        );
      },
    );

    // Bei Abbrechen, Zurück-Taste oder Tippen außerhalb
    // wird nichts gelöscht.
    if (confirmed != true || !mounted) return;

    await removeTodo(todo.id!);
  }

  Future<void> removeTodo(int id) async {
    await db.deleteTodo(id);

    if (expandedTodoId == id) {
      expandedTodoId = null;
    }

    await loadTodos();
  }

  // Beschreibung öffnen oder schließen
  void toggleExpanded(int? id) {
    setState(() {
      expandedTodoId =
          expandedTodoId == id ? null : id;
    });
  }

  // Einzelne Aufgabe darstellen
  Widget buildTodoTile(Todo todo) {
    return TodoTile(
      key: ValueKey(todo.id),
      todo: todo,

      isExpanded: expandedTodoId == todo.id,

      onTap: () {
        toggleExpanded(todo.id);
      },

      onCompletedChanged: (completed) {
        toggleTodo(todo, completed);
      },

      onEdit: () => editTodo(todo),

      onDelete: () {
        confirmDeleteTodo(todo);
      },
    );
  }

  
  @override
  Widget build(BuildContext context) {
    final visibleTodos = sortedTodos;

    return Scaffold(
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Sortierung und Filter
                buildSortControls(),

                if (todos.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(
                      child: Text(
                        'Noch keine Quests vorhanden.',
                      ),
                    ),
                  )
                else if (visibleTodos.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(
                      child: Text(
                        'Keine Quests für diesen Filter.',
                      ),
                    ),
                  )
                else
                  ...visibleTodos.map(buildTodoTile),
              ],
            ),

      floatingActionButton: FloatingActionButton(
        onPressed: addTodo,
        child: const Icon(Icons.add),
      ),
    );
  }
}
