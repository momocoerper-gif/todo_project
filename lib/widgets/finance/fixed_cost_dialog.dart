
import 'package:flutter/material.dart';

class FixedCostResult {
  final String title;
  final int cents;

  const FixedCostResult({
    required this.title,
    required this.cents,
  });
}

class FixedCostDialog extends StatefulWidget {
  final String? initialTitle;
  final int? initialCents;

  const FixedCostDialog({
    super.key,
    this.initialTitle,
    this.initialCents,
  });

  @override
  State<FixedCostDialog> createState() =>
      _FixedCostDialogState();
}

class _FixedCostDialogState extends State<FixedCostDialog> {
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();

  String? _titleError;
  String? _amountError;

  bool get isEditing => widget.initialTitle != null;

  @override
  void initState() {
    super.initState();
    _titleController.text = widget.initialTitle ?? '';
    final amount = widget.initialCents;
    if (amount != null) {
      _amountController.text =
          '${amount ~/ 100},${(amount % 100).toString().padLeft(2, '0')}';
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();

    super.dispose();
  }

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

  void _save() {
    final title = _titleController.text.trim();
    final cents = _parseAmount(_amountController.text);

    setState(() {
      _titleError = title.isEmpty
          ? 'Bitte eine Bezeichnung eingeben.'
          : null;

      _amountError = cents == null || cents <= 0
          ? 'Bitte einen Betrag größer als 0 eingeben.'
          : null;
    });

    if (_titleError != null || _amountError != null) {
      return;
    }

    Navigator.of(context).pop(
      FixedCostResult(
        title: title,
        cents: cents!,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(isEditing ? 'Fixkosten bearbeiten' : 'Laufende Kosten hinzufügen'),

      content: SingleChildScrollView(
        child: SizedBox(
          width: 350,

          child: Column(
            mainAxisSize: MainAxisSize.min,

            children: [
              TextField(
                controller: _titleController,
                autofocus: true,

                textCapitalization:
                    TextCapitalization.sentences,

                decoration: InputDecoration(
                  labelText: 'Bezeichnung',
                  hintText: 'z. B. Miete',

                  prefixIcon: const Icon(
                    Icons.receipt_long_outlined,
                  ),

                  errorText: _titleError,
                ),
              ),

              const SizedBox(height: 16),

              TextField(
                controller: _amountController,

                keyboardType:
                    const TextInputType.numberWithOptions(
                  decimal: true,
                ),

                decoration: InputDecoration(
                  labelText: 'Monatlicher Betrag',
                  suffixText: '€',

                  prefixIcon: const Icon(Icons.euro),

                  errorText: _amountError,
                ),

                onSubmitted: (_) => _save(),
              ),
            ],
          ),
        ),
      ),

      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Abbrechen'),
        ),

        FilledButton(
          onPressed: _save,
          child: Text(isEditing ? 'Speichern' : 'Hinzufügen'),
        ),
      ],
    );
  }
}
