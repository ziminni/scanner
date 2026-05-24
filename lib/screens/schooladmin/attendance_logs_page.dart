import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../core/services/app_controller.dart';
import '../../models/models.dart';
import '../../shared/widgets/app_widgets.dart';
import '../../shared/widgets/admin_widgets.dart';

class AttendanceLogsPage extends StatefulWidget {
  const AttendanceLogsPage({super.key});

  @override
  State<AttendanceLogsPage> createState() => _AttendanceLogsPageState();
}

class _AttendanceLogsPageState extends State<AttendanceLogsPage> {
  final _search = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return AdminPage(
      title: 'Attendance Logs',
      child: Column(
        children: [
          TextField(
            controller: _search,
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search),
              labelText: 'Search name, ID, section, scanner',
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 12),
          AttendanceLogsTable(limit: 200, search: _search.text),
        ],
      ),
    );
  }
}

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
