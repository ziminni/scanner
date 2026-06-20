import 'package:flutter/material.dart';

class BulkArchiveSelectionBar extends StatelessWidget {
  const BulkArchiveSelectionBar({
    super.key,
    required this.selectedCount,
    required this.onClear,
    required this.onArchive,
  });

  final int selectedCount;
  final VoidCallback onClear;
  final VoidCallback onArchive;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withAlpha(18),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.primary.withAlpha(45)),
      ),
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        crossAxisAlignment: WrapCrossAlignment.center,
        alignment: WrapAlignment.spaceBetween,
        children: [
          Text(
            '$selectedCount selected',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              TextButton(onPressed: onClear, child: const Text('Clear')),
              FilledButton.icon(
                onPressed: onArchive,
                icon: const Icon(Icons.archive_outlined),
                label: const Text('Archive selected'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
