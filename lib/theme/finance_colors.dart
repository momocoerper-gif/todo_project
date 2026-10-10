
import 'package:flutter/material.dart';

class FinanceColors {
  static const fixedCosts = Color(0xFFBD8464);
  static const remaining = Color(0xFFB9B5AA);
  static const overBudget = Color(0xFFD65C5C);

  static const Map<String, Color> categories = {
    'Lebensmittel': Color(0xFF80A469),
    'Haushalt': Color(0xFFD5A65C),
    'Mobilität': Color(0xFF7FADC0),
    'Gesundheit': Color(0xFFD98594),
    'Freizeit': Color(0xFFE8AF64),
    'Shopping': Color(0xFFA38CCC),
    'Bildung': Color(0xFF74B5A7),
    'Sonstiges': Color(0xFF9298A6),
  };

  static Color forCategory(String category) {
    return categories[category] ??
        categories['Sonstiges']!;
  }
}
