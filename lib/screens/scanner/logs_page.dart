import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../core/constants/enums.dart';
import '../../core/services/app_controller.dart';
import '../../models/models.dart';
import '../../shared/widgets/app_widgets.dart';
import 'scanner_theme.dart';

class ScannerLogsPage extends StatefulWidget {
  const ScannerLogsPage({super.key});

  @override
  State<ScannerLogsPage> createState() => _ScannerLogsPageState();
}

class _ScannerLogsPageState extends State<ScannerLogsPage> {
  final _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: ColoredBox(
        color: ScannerTheme.background,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: ScannerTheme.panelDecoration(),
              child: TextField(
                controller: _search,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.search),
                  labelText: 'Search name',
                ),
                onChanged: (_) => setState(() {}),
              ),
            ),
            const SizedBox(height: 12),
            const TabBar(
              labelColor: ScannerTheme.primary,
              indicatorColor: ScannerTheme.primary,
              tabs: [
                Tab(text: 'Attendance'),
                Tab(text: 'Gate Pass'),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: MediaQuery.sizeOf(context).height - 250,
              child: TabBarView(
                children: [
                  SingleChildScrollView(
                    child: _ScannerAttendanceLogsTable(
                      limit: 200,
                      search: _search.text,
                    ),
                  ),
                  SingleChildScrollView(
                    child: _ScannerGatePassLogsTable(
                      limit: 200,
                      search: _search.text,
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

class _ScannerAttendanceLogsTable extends StatelessWidget {
  const _ScannerAttendanceLogsTable({
    required this.limit,
    required this.search,
  });

  final int limit;
  final String search;

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: app.attendance.logsStream(limit: limit),
      builder: (context, snapshot) {
        final query = search.toLowerCase();
        final pairs = _attendancePairs(
          (snapshot.data?.docs ?? [])
              .map(AttendanceLog.fromDoc)
              .where(
                (log) =>
                    query.isEmpty || log.fullName.toLowerCase().contains(query),
              )
              .toList(),
        );
        if (pairs.isEmpty) {
          return const EmptyState(title: 'No attendance logs found');
        }
        return _ScannerTableSurface(
          child: DataTable(
            columns: const [
              DataColumn(label: Text('#')),
              DataColumn(label: Text('Name')),
              DataColumn(label: Text('Time In')),
              DataColumn(label: Text('Time Out')),
            ],
            rows: [
              for (var index = 0; index < pairs.length; index++)
                DataRow(
                  cells: [
                    DataCell(Text('${index + 1}')),
                    DataCell(Text(pairs[index].name)),
                    DataCell(Text(pairs[index].timeIn)),
                    DataCell(Text(pairs[index].timeOut)),
                  ],
                ),
            ],
          ),
        );
      },
    );
  }

  List<_AttendanceLogPair> _attendancePairs(List<AttendanceLog> logs) {
    final grouped = <String, _AttendanceLogPair>{};

    for (final log in logs) {
      if (log.attendanceStatus == AttendanceStatus.duplicate) continue;
      final key = '${log.dateKey}-${log.personId}';
      final pair = grouped.putIfAbsent(
        key,
        () => _AttendanceLogPair(name: log.fullName, timestamp: log.timestamp),
      );
      pair.keepLatestTimestamp(log.timestamp);
      if (log.attendanceType.isTimeIn && pair.timeIn == '-') {
        pair.timeIn = log.timeText;
      }
      if (log.attendanceType.isTimeOut && pair.timeOut == '-') {
        pair.timeOut = log.timeText;
      }
    }

    return grouped.values.toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }
}

class _ScannerGatePassLogsTable extends StatelessWidget {
  const _ScannerGatePassLogsTable({required this.limit, required this.search});

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
                  query.isEmpty || log.fullName.toLowerCase().contains(query),
            )
            .toList();
        if (logs.isEmpty) {
          return const EmptyState(title: 'No gate pass logs found');
        }
        return _ScannerTableSurface(
          child: DataTable(
            columns: const [
              DataColumn(label: Text('#')),
              DataColumn(label: Text('Name')),
              DataColumn(label: Text('Time Out')),
              DataColumn(label: Text('Time In')),
            ],
            rows: [
              for (var index = 0; index < logs.length; index++)
                DataRow(
                  cells: [
                    DataCell(Text('${index + 1}')),
                    DataCell(Text(logs[index].fullName)),
                    DataCell(Text(logs[index].exitTimeText)),
                    DataCell(
                      Text(
                        logs[index].returnTimeText.isEmpty
                            ? '-'
                            : logs[index].returnTimeText,
                      ),
                    ),
                  ],
                ),
            ],
          ),
        );
      },
    );
  }
}

class _AttendanceLogPair {
  _AttendanceLogPair({required this.name, required this.timestamp});

  final String name;
  DateTime timestamp;
  String timeIn = '-';
  String timeOut = '-';

  void keepLatestTimestamp(DateTime nextTimestamp) {
    if (nextTimestamp.isAfter(timestamp)) timestamp = nextTimestamp;
  }
}

class _ScannerTableSurface extends StatelessWidget {
  const _ScannerTableSurface({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: ScannerTheme.surface,
        border: Border.all(color: ScannerTheme.border),
        borderRadius: BorderRadius.circular(8),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: child,
      ),
    );
  }
}
