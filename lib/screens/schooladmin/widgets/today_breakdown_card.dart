part of '../school_admin_dashboard_page.dart';

class _TodayBreakdownCard extends StatelessWidget {
  const _TodayBreakdownCard({required this.logs});

  final List<AttendanceLog> logs;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    var early = 0;
    var onTime = 0;
    var lateCount = 0;
    var absent = 0;

    for (final log in logs) {
      if (!log.attendanceType.isTimeIn) continue;
      switch (log.attendanceStatus) {
        case AttendanceStatus.early:
          early++;
          break;
        case AttendanceStatus.onTime:
          onTime++;
          break;
        case AttendanceStatus.late:
          lateCount++;
          break;
        case AttendanceStatus.absent:
          absent++;
          break;
        default:
          break;
      }
    }

    final presentTotal = early + onTime + lateCount + absent;

    Widget buildBar(String label, int count, Color color) {
      final percentage = presentTotal == 0 ? 0.0 : count / presentTotal;
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      label,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
                Text(
                  '$count (${(percentage * 100).toStringAsFixed(0)}%)',
                  style: TextStyle(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: percentage,
                backgroundColor: color.withAlpha(25),
                valueColor: AlwaysStoppedAnimation<Color>(color),
                minHeight: 8,
              ),
            ),
          ],
        ),
      );
    }

    return DataSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Today's Attendance Status Breakdown",
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              Icon(Icons.analytics_outlined, color: theme.colorScheme.primary),
            ],
          ),
          const SizedBox(height: 16),
          if (presentTotal == 0)
            const SizedBox(
              height: 180,
              child: Center(
                child: Text('No check-in logs recorded for today yet.'),
              ),
            )
          else
            Column(
              children: [
                buildBar('Early', early, const Color(0xFF10B981)),
                buildBar('On Time', onTime, const Color(0xFF3B82F6)),
                buildBar('Late', lateCount, const Color(0xFFF59E0B)),
                buildBar('Absent', absent, const Color(0xFFEF4444)),
              ],
            ),
        ],
      ),
    );
  }
}
