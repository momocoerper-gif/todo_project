
import 'package:flutter/material.dart';

class SettingsScreen extends StatelessWidget {
  final bool isDarkMode;
  final ValueChanged<bool> onThemeChanged;

  const SettingsScreen({
    super.key,
    required this.isDarkMode,
    required this.onThemeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'Darstellung',
          style: Theme.of(context).textTheme.titleLarge,
        ),

        const SizedBox(height: 16),

        SwitchListTile(
          title: const Text('Dark Mode'),

          subtitle: Text(
            isDarkMode
                ? 'Dunkles Design aktiviert'
                : 'Helles Design aktiviert',
          ),

          secondary: Icon(
            isDarkMode
                ? Icons.dark_mode
                : Icons.light_mode,
          ),

          value: isDarkMode,

          onChanged: onThemeChanged,
        ),
      ],
    );
  }
}
