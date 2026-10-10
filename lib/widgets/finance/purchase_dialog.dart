
import 'package:flutter/material.dart';

import '../../theme/finance_colors.dart';

class PurchaseResult {
  final String title;
  final int cents;
  final String category;

  const PurchaseResult({
    required this.title,
    required this.cents,
    required this.category,
  });
}

class PurchaseDialog extends StatefulWidget {
  const PurchaseDialog({super.key});

  @override
  State<PurchaseDialog> createState() =>
      _PurchaseDialogState();
}

class _PurchaseDialogState extends State<PurchaseDialog> {
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();

  String _category = 'Lebensmittel';

  String? _titleError;
  String? _amountError;

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
          ? 'Bitte einen Kauf benennen.'
          : null;

      _amountError = cents == null || cents <= 0
          ? 'Bitte einen Betrag größer als 0 eingeben.'
          : null;
    });

    if (_titleError != null || _amountError != null) {
      return;
    }

    Navigator.of(context).pop(
      PurchaseResult(
        title: title,
        cents: cents!,
        category: _category,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Neuen Kauf erfassen'),

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
                  labelText: 'Was hast du gekauft?',

                  prefixIcon: const Icon(
                    Icons.shopping_bag_outlined,
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
                  labelText: 'Preis',
                  suffixText: '€',

                  prefixIcon: const Icon(Icons.euro),

                  errorText: _amountError,
                ),
              ),

              const SizedBox(height: 16),

              // Kategorie mit eigener Farbe
              DropdownButtonFormField<String>(
                initialValue: _category,
                isExpanded: true,

                decoration: const InputDecoration(
                  labelText: 'Kategorie',
                ),

                items: FinanceColors.categories.entries.map(
                  (entry) {
                    return DropdownMenuItem<String>(
                      value: entry.key,

                      child: Row(
                        children: [
                          Container(
                            width: 12,
                            height: 12,

                            decoration: BoxDecoration(
                              color: entry.value,
                              shape: BoxShape.circle,
                            ),
                          ),

                          const SizedBox(width: 10),

                          Flexible(
                            child: Text(entry.key),
                          ),
                        ],
                      ),
                    );
                  },
                ).toList(),

                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _category = value;
                    });
                  }
                },
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
          child: const Text('Speichern'),
        ),
      ],
    );
  }
}
