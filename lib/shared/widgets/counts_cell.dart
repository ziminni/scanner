import 'package:flutter/material.dart';

import 'admin_formatters.dart';
import 'count_list_item.dart';

class CountsCell extends StatelessWidget {
  const CountsCell({super.key, required this.counts});

  static const int _visibleCount = 4;

  final Map counts;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final constrainedWidth =
        (screenWidth < 700 ? screenWidth * 0.58 : screenWidth * 0.32)
            .clamp(200.0, 360.0)
            .toDouble();
    final entries = counts.entries.toList()
      ..sort((a, b) => a.key.toString().compareTo(b.key.toString()));
    final visibleEntries = entries.take(_visibleCount).toList();
    final hiddenCount = entries.length - visibleEntries.length;

    if (entries.isEmpty) {
      return const Text('-');
    }

    return SizedBox(
      width: constrainedWidth,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final entry in visibleEntries)
              CountListItem(
                label: adminLabel(entry.key.toString()),
                value: entry.value?.toString() ?? '0',
              ),
            if (hiddenCount > 0)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    '+$hiddenCount more collections',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
