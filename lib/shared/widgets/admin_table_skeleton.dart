import 'package:flutter/material.dart';

import 'data_surface.dart';

class AdminTableSkeleton extends StatelessWidget {
  const AdminTableSkeleton({super.key, this.rows = 7, this.columns = 6});

  final int rows;
  final int columns;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final base = theme.colorScheme.surfaceContainerHighest;
    final subtle = theme.colorScheme.surfaceContainerHigh;

    return DataSurface(
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 42,
              decoration: BoxDecoration(
                color: subtle,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            const SizedBox(height: 8),
            for (var row = 0; row < rows; row++) ...[
              Container(
                height: 48,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: theme.dividerColor.withAlpha(35)),
                  ),
                ),
                child: Row(
                  children: [
                    for (var column = 0; column < columns; column++) ...[
                      Expanded(
                        flex: column == 1 ? 2 : 1,
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: FractionallySizedBox(
                            widthFactor: column.isEven ? .62 : .78,
                            child: Container(
                              height: 11,
                              decoration: BoxDecoration(
                                color: base,
                                borderRadius: BorderRadius.circular(5),
                              ),
                            ),
                          ),
                        ),
                      ),
                      if (column < columns - 1) const SizedBox(width: 12),
                    ],
                  ],
                ),
              ),
            ],
            const SizedBox(height: 14),
            Row(
              children: [
                Container(
                  width: 150,
                  height: 12,
                  decoration: BoxDecoration(
                    color: base,
                    borderRadius: BorderRadius.circular(5),
                  ),
                ),
                const Spacer(),
                Container(
                  width: 96,
                  height: 32,
                  decoration: BoxDecoration(
                    color: base,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
