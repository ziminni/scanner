import 'package:flutter/material.dart';

class AdminTableFooter extends StatelessWidget {
  const AdminTableFooter({
    super.key,
    required this.currentPage,
    required this.totalItems,
    required this.itemsPerPage,
    required this.itemLabel,
    required this.itemsPerPageOptions,
    required this.onItemsPerPageChanged,
  });

  final int currentPage;
  final int totalItems;
  final int itemsPerPage;
  final String itemLabel;
  final List<int> itemsPerPageOptions;
  final ValueChanged<int> onItemsPerPageChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final start = totalItems == 0 ? 0 : currentPage * itemsPerPage + 1;
    final end = (currentPage * itemsPerPage + itemsPerPage)
        .clamp(0, totalItems)
        .toInt();

    return Wrap(
      spacing: 12,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(
          'Showing $start to $end of $totalItems $itemLabel',
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Rows per page:',
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(width: 8),
            DropdownButton<int>(
              value: itemsPerPage,
              isDense: true,
              items: itemsPerPageOptions
                  .map(
                    (option) => DropdownMenuItem<int>(
                      value: option,
                      child: Text(option.toString()),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                if (value != null) {
                  onItemsPerPageChanged(value);
                }
              },
            ),
          ],
        ),
      ],
    );
  }
}
