part of '../attendance_logs_page.dart';

class AttendanceLogsTable extends StatelessWidget {
  const AttendanceLogsTable({super.key, required this.limit, this.search = ''});

  final int limit;
  final String search;

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: app.attendance.logsStream(limit: limit),
      builder: (context, snapshot) {
        final query = search.toLowerCase();
        final logs = (snapshot.data?.docs ?? [])
            .map(AttendanceLog.fromDoc)
            .where(
              (log) =>
                  query.isEmpty ||
                  '${log.personId} ${log.fullName} ${log.section} ${log.scannedBy}'
                      .toLowerCase()
                      .contains(query),
            )
            .toList();
        if (logs.isEmpty) {
          return const EmptyState(title: 'No attendance logs found');
        }
        return DataSurface(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columns: const [
                DataColumn(label: Text('ID')),
                DataColumn(label: Text('Name')),
                DataColumn(label: Text('Role')),
                DataColumn(label: Text('Section')),
                DataColumn(label: Text('Date')),
                DataColumn(label: Text('Type')),
                DataColumn(label: Text('Status')),
                DataColumn(label: Text('Scanner')),
                DataColumn(label: Text('Sync')),
              ],
              rows: [
                for (final log in logs)
                  DataRow(
                    cells: [
                      DataCell(Text(log.personId)),
                      DataCell(Text(log.fullName)),
                      DataCell(Text(log.personRole.label)),
                      DataCell(Text(log.section)),
                      DataCell(Text('${log.dateKey} ${log.timeText}')),
                      DataCell(Text(log.attendanceType.label)),
                      DataCell(Text(log.attendanceStatus.label)),
                      DataCell(Text(log.scannedBy)),
                      DataCell(Text(log.syncStatus.label)),
                    ],
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class GatePassLogsTable extends StatelessWidget {
  const GatePassLogsTable({super.key, required this.limit, this.search = ''});

  final int limit;
  final String search;

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: app.attendance.gatePassLogsStream(limit: limit),
      builder: (context, snapshot) {
        final query = search.toLowerCase();
        final logs = (snapshot.data?.docs ?? [])
            .map(GatePassLog.fromDoc)
            .where(
              (log) =>
                  query.isEmpty ||
                  '${log.personId} ${log.fullName} ${log.section} ${log.scannedBy} ${log.reason}'
                      .toLowerCase()
                      .contains(query),
            )
            .toList();
        if (logs.isEmpty) {
          return const EmptyState(title: 'No gate pass logs found');
        }
        return DataSurface(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columns: const [
                DataColumn(label: Text('ID')),
                DataColumn(label: Text('Name')),
                DataColumn(label: Text('Role')),
                DataColumn(label: Text('Section')),
                DataColumn(label: Text('Out')),
                DataColumn(label: Text('Back In')),
                DataColumn(label: Text('Status')),
                DataColumn(label: Text('Reason')),
                DataColumn(label: Text('Business')),
                DataColumn(label: Text('Duration')),
                DataColumn(label: Text('Scanner')),
                DataColumn(label: Text('Sync')),
              ],
              rows: [
                for (final log in logs)
                  DataRow(
                    cells: [
                      DataCell(Text(log.personId)),
                      DataCell(Text(log.fullName)),
                      DataCell(Text(log.personRole.label)),
                      DataCell(Text(log.section)),
                      DataCell(Text('${log.dateKey} ${log.exitTimeText}')),
                      DataCell(
                        Text(
                          log.returnTimeText.isEmpty ? '-' : log.returnTimeText,
                        ),
                      ),
                      DataCell(Text(log.status.label)),
                      DataCell(SizedBox(width: 240, child: Text(log.reason))),
                      DataCell(Text(log.teacherBusinessType?.label ?? '-')),
                      DataCell(Text(_durationText(log.durationMinutes))),
                      DataCell(Text(log.scannedBy)),
                      DataCell(Text(log.syncStatus.label)),
                    ],
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _durationText(int minutes) {
    if (minutes <= 0) return '-';
    final hours = minutes ~/ 60;
    final remainingMinutes = minutes % 60;
    if (hours == 0) return '${remainingMinutes}m';
    if (remainingMinutes == 0) return '${hours}h';
    return '${hours}h ${remainingMinutes}m';
  }
}
