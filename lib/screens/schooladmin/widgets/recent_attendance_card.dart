part of '../school_admin_dashboard_page.dart';

class _RecentAttendanceCard extends StatelessWidget {
  const _RecentAttendanceCard({required this.logs});

  final List<AttendanceLog> logs;

  @override
  Widget build(BuildContext context) {
    final previewLogs = logs.take(6).toList();

    return RepaintBoundary(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: _dashboardCardDecoration(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _DashboardCardHeader(
              title: 'Recent Attendance Logs',
              subtitle: 'Latest scanner activity from this school year.',
              icon: Icons.history_outlined,
            ),
            const SizedBox(height: 16),
            if (previewLogs.isEmpty)
              const SizedBox(
                height: 220,
                child: EmptyState(title: 'No attendance logs found'),
              )
            else
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    headingRowHeight: 42,
                    dataRowMinHeight: 46,
                    dataRowMaxHeight: 54,
                    horizontalMargin: 14,
                    columnSpacing: 18,
                    headingTextStyle: Theme.of(context).textTheme.labelMedium
                        ?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w800,
                        ),
                    dataTextStyle: Theme.of(context).textTheme.bodySmall,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: Theme.of(context).dividerColor.withAlpha(80),
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    columns: const [
                      DataColumn(label: Text('#')),
                      DataColumn(label: Text('Name')),
                      DataColumn(label: Text('Role')),
                      DataColumn(label: Text('Time')),
                      DataColumn(label: Text('Status')),
                    ],
                    rows: [
                      for (var index = 0; index < previewLogs.length; index++)
                        _buildLogRow(context, index + 1, previewLogs[index]),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  DataRow _buildLogRow(BuildContext context, int index, AttendanceLog log) {
    final isLate = log.attendanceStatus == AttendanceStatus.late;
    return DataRow(
      color: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.hovered)) {
          return Theme.of(context).colorScheme.primary.withAlpha(12);
        }
        return index.isEven ? Colors.black.withAlpha(3) : Colors.transparent;
      }),
      cells: [
        DataCell(Text('$index')),
        DataCell(
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 220),
            child: Text(
              log.fullName,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ),
        DataCell(Text(log.personRole.label)),
        DataCell(Text(log.timeText)),
        DataCell(
          StatusBadge(
            label: log.attendanceStatus.label,
            type: isLate ? 'late' : 'active',
          ),
        ),
      ],
    );
  }
}
