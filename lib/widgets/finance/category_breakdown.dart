import 'package:flutter/material.dart';
import '../../theme/finance_colors.dart';

/// Prozentuale Verteilung der Einkäufe (ohne Fixkosten).
class CategoryBreakdown extends StatelessWidget {
  final Map<String, int> categoryAmounts;

  const CategoryBreakdown({
    super.key,
    required this.categoryAmounts,
  });

  String _euro(int cents) =>
      '${cents ~/ 100},${(cents % 100).toString().padLeft(2, '0')} €';

  @override
  Widget build(BuildContext context) {
    final positive = categoryAmounts.entries
        .where((entry) => entry.value > 0)
        .toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final total = positive.fold<int>(0, (sum, item) => sum + item.value);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Ausgaben nach Kategorie',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 4),
            Text('Nur Einkäufe · insgesamt ${_euro(total)}',
                style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 16),
            if (positive.isEmpty)
              const Text('Noch keine Käufe in diesem Monat.')
            else
              for (final entry in positive) ...[
                Row(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: FinanceColors.forCategory(entry.key),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(child: Text(entry.key)),
                    Text('${_euro(entry.value)}  ·  '
                        '${(entry.value / total * 100).toStringAsFixed(1).replaceAll('.', ',')} %'),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: entry.value / total,
                    minHeight: 10,
                    backgroundColor:
                        Theme.of(context).colorScheme.surfaceContainerHighest,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      FinanceColors.forCategory(entry.key),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
              ],
          ],
        ),
      ),
    );
  }
}
