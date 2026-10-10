
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../theme/finance_colors.dart';

class BudgetChart extends StatelessWidget {
  final int budgetCents;
  final int fixedCents;
  final Map<String, int> categoryAmounts;

  const BudgetChart({
    super.key,
    required this.budgetCents,
    required this.fixedCents,
    required this.categoryAmounts,
  });

  String _formatEuro(int cents) {
    final sign = cents < 0 ? '-' : '';
    final abs = cents.abs();

    return '$sign${abs ~/ 100},'
        '${(abs % 100).toString().padLeft(2, '0')} €';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    // Ausgaben aller Kaufkategorien
    final purchased = categoryAmounts.values.fold<int>(
      0,
      (sum, amount) => sum + amount,
    );

    // Gesamtausgaben einschließlich Fixkosten
    final spent = fixedCents + purchased;

    // Verbleibendes Monatsbudget
    final remaining = budgetCents - spent;

    final hasData = budgetCents > 0 || spent > 0;

    final sections = <PieChartSectionData>[];

    final legend = <({
      String name,
      int cents,
      Color color,
    })>[];

    // Fügt einen Bereich zum Diagramm hinzu
    void addPart(String name, int cents, Color color) {
      if (cents <= 0) return;

      sections.add(
        PieChartSectionData(
          value: cents.toDouble(),
          color: color,
          radius: 23,
          showTitle: false,
        ),
      );

      legend.add((
        name: name,
        cents: cents,
        color: color,
      ));
    }

    // Fixkosten als eigener Bereich
    addPart(
      'Fixkosten',
      fixedCents,
      FinanceColors.fixedCosts,
    );

    // Ausgaben nach Kategorie
    for (final entry in FinanceColors.categories.entries) {
      addPart(
        entry.key,
        categoryAmounts[entry.key] ?? 0,
        entry.value,
      );
    }

    // Auch unbekannte gespeicherte Kategorien
    // weiterhin darstellen
    for (final entry in categoryAmounts.entries) {
      if (!FinanceColors.categories.containsKey(entry.key)) {
        addPart(
          entry.key,
          entry.value,
          FinanceColors.forCategory(entry.key),
        );
      }
    }

    // Noch verfügbares Budget
    if (remaining > 0) {
      addPart(
        'Verfügbar',
        remaining,
        FinanceColors.remaining,
      );
    }

    // Platzhalter, wenn noch keine Daten existieren
    if (sections.isEmpty) {
      sections.add(
        PieChartSectionData(
          value: 1,
          color: colors.outlineVariant,
          radius: 23,
          showTitle: false,
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Budgetverteilung',
          style: theme.textTheme.titleLarge,
        ),

        const SizedBox(height: 12),

        SizedBox(
          height: 220,
          child: Stack(
            alignment: Alignment.center,
            children: [
              PieChart(
                PieChartData(
                  sections: sections,
                  centerSpaceRadius: 66,
                  sectionsSpace: 2,
                  startDegreeOffset: -90,
                ),
              ),

              // Text im Zentrum des Diagramms
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    remaining < 0
                        ? 'Überzogen'
                        : 'Verfügbar',
                    style: theme.textTheme.bodySmall,
                  ),

                  const SizedBox(height: 4),

                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      _formatEuro(remaining),
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: remaining < 0
                            ? colors.error
                            : colors.onSurface,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        if (!hasData)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              'Lege ein Budget fest oder erfasse '
              'deine ersten Ausgaben.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall,
            ),
          ),

        const SizedBox(height: 8),

        // Legende
        for (final part in legend)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                Container(
                  width: 13,
                  height: 13,
                  decoration: BoxDecoration(
                    color: part.color,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),

                const SizedBox(width: 10),

                Expanded(
                  child: Text(part.name),
                ),

                Text(
                  _formatEuro(part.cents),
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),

        // Hinweis bei Budgetüberschreitung
        if (remaining < 0) ...[
          const SizedBox(height: 8),

          Text(
            'Du hast dein Budget um '
            '${_formatEuro(-remaining)} überschritten.',
            style: TextStyle(
              color: colors.error,
            ),
          ),
        ],
      ],
    );
  }
}
