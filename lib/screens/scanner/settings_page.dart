import 'package:flutter/material.dart';

import 'scanner_theme.dart';

class ScannerSettingsPage extends StatelessWidget {
  const ScannerSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ColoredBox(
      color: ScannerTheme.background,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: ScannerTheme.panelDecoration(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Scanner Settings',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: ScannerTheme.text,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                const Text('Settings for the scanner module will appear here.'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
