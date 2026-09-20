part of '../school_year_page.dart';

class _SchoolYearCard extends StatelessWidget {
  const _SchoolYearCard({required this.schoolYear});

  final SchoolYear schoolYear;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final start = schoolYear.termStarts.whereType<DateTime>().firstOrNull;
    final end = schoolYear.termEnds.whereType<DateTime>().lastOrNull;
    final format = DateFormat('MMM d, yyyy');

    return DataSurface(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 620;
            final identity = Row(
              children: [
                Icon(
                  Icons.history_outlined,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        schoolYear.name,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${start == null ? 'Not set' : format.format(start)} - ${end == null ? 'Not set' : format.format(end)}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
            if (compact) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  identity,
                  const SizedBox(height: 12),
                  _SchoolYearMeta(schoolYear: schoolYear),
                ],
              );
            }
            return Row(
              children: [
                Expanded(child: identity),
                const SizedBox(width: 16),
                _SchoolYearMeta(schoolYear: schoolYear),
              ],
            );
          },
        ),
      ),
    );
  }
}
