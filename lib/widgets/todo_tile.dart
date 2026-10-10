
import 'package:flutter/material.dart';

import '../models/todo.dart';
import '../theme/app_theme.dart';

class TodoTile extends StatelessWidget {
  final Todo todo;
  final bool isExpanded;
  final VoidCallback onTap;
  final ValueChanged<bool> onCompletedChanged;
  final VoidCallback onDelete;
  final VoidCallback? onEdit;

  const TodoTile({
    super.key,
    required this.todo,
    required this.isExpanded,
    required this.onTap,
    required this.onCompletedChanged,
    required this.onDelete,
    this.onEdit,
  });

Color priorityColor(int priority) {
    switch (priority) {
      case 3:
        return const Color(0xFFD75E5E);
      case 2:
        return const Color(0xFFE5AF55);
      case 1:
        return const Color(0xFF83AB79);
      default:
        return const Color(0xFFE5AF55);
    }
  }

  String formatDate(DateTime date) {
    String pad(int value) => value.toString().padLeft(2, '0');

    return '${pad(date.day)}.${pad(date.month)}.${date.year} '
        '${pad(date.hour)}:${pad(date.minute)}';
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    final isOverdue =
        todo.dueDate != null &&
        DateTime.now().isAfter(todo.dueDate!) &&
        !todo.isCompleted;

    final titleColor = isOverdue
        ? TodoTileStyle.overdueColor(context)
        : TodoTileStyle.titleColor(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),

      decoration: BoxDecoration(
        color: TodoTileStyle.backgroundColor(context),

        borderRadius: BorderRadius.circular(
          TodoTileStyle.borderRadius,
        ),

        border: Border.all(
          color: TodoTileStyle.borderColor(context),
          width: TodoTileStyle.borderWidth,
        ),
      ),

      child: Column(
        children: [
          ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: TodoTileStyle.horizontalPadding,
              vertical: TodoTileStyle.verticalPadding,
            ),

            onTap: onTap,

            leading: Checkbox(
              value: todo.isCompleted,
              onChanged: (value) {
                onCompletedChanged(value ?? false);
              },
            ),

            title: Row(
              children: [
                Tooltip(
                  message: switch (todo.priority) {
                    3 => 'Hohe Priorität',
                    2 => 'Mittlere Priorität',
                    _ => 'Niedrige Priorität',
                  },
                  child: Icon(
                    Icons.flag_rounded,
                    size: 18,
                    color: priorityColor(todo.priority),
                  ),
                ),

                const SizedBox(width: 8),

                Expanded(
                  child: Text(
                    todo.title,
                    style: TextStyle(
                      fontSize: TodoTileStyle.titleFontSize,
                      color: titleColor,
                      decoration: todo.isCompleted
                          ? TextDecoration.lineThrough
                          : TextDecoration.none,
                    ),
                  ),
                ),
              ],
            ),

            subtitle: todo.dueDate == null
                ? null
                : Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Row(
                      children: [
                        Icon(
                          Icons.calendar_month,
                          size: 16,
                          color: isOverdue
                              ? colors.error
                              : colors.onSurfaceVariant,
                        ),

                        const SizedBox(width: 6),

                        Flexible(
                          child: Text(
                            formatDate(todo.dueDate!),
                            style: TextStyle(
                              fontSize: TodoTileStyle.dateFontSize,
                              color: isOverdue
                                  ? colors.error
                                  : colors.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

            trailing: Icon(
              isExpanded
                  ? Icons.keyboard_arrow_up
                  : Icons.keyboard_arrow_down,
            ),
          ),

          // Ausklappbarer Bereich
          AnimatedSize(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,

            child: isExpanded
                ? Padding(
                    padding: const EdgeInsets.fromLTRB(
                      TodoTileStyle.horizontalPadding,
                      0,
                      TodoTileStyle.horizontalPadding,
                      TodoTileStyle.verticalPadding,
                    ),

                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,

                      children: [
                        Divider(
                          color: TodoTileStyle.borderColor(context),
                        ),

                        const SizedBox(height: 8),

                        Text(
                          todo.description.isEmpty
                              ? 'Keine Beschreibung vorhanden.'
                              : todo.description,

                          style: TextStyle(
                            fontSize:
                                TodoTileStyle.descriptionFontSize,
                            color: TodoTileStyle.descriptionColor(
                              context,
                            ),
                          ),
                        ),

                        const SizedBox(height: 12),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            if (onEdit != null)
                              IconButton(
                                tooltip: 'Quest bearbeiten',
                                onPressed: onEdit,
                                icon: const Icon(Icons.edit_outlined),
                              ),
                            IconButton(
                              tooltip: 'Aufgabe löschen',
                              onPressed: onDelete,
                              icon: const Icon(Icons.delete_outline),
                            ),
                          ],
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
}
