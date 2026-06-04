part of '../attendance_logs_page.dart';

class AttendanceLogsTable extends StatefulWidget {
  const AttendanceLogsTable({
    super.key,
    required this.limit,
    this.search = '',
    this.roleFilter = '',
    this.typeFilter = '',
    this.statusFilter = '',
    this.syncFilter = '',
    this.sectionFilter = '',
    this.teacherScheduleFilter = '',
  });

  final int limit;
  final String search;
  final String roleFilter;
  final String typeFilter;
  final String statusFilter;
  final String syncFilter;
  final String sectionFilter;
  final String teacherScheduleFilter;

  @override
  State<AttendanceLogsTable> createState() => _AttendanceLogsTableState();
}

class _AttendanceLogsTableState extends State<AttendanceLogsTable> {
  static const List<int> _itemsPerPageOptions = [10, 25, 50, 100];

  int _currentPage = 0;
  int _itemsPerPage = 10;

  @override
  void didUpdateWidget(covariant AttendanceLogsTable oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.search != widget.search ||
        oldWidget.limit != widget.limit ||
        oldWidget.roleFilter != widget.roleFilter ||
        oldWidget.typeFilter != widget.typeFilter ||
        oldWidget.statusFilter != widget.statusFilter ||
        oldWidget.syncFilter != widget.syncFilter ||
        oldWidget.sectionFilter != widget.sectionFilter ||
        oldWidget.teacherScheduleFilter != widget.teacherScheduleFilter) {
      _currentPage = 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    if (widget.teacherScheduleFilter.isNotEmpty) {
      return FutureBuilder<SchoolYear?>(
        future: app.attendance.activeSchoolYear(),
        builder: (context, schoolYearSnapshot) {
          final schoolYear = schoolYearSnapshot.data;
          if (schoolYear == null) {
            return const EmptyState(title: 'No attendance logs found');
          }
          return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: app.repository.activeTeachersStream(schoolYear.id),
            builder: (context, teachersSnapshot) {
              final teacherSchedules = {
                for (final doc in teachersSnapshot.data?.docs ?? [])
                  (doc.data()['teacherId'] as String? ?? '').trim():
                      _teacherSchedule(doc.data()),
              }..removeWhere((teacherId, _) => teacherId.isEmpty);
              return _buildLogs(context, app, teacherSchedules);
            },
          );
        },
      );
    }
    return _buildLogs(context, app, const {});
  }

  Widget _buildLogs(
    BuildContext context,
    AppController app,
    Map<String, String> teacherSchedules,
  ) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: app.attendance.logsStream(limit: widget.limit),
      builder: (context, snapshot) {
        final query = widget.search.toLowerCase();
        final logs = (snapshot.data?.docs ?? []).map(AttendanceLog.fromDoc).where((
          log,
        ) {
          if (widget.roleFilter.isNotEmpty &&
              log.personRole.label != widget.roleFilter) {
            return false;
          }
          if (widget.typeFilter.isNotEmpty &&
              log.attendanceType.label != widget.typeFilter) {
            return false;
          }
          if (widget.statusFilter.isNotEmpty &&
              log.attendanceStatus.label != widget.statusFilter) {
            return false;
          }
          if (widget.syncFilter.isNotEmpty &&
              log.syncStatus.label != widget.syncFilter) {
            return false;
          }
          if (widget.sectionFilter.isNotEmpty &&
              log.section != widget.sectionFilter) {
            return false;
          }
          if (widget.teacherScheduleFilter.isNotEmpty &&
              teacherSchedules[log.personId] != widget.teacherScheduleFilter) {
            return false;
          }
          return query.isEmpty ||
              '${log.personId} ${log.fullName} ${log.section} ${log.scannedBy}'
                  .toLowerCase()
                  .contains(query);
        }).toList();
        if (logs.isEmpty) {
          return const EmptyState(title: 'No attendance logs found');
        }
        final totalPages = (logs.length / _itemsPerPage).ceil();
        final currentPage = totalPages == 0
            ? 0
            : _currentPage.clamp(0, totalPages - 1).toInt();
        final start = currentPage * _itemsPerPage;
        final end = (start + _itemsPerPage).clamp(0, logs.length).toInt();
        final paginatedLogs = logs.sublist(start, end);

        return DataSurface(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FullWidthHorizontalTable(
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
                    for (final log in paginatedLogs)
                      DataRow(
                        cells: [
                          DataCell(Text(log.personId)),
                          DataCell(Text(log.fullName)),
                          DataCell(Text(log.personRole.label)),
                          DataCell(Text(log.section)),
                          DataCell(Text('${log.dateKey} ${log.timeText}')),
                          DataCell(Text(log.attendanceType.label)),
                          DataCell(
                            StatusBadge(
                              label: log.attendanceStatus.label,
                              type:
                                  log.attendanceStatus == AttendanceStatus.late
                                  ? 'late'
                                  : 'active',
                            ),
                          ),
                          DataCell(Text(log.scannedBy)),
                          DataCell(Text(log.syncStatus.label)),
                        ],
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              AdminTableFooter(
                currentPage: currentPage,
                totalItems: logs.length,
                itemsPerPage: _itemsPerPage,
                itemLabel: 'logs',
                itemsPerPageOptions: _itemsPerPageOptions,
                onItemsPerPageChanged: (value) {
                  setState(() {
                    _itemsPerPage = value;
                    _currentPage = 0;
                  });
                },
              ),
              if (totalPages > 1) ...[
                const SizedBox(height: 8),
                AdminPaginationControls(
                  currentPage: currentPage,
                  totalPages: totalPages,
                  onPageChanged: (page) {
                    setState(() {
                      _currentPage = page;
                    });
                  },
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  static String _teacherSchedule(Map<String, dynamic> data) {
    final timeIn = data['assignedTimeIn'] as String? ?? '07:00';
    final timeOut = data['assignedTimeOut'] as String? ?? '17:00';
    return '$timeIn - $timeOut';
  }
}

class GatePassLogsTable extends StatelessWidget {
  const GatePassLogsTable({
    super.key,
    required this.limit,
    this.search = '',
    this.roleFilter = '',
    this.syncFilter = '',
    this.sectionFilter = '',
    this.teacherScheduleFilter = '',
  });

  final int limit;
  final String search;
  final String roleFilter;
  final String syncFilter;
  final String sectionFilter;
  final String teacherScheduleFilter;

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    if (teacherScheduleFilter.isNotEmpty) {
      return FutureBuilder<SchoolYear?>(
        future: app.attendance.activeSchoolYear(),
        builder: (context, schoolYearSnapshot) {
          final schoolYear = schoolYearSnapshot.data;
          if (schoolYear == null) {
            return const EmptyState(title: 'No gate pass logs found');
          }
          return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: app.repository.activeTeachersStream(schoolYear.id),
            builder: (context, teachersSnapshot) {
              final teacherSchedules = {
                for (final doc in teachersSnapshot.data?.docs ?? [])
                  (doc.data()['teacherId'] as String? ?? '').trim():
                      _teacherSchedule(doc.data()),
              }..removeWhere((teacherId, _) => teacherId.isEmpty);
              return _buildLogs(context, app, teacherSchedules);
            },
          );
        },
      );
    }
    return _buildLogs(context, app, const {});
  }

  Widget _buildLogs(
    BuildContext context,
    AppController app,
    Map<String, String> teacherSchedules,
  ) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: app.attendance.gatePassLogsStream(limit: limit),
      builder: (context, snapshot) {
        final query = search.toLowerCase();
        final logs = (snapshot.data?.docs ?? []).map(GatePassLog.fromDoc).where((
          log,
        ) {
          if (roleFilter.isNotEmpty && log.personRole.label != roleFilter) {
            return false;
          }
          if (syncFilter.isNotEmpty && log.syncStatus.label != syncFilter) {
            return false;
          }
          if (sectionFilter.isNotEmpty && log.section != sectionFilter) {
            return false;
          }
          if (teacherScheduleFilter.isNotEmpty &&
              teacherSchedules[log.personId] != teacherScheduleFilter) {
            return false;
          }
          return query.isEmpty ||
              '${log.personId} ${log.fullName} ${log.section} ${log.scannedBy} ${log.reason}'
                  .toLowerCase()
                  .contains(query);
        }).toList();
        if (logs.isEmpty) {
          return const EmptyState(title: 'No gate pass logs found');
        }
        return DataSurface(
          child: FullWidthHorizontalTable(
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

  static String _teacherSchedule(Map<String, dynamic> data) {
    final timeIn = data['assignedTimeIn'] as String? ?? '07:00';
    final timeOut = data['assignedTimeOut'] as String? ?? '17:00';
    return '$timeIn - $timeOut';
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
