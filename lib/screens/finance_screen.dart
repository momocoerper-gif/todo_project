import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../widgets/finance/budget_chart.dart';
import '../widgets/finance/category_breakdown.dart';
import '../widgets/finance/budget_dialog.dart';
import '../widgets/finance/fixed_cost_dialog.dart';
import '../widgets/finance/purchase_dialog.dart';
import '../theme/finance_colors.dart';

// Euro-Betrag aus gespeicherten Cent
String euro(int cents) {
  final sign = cents < 0 ? '-' : '';
  final value = (cents.abs() / 100).toStringAsFixed(2);
  return '$sign${value.replaceAll('.', ',')} €';
}

class FinanceScreen extends StatefulWidget {
  const FinanceScreen({super.key});

  @override
  State<FinanceScreen> createState() => _FinanceScreenState();
}

class _FinanceScreenState extends State<FinanceScreen> {
  final db = DatabaseHelper.instance;

  Map<String, Object?>? overview;
  List<Map<String, Object?>> activeCosts = [];
  List<Map<String, Object?>> archive = [];

  bool loading = true;

  @override
  void initState() {
    super.initState();
    loadData();
  }

  Future<void> loadData() async {
    final now = DateTime.now();

    final result = await db.getFinanceOverview(now);
    final costs = await db.getActiveFixedCosts();
    final history = await db.getFinanceArchive();
    debugPrint('ARCHIV: $history');

    if (!mounted) return;

    setState(() {
      overview = result;
      activeCosts = costs;
      archive = history;
      loading = false;
    });
  }

  Future<void> editBudget() async {
    final result = await showDialog<int>(
      context: context,
      builder: (_) => BudgetDialog(
        initialCents: overview?['budget'] as int? ?? 0,
      ),
    );

    if (!mounted || result == null) return;

    await db.setFinanceBudget(DateTime.now(), result);
    await loadData();
  }

  Future<void> addFixedCost() async {
    final result = await showDialog<FixedCostResult>(
      context: context,
      builder: (_) => const FixedCostDialog(),
    );

    if (!mounted || result == null) return;

    await db.addFixedCost(result.title, result.cents);
    await loadData();
  }

  Future<void> editFixedCost(Map<String, Object?> cost) async {
    final result = await showDialog<FixedCostResult>(
      context: context,
      builder: (_) => FixedCostDialog(
        initialTitle: cost['title'] as String,
        initialCents: cost['amount_cents'] as int,
      ),
    );
    if (!mounted || result == null) return;

    await db.updateFixedCost(
      cost['id'] as int,
      result.title,
      result.cents,
    );
    if (!mounted) return;
    await loadData();
  }

  Future<void> addPurchase() async {
    final result = await showDialog<PurchaseResult>(
      context: context,
      builder: (_) => const PurchaseDialog(),
    );

    if (!mounted || result == null) return;

    await db.addFinancePurchase(
      title: result.title,
      amountCents: result.cents,
      category: result.category,
      date: DateTime.now(),
    );

    await loadData();
  }

  Future<void> removeFixedCost(int id) async {
    await db.deleteFixedCost(id);
    await loadData();
  }

  Future<void> removePurchase(int id) async {
    await db.deleteFinancePurchase(id);
    await loadData();
  }

