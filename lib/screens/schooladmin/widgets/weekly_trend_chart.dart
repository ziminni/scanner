part of '../school_admin_dashboard_page.dart';

class _WeeklyTrendChart extends StatelessWidget {
  const _WeeklyTrendChart({required this.logs});

  final List<AttendanceLog> logs;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Group logs by dateKey (for the last 5 days)
    final dateGroups = <String, List<AttendanceLog>>{};
    for (final log in logs) {
      if (!log.attendanceType.isTimeIn) continue;
      dateGroups.putIfAbsent(log.dateKey, () => []).add(log);
    }

    // Get the sorted list of last 5 dateKeys
    final sortedDates = dateGroups.keys.toList()..sort();
    final last5Dates = sortedDates.reversed.take(5).toList().reversed.toList();

    // Map each date to a daily count
    final dailyCounts = last5Dates.map((date) {
      final dateLogs = dateGroups[date] ?? [];
      final present = dateLogs
          .where((l) => l.attendanceStatus != AttendanceStatus.absent)
          .length;
      final total = dateLogs.length;
      final rate = total == 0 ? 0.0 : present / total;

      // format date label: e.g., "Mon"
      String label = date;
      try {
        final parsed = DateFormat('yyyy-MM-dd').parse(date);
        label = DateFormat('EEE').format(parsed);
      } catch (_) {}

      return _DayData(label: label, rate: rate, total: total);
    }).toList();

    // If we don't have enough days, pad with mock/empty days
    while (dailyCounts.length < 5) {
      dailyCounts.insert(0, _DayData(label: '-', rate: 0.0, total: 0));
    }

    return DataSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Attendance Rate Trend (Last 5 Days)",
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              Icon(Icons.trending_up, color: theme.colorScheme.primary),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 180,
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
                                width: 32,
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.primary.withAlpha(
                                    20,
                                  ),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                              ),
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 300),
                                width: 32,
                                height: 130 * day.rate, // scale height
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.bottomCenter,
                                    end: Alignment.topCenter,
                                    colors: [
                                      theme.colorScheme.primary,
                                      theme.colorScheme.primary.withAlpha(190),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(6),
                                  boxShadow: [
                                    BoxShadow(
                                      color: theme.colorScheme.primary
                                          .withAlpha(40),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
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
    );
  }
}

class _DayData {
  final String label;
  final double rate;
  final int total;
  _DayData({required this.label, required this.rate, required this.total});
}
