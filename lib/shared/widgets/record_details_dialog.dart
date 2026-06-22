import 'package:flutter/material.dart';

import 'admin_formatters.dart';

class RecordDetailsDialog extends StatelessWidget {
  const RecordDetailsDialog({
    super.key,
    required this.title,
    required this.data,
    required this.columns,
  });

  final String title;
  final Map<String, dynamic> data;
  final List<String> columns;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AlertDialog(
      title: Text(title),
      content: SizedBox(
        width: 480,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final column in columns)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 130,
                        child: Text(
                          column == 'fullName'
                              ? 'Full Name'
                              : adminLabel(column),
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          column == 'fullName'
                              ? adminPersonName(data)
                              : adminFormatValue(data[column]),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
      actions: [
        FilledButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }
}
