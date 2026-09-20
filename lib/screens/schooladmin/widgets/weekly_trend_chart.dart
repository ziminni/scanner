part of '../school_admin_dashboard_page.dart';

class _WeeklyTrendChart extends StatelessWidget {
  const _WeeklyTrendChart({required this.logs});

  final List<AttendanceLog> logs;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final dateGroups = <String, List<AttendanceLog>>{};
    for (final log in logs) {
      if (!log.attendanceType.isTimeIn) continue;
      dateGroups.putIfAbsent(log.dateKey, () => []).add(log);
    }

    final sortedDates = dateGroups.keys.toList()..sort();
    final last5Dates = sortedDates.reversed.take(5).toList().reversed.toList();

    final dailyCounts = last5Dates.map((date) {
      final dateLogs = dateGroups[date] ?? [];
      final present = dateLogs
          .where((l) => l.attendanceStatus != AttendanceStatus.absent)
          .length;
      final total = dateLogs.length;
      final rate = total == 0 ? 0.0 : present / total;

      String label = date;
      try {
        final parsed = DateFormat('yyyy-MM-dd').parse(date);
        label = DateFormat('EEE').format(parsed);
      } catch (_) {}

      return _DayData(label: label, rate: rate, total: total);
    }).toList();

    while (dailyCounts.length < 5) {
      dailyCounts.insert(0, _DayData(label: '-', rate: 0.0, total: 0));
    }

    return RepaintBoundary(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: _dashboardCardDecoration(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _DashboardCardHeader(
              title: 'Attendance Trend',
              subtitle: 'Attendance rate from the last 5 active days.',
              icon: Icons.trending_up,
            ),
            const SizedBox(height: 22),
            SizedBox(
              height: 190,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  for (final day in dailyCounts)
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Expanded(
                            child: Stack(
                              alignment: Alignment.bottomCenter,
                              children: [
                                Container(
                                  width: 36,
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.primary.withAlpha(
                                      20,
                                    ),
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                ),
                                Container(
                                  width: 36,
                                  height: 136 * day.rate,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.bottomCenter,
                                      end: Alignment.topCenter,
                                      colors: [
                                        theme.colorScheme.primary,
                                        theme.colorScheme.primary.withAlpha(
                                          190,
                                        ),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            day.label,
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${(day.rate * 100).toStringAsFixed(0)}%',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DayData {
  final String label;
  final double rate;
  final int total;
  _DayData({required this.label, required this.rate, required this.total});
}
