part of '../archive_management_page.dart';

class _CompletedSchoolYearCard extends StatelessWidget {
  const _CompletedSchoolYearCard({
    required this.schoolYear,
    required this.deleting,
    required this.onDelete,
  });

  final SchoolYear schoolYear;
  final bool deleting;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final app = SchoolAdminViewModelScope.of(context);
    final theme = Theme.of(context);

    return DataSurface(
      child: FutureBuilder<_SchoolYearStats>(
        future: _SchoolYearStats.load(app.app, schoolYear.id),
        builder: (context, snapshot) {
          final stats = snapshot.data;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          schoolYear.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _dateRange(schoolYear),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  FilledButton.icon(
                    icon: deleting
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.delete_outline),
                    label: const Text('Delete'),
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: deleting ? null : onDelete,
                  ),
                ],
              ),
              const Spacer(),
              if (snapshot.connectionState == ConnectionState.waiting)
                const LinearProgressIndicator()
              else
                Row(
                  children: [
                    Expanded(
                      child: _StatTile(
                        label: 'Students',
                        value: (stats?.students ?? 0).toString(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _StatTile(
                        label: 'Teachers',
                        value: (stats?.teachers ?? 0).toString(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _StatTile(
                        label: 'Attendance',
                        value: (stats?.attendanceLogs ?? 0).toString(),
                      ),
                    ),
                  ],
                ),
            ],
          );
        },
      ),
    );
  }

  String _dateRange(SchoolYear schoolYear) {
    final start = _firstDate(schoolYear.termStarts);
    final end = _lastDate(schoolYear.termEnds);
    if (start == null && end == null) return 'Date range not set';

    final formatter = DateFormat('MMM d, yyyy');
    final startText = start == null ? 'Not set' : formatter.format(start);
    final endText = end == null ? 'Not set' : formatter.format(end);
    return '$startText - $endText';
  }

  DateTime? _firstDate(List<DateTime?> dates) {
    for (final date in dates) {
      if (date != null) return date;
    }
    return null;
  }

  DateTime? _lastDate(List<DateTime?> dates) {
    for (final date in dates.reversed) {
      if (date != null) return date;
    }
    return null;
  }
}
