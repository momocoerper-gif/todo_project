
import 'package:flutter/material.dart';

class BudgetDialog extends StatefulWidget {
  final int initialCents;

  const BudgetDialog({
    super.key,
    required this.initialCents,
  });

  @override
  State<BudgetDialog> createState() => _BudgetDialogState();
}

class _BudgetDialogState extends State<BudgetDialog> {
  late final TextEditingController _amountController;

  String? _error;

  @override
  void initState() {
    super.initState();

    final euros = widget.initialCents ~/ 100;

    final cents = (widget.initialCents % 100)
        .toString()
        .padLeft(2, '0');

    _amountController = TextEditingController(
      text: '$euros,$cents',
    );
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  // Euro-Eingabe in Cent umwandeln
  int? _parseAmount(String input) {
    final cleaned = input.trim().replaceAll(',', '.');

    if (!RegExp(r'^\d+(\.\d{1,2})?$').hasMatch(cleaned)) {
      return null;
    }

    final parts = cleaned.split('.');

    final euros = int.tryParse(parts[0]);

    final cents = parts.length == 2
        ? int.tryParse(parts[1].padRight(2, '0'))
        : 0;

    if (euros == null || cents == null) {
      return null;
    }

    return euros * 100 + cents;
  }

  // Budget speichern
  void _save() {
    final cents = _parseAmount(_amountController.text);

    if (cents == null) {
      setState(() {
        _error =
            'Bitte einen gültigen Betrag eingeben '
            '(z. B. 1500,00).';
      });

      return;
    }

    Navigator.of(context).pop(cents);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Monatsbudget festlegen'),

      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 350),

        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,

          children: [
            const Text(
              'Wie viel Geld steht dir pro Monat '
              'insgesamt zur Verfügung?',
            ),

            const SizedBox(height: 16),

            TextField(
              controller: _amountController,
              autofocus: true,

              keyboardType:
                  const TextInputType.numberWithOptions(
                decimal: true,
              ),

              decoration: InputDecoration(
                labelText: 'Monatsbudget',
                suffixText: '€',
                errorText: _error,

                prefixIcon: const Icon(
                  Icons.account_balance_wallet_outlined,
                ),
              ),

              onSubmitted: (_) => _save(),
            ),
          ],
        ),
      ),

      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Abbrechen'),
        ),

        FilledButton(
          onPressed: _save,
          child: const Text('Speichern'),
        ),
      ],
    );
  }
}