  Widget sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 10),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleLarge,
      ),
    );
  }

  Widget infoCard(String label, int amount) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Text(label, textAlign: TextAlign.center),
              const SizedBox(height: 8),
              FittedBox(
                child: Text(
                  euro(amount),
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildArchive() {
    if (archive.isEmpty) {
      return const Text(
        'Noch keine abgeschlossenen Monate.',
      );
    }

    final colors = Theme.of(context).colorScheme;

    return Column(
      children: archive.map((row) {
        final monthKey = row['month_key'] as String;

        final budget = row['budget_cents'] as int;
        final fixed = row['fixed_cents'] as int;
        final purchases = row['spent_cents'] as int;

        // Gesamtausgaben
        final spent = fixed + purchases;

        // Verbleibendes Budget
        final remaining = budget - spent;

        // Prozentualer Anteil am Monatsbudget
        final percentage = budget > 0
            ? spent / budget * 100
            : 0.0;

        // Für die Darstellung maximal 100 %.
        // Auch bei Budgetüberschreitung korrekt.
        final progress = budget > 0
            ? (spent / budget).clamp(0.0, 1.0)
            : 0.0;

        // Monatsname auf Deutsch
        final parts = monthKey.split('-');
        final year = int.parse(parts[0]);
        final month = int.parse(parts[1]);

        final monthNames = [
          'Januar',
          'Februar',
          'März',
          'April',
          'Mai',
          'Juni',
          'Juli',
          'August',
          'September',
          'Oktober',
          'November',
          'Dezember',
        ];

        final monthText = '${monthNames[month - 1]} $year';

        // Farbe abhängig vom Budgetstatus
        final progressColor = remaining < 0
            ? colors.error
            : colors.primary;

        return Card(
          margin: const EdgeInsets.only(bottom: 12),

          child: Padding(
            padding: const EdgeInsets.all(16),

            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,

              children: [
                // Monat
                Text(
                  monthText,
                  style: Theme.of(context).textTheme.titleLarge,
                ),

                const SizedBox(height: 16),

                // Gesamtausgaben oberhalb des Balkens
                Row(
                  mainAxisAlignment:
                      MainAxisAlignment.spaceBetween,

                  children: [
                    const Text('Gesamtausgaben'),

                    Text(
                      euro(spent),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 10),

                // Fortschrittsbalken
                LinearProgressIndicator(
                  value: progress,
                  minHeight: 14,
                  borderRadius: BorderRadius.circular(8),
                  backgroundColor:
                      colors.surfaceContainerHighest,
                  color: progressColor,
                ),

                const SizedBox(height: 8),

                // Prozentsatz links und Budget rechts
                Row(
                  mainAxisAlignment:
                      MainAxisAlignment.spaceBetween,

                  children: [
                    Text(
                      budget > 0
                          ? '${percentage.toStringAsFixed(1).replaceAll('.', ',')} % '
                            'des Monatsbudgets'
                          : 'Kein Budget festgelegt',

                      style: Theme.of(context)
                          .textTheme
                          .bodySmall,
                    ),

                    Text(
                      euro(budget),
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall,
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                Divider(
                  color: colors.outlineVariant,
                ),

                const SizedBox(height: 8),

                // Restbudget
                Row(
                  mainAxisAlignment:
                      MainAxisAlignment.spaceBetween,

                  children: [
                    const Expanded(
                      child: Text(
                        'Verbleibendes Budget',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),

                    const SizedBox(width: 8),

                    Text(
                      euro(remaining),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,

                        color: remaining < 0
                            ? colors.error
                            : colors.onSurface,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (loading || overview == null) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    final data = overview!;
    final colors = Theme.of(context).colorScheme;

    final budget = data['budget'] as int;
    final fixed = data['fixed'] as int;
    final spent = data['spent'] as int;
    final remaining = data['remaining'] as int;

    final purchases =
        data['purchases'] as List<Map<String, Object?>>;

    final Map<String, int> categoryAmounts = {};

    for (final purchase in purchases) {
      final category = purchase['category'] as String;
      final amount = purchase['amount_cents'] as int;

      categoryAmounts.update(
        category,
        (existing) => existing + amount,
        ifAbsent: () => amount,
      );
    }

    final fraction = budget > 0
        ? ((fixed + spent) / budget).clamp(0.0, 1.0)
        : 0.0;

    return RefreshIndicator(
      onRefresh: loadData,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // MONATSÜBERSICHT
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Noch verfügbares Budget',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    euro(remaining),
                    style: Theme.of(context)
                        .textTheme
                        .headlineLarge
                        ?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: remaining < 0
                              ? colors.error
                              : colors.primary,
                        ),
                  ),
                  const SizedBox(height: 16),
                  LinearProgressIndicator(
                    value: fraction,
                    minHeight: 12,
                    borderRadius: BorderRadius.circular(6),
                    color: remaining < 0
                        ? colors.error
                        : colors.primary,
                  ),
                  const SizedBox(height: 12),
                  Text('Monatsbudget: ${euro(budget)}'),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: editBudget,
                    icon: const Icon(Icons.edit),
                    label: const Text('Budget festlegen'),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 12),

          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: BudgetChart(
                budgetCents: budget,
                fixedCents: fixed,
                categoryAmounts: categoryAmounts,
              ),
            ),
          ),

          const SizedBox(height: 12),

          Row(
            children: [
              infoCard('Fixkosten', fixed),
              infoCard('Käufe', spent),
            ],
          ),

          // CATEGORY BREAKDOWN: purchases only, no fixed costs
          const SizedBox(height: 12),
          CategoryBreakdown(categoryAmounts: categoryAmounts),

          // FIXKOSTEN
          sectionTitle('🏠 Laufende Kosten'),

          ...activeCosts.map((cost) {
            return Card(
              child: ListTile(
                title: Text(cost['title'] as String),
                subtitle: Text(
                  euro(cost['amount_cents'] as int),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      tooltip: 'Fixkosten bearbeiten',
                      icon: const Icon(Icons.edit_outlined),
                      onPressed: () => editFixedCost(cost),
                    ),
                    IconButton(
                      tooltip: 'Fixkosten entfernen',
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () =>
                          removeFixedCost(cost['id'] as int),
                    ),
                  ],
                ),
              ),
            );
          }),

          OutlinedButton.icon(
            onPressed: addFixedCost,
            icon: const Icon(Icons.add),
            label: const Text('Fixkosten hinzufügen'),
          ),

          // KÄUFE
          sectionTitle('🛍️ Käufe diesen Monat'),

          FilledButton.icon(
            onPressed: addPurchase,
            icon: const Icon(Icons.add),
            label: const Text('Neuen Kauf registrieren'),
          ),

          const SizedBox(height: 10),

          if (purchases.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text('Noch keine Käufe in diesem Monat.'),
              ),
            ),

          ...purchases.map((purchase) {
            final category = purchase['category'] as String;
            return Card(
              child: ListTile(
                leading: CircleAvatar(
                  radius: 9,
                  backgroundColor: FinanceColors.forCategory(category),
                ),
                title: Text(purchase['title'] as String),
                subtitle: Text(
                  '${purchase['category']} · ${purchase['purchase_date']}',
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      euro(purchase['amount_cents'] as int),
                    ),
                    IconButton(
                      tooltip: 'Kauf löschen',
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () => removePurchase(
                        purchase['id'] as int,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),

          // ARCHIV
          sectionTitle('📊 Monatsarchiv'),
          buildArchive(),

          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
