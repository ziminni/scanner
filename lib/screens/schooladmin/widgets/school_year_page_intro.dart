part of '../school_year_page.dart';

class _SchoolYearPageIntro extends StatelessWidget {
  const _SchoolYearPageIntro({required this.activeSchoolYear, this.onArchive});

  final SchoolYear? activeSchoolYear;
  final VoidCallback? onArchive;

  @override
  Widget build(BuildContext context) {
    final schoolYear = activeSchoolYear;
    if (schoolYear == null) return _buildEmpty(context);

    final theme = Theme.of(context);
    final now = DateTime.now();
    final start = schoolYear.termStarts.whereType<DateTime>().firstOrNull;
    final end = schoolYear.termEnds.whereType<DateTime>().lastOrNull;
    final progress = _progress(start, end, now);

    return DataSurface(
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            LayoutBuilder(
              builder: (context, constraints) {
                final compact = constraints.maxWidth < 680;
                final heading = Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        _StatusPill(status: schoolYear.displayStatus),
                        const SizedBox(width: 8),
                        Text(
                          schoolYear.activeTermName(now),
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      schoolYear.name,
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      _dateRange(start, end),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                );
                final archiveButton = OutlinedButton.icon(
                  onPressed: onArchive == null
                      ? null
                      : () => _confirmArchive(context, schoolYear),
                  icon: const Icon(Icons.archive_outlined, size: 18),
                  label: const Text('Archive school year'),
                );
                if (compact) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      heading,
                      const SizedBox(height: 14),
                      archiveButton,
                    ],
                  );
                }
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: heading),
                    const SizedBox(width: 18),
                    archiveButton,
                  ],
                );
              },
            ),
            const SizedBox(height: 22),
            Text(
              'School year progress',
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(99),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 9,
                backgroundColor: theme.colorScheme.surfaceContainerHighest,
              ),
            ),
            const SizedBox(height: 7),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('${(progress * 100).round()}% complete'),
                Text(_remainingLabel(end, now)),
              ],
            ),
            const SizedBox(height: 22),
            Text(
              'At a glance',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 10),
            FutureBuilder<_SYCounts>(
              future: _SYCounts.load(
                SchoolAdminViewModelScope.of(context).app,
                schoolYear.id,
              ),
              builder: (context, snapshot) {
                final counts = snapshot.data;
                return LayoutBuilder(
                  builder: (context, constraints) {
                    final columns = constraints.maxWidth >= 900
                        ? 4
                        : constraints.maxWidth >= 480
                        ? 2
                        : 1;
                    return GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: columns,
                      mainAxisSpacing: 10,
                      crossAxisSpacing: 10,
                      childAspectRatio: columns == 1 ? 4.4 : 2.35,
                      children: [
                        _SchoolYearStatTile(
                          label: 'Students',
                          value: counts?.students.toString() ?? '—',
                          icon: Icons.school_outlined,
                        ),
                        _SchoolYearStatTile(
                          label: 'Teachers',
                          value: counts?.teachers.toString() ?? '—',
                          icon: Icons.badge_outlined,
                        ),
                        _SchoolYearStatTile(
                          label: 'Sections',
                          value: counts?.sections.toString() ?? '—',
                          icon: Icons.meeting_room_outlined,
                        ),
                        _SchoolYearStatTile(
                          label: 'Attendance records',
                          value: counts?.attendanceLogs.toString() ?? '—',
                          icon: Icons.fact_check_outlined,
                        ),
                      ],
                    );
                  },
                );
              },
            ),
            const SizedBox(height: 22),
            Text(
              'Term calendar',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                for (var index = 0; index < 3; index++)
                  _TermChip(
                    label: _termLabel(index),
                    start: _formatDate(
                      schoolYear.termStarts.elementAtOrNull(index),
                    ),
                    end: _formatDate(
                      schoolYear.termEnds.elementAtOrNull(index),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty(BuildContext context) {
    final theme = Theme.of(context);
    return DataSurface(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 28),
        child: Column(
          children: [
            Icon(
              Icons.calendar_month_outlined,
              size: 42,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: 12),
            Text(
              'No active school year',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              'Create a school year to define term dates and begin tracking students, teachers, and attendance.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  double _progress(DateTime? start, DateTime? end, DateTime now) {
    if (start == null || end == null || !end.isAfter(start)) return 0;
    if (now.isBefore(start)) return 0;
    if (now.isAfter(end)) return 1;
    return now.difference(start).inMinutes / end.difference(start).inMinutes;
  }

  String _dateRange(DateTime? start, DateTime? end) {
    if (start == null && end == null) return 'Academic dates are not set';
    final format = DateFormat('MMMM d, yyyy');
    return '${start == null ? 'Not set' : format.format(start)} - ${end == null ? 'Not set' : format.format(end)}';
  }

  String _remainingLabel(DateTime? end, DateTime now) {
    if (end == null) return 'End date not set';
    final days = DateTime(
      end.year,
      end.month,
      end.day,
    ).difference(DateTime(now.year, now.month, now.day)).inDays;
    if (days < 0) return 'School year ended';
    if (days == 0) return 'Ends today';
    return '$days days remaining';
  }

  String _termLabel(int index) => switch (index) {
    0 => '1st Term',
    1 => '2nd Term',
    _ => '3rd Term',
  };

  String? _formatDate(DateTime? date) =>
      date == null ? null : DateFormat('MMM d, yyyy').format(date);

  Future<void> _confirmArchive(
    BuildContext context,
    SchoolYear schoolYear,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Archive school year?'),
        content: Text(
          'This will mark ${schoolYear.name} as archived and allow you to create a new active school year.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton.icon(
            onPressed: () => Navigator.pop(dialogContext, true),
            icon: const Icon(Icons.archive_outlined),
            label: const Text('Archive'),
          ),
        ],
      ),
    );
    if (confirmed == true) onArchive?.call();
  }
}
