import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/constants/enums.dart';
import '../../models/models.dart';
import '../../shared/widgets/admin.dart';
import '../../shared/widgets/app_widgets.dart';
import 'attendance_logs_page.dart';
import 'viewmodels/school_admin_viewmodel.dart';

part 'widgets/active_school_year_banner.dart';
part 'widgets/today_breakdown_card.dart';
part 'widgets/weekly_trend_chart.dart';
part 'widgets/leaderboard_card.dart';

class SchoolAdminDashboardPage extends StatefulWidget {
  const SchoolAdminDashboardPage({super.key});

  @override
  State<SchoolAdminDashboardPage> createState() =>
      _SchoolAdminDashboardPageState();
}

class _SchoolAdminDashboardPageState extends State<SchoolAdminDashboardPage> {
  Future<Map<String, List<_Performer>>> _loadLeaderboard(
    SchoolAdminViewModel app,
    String schoolYearId,
  ) async {
    final snapshot = await app.repository
        .schoolYearCollection(schoolYearId, 'attendance_logs')
        .where('attendanceType', isEqualTo: 'timeIn')
        .where('attendanceStatus', whereIn: ['early', 'onTime'])
        .get();

    final logs = snapshot.docs.map(AttendanceLog.fromDoc).toList();
    final studentsMap = <String, _Performer>{};
    final teachersMap = <String, _Performer>{};

    for (final log in logs) {
      final isStudent = log.personRole == PersonRole.student;
      final map = isStudent ? studentsMap : teachersMap;
      final entry = map.putIfAbsent(
        log.personId,
        () => _Performer(log.personId, log.fullName, log.section),
      );
      if (log.attendanceStatus == AttendanceStatus.early) {
        entry.points += 2;
      } else {
        entry.points += 1;
      }
    }

    final topStudents = studentsMap.values.toList()
      ..sort((a, b) => b.points.compareTo(a.points));
    final topTeachers = teachersMap.values.toList()
      ..sort((a, b) => b.points.compareTo(a.points));

    return {
      'students': topStudents.take(10).toList(),
      'teachers': topTeachers.take(10).toList(),
    };
  }

  @override
  Widget build(BuildContext context) {
    final app = SchoolAdminViewModelScope.of(context);
    final todayKey = DateFormat('yyyy-MM-dd').format(DateTime.now());

    return FutureBuilder<SchoolYear?>(
      future: app.attendance.activeSchoolYear(),
      builder: (context, activeYearSnapshot) {
        final schoolYear = activeYearSnapshot.data;
        final hasActiveYear = schoolYear != null;

        return ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              'School Administration Dashboard',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 4),
            Text(
              'Real-time attendance analytics, trends, and top performers overview.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 20),
            _ActiveSchoolYearBanner(
              schoolYear: schoolYear,
              loading:
                  activeYearSnapshot.connectionState == ConnectionState.waiting,
            ),
            const SizedBox(height: 20),
            GridView(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 280,
                mainAxisExtent: 104,
                crossAxisSpacing: 14,
                mainAxisSpacing: 14,
              ),
              children: [
                ActiveSchoolYearCount(
                  collection: 'students',
                  filters: const {'archived': false},
                  builder: (value) => MetricCard(
                    label: 'Total Students',
                    value: value,
                    icon: Icons.school_outlined,
                    color: Colors.teal.shade700,
                  ),
                ),
                ActiveSchoolYearCount(
                  collection: 'teachers',
                  filters: const {'archived': false},
                  builder: (value) => MetricCard(
                    label: 'Total Teachers',
                    value: value,
                    icon: Icons.badge_outlined,
                    color: Colors.indigo.shade700,
                  ),
                ),
                ActiveSchoolYearCount(
                  collection: 'attendance_logs',
                  filters: {
                    'attendanceStatus': AttendanceStatus.late.name,
                    'dateKey': todayKey,
                  },
                  builder: (value) => MetricCard(
                    label: 'Late Today',
                    value: value,
                    icon: Icons.schedule_outlined,
                    color: Colors.amber.shade800,
                  ),
                ),
                ActiveSchoolYearCount(
                  collection: 'attendance_logs',
                  filters: {
                    'attendanceStatus': AttendanceStatus.absent.name,
                    'dateKey': todayKey,
                  },
                  builder: (value) => MetricCard(
                    label: 'Absent Today',
                    value: value,
                    icon: Icons.person_off_outlined,
                    color: Colors.red.shade700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            if (hasActiveYear) ...[
              StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: app.repository
                    .schoolYearCollection(schoolYear.id, 'attendance_logs')
                    .snapshots(),
                builder: (context, logsSnapshot) {
                  if (logsSnapshot.connectionState == ConnectionState.waiting) {
                    return const SizedBox(
                      height: 200,
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }

                  final allLogs = (logsSnapshot.data?.docs ?? [])
                      .map(AttendanceLog.fromDoc)
                      .toList();
                  final todayLogs = allLogs
                      .where((log) => log.dateKey == todayKey)
                      .toList();

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      LayoutBuilder(
                        builder: (context, constraints) {
                          if (constraints.maxWidth < 960) {
                            return Column(
                              children: [
                                _TodayBreakdownCard(logs: todayLogs),
                                const SizedBox(height: 20),
                                _WeeklyTrendChart(logs: allLogs),
                              ],
                            );
                          }
                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: _TodayBreakdownCard(logs: todayLogs),
                              ),
                              const SizedBox(width: 20),
                              Expanded(child: _WeeklyTrendChart(logs: allLogs)),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 24),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final leftWidget = Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Recent Attendance Logs',
                                style: Theme.of(context).textTheme.titleLarge
                                    ?.copyWith(fontWeight: FontWeight.w800),
                              ),
                              const SizedBox(height: 12),
                              const AttendanceLogsTable(limit: 5),
                            ],
                          );

                          if (constraints.maxWidth < 760) {
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                leftWidget,
                                const SizedBox(height: 24),
                                FutureBuilder<Map<String, List<_Performer>>>(
                                  future: _loadLeaderboard(app, schoolYear.id),
                                  builder: (context, perfSnapshot) {
                                    if (perfSnapshot.connectionState ==
                                        ConnectionState.waiting) {
                                      return const Center(
                                        child: CircularProgressIndicator(),
                                      );
                                    }
                                    return _LeaderboardCard(
                                      performers: perfSnapshot.data ?? {},
                                    );
                                  },
                                ),
                              ],
                            );
                          }

                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(flex: 3, child: leftWidget),
                              const SizedBox(width: 20),
                              Expanded(
                                flex: 2,
                                child:
                                    FutureBuilder<
                                      Map<String, List<_Performer>>
                                    >(
                                      future: _loadLeaderboard(
                                        app,
                                        schoolYear.id,
                                      ),
                                      builder: (context, perfSnapshot) {
                                        if (perfSnapshot.connectionState ==
                                            ConnectionState.waiting) {
                                          return const Center(
                                            child: CircularProgressIndicator(),
                                          );
                                        }
                                        return _LeaderboardCard(
                                          performers: perfSnapshot.data ?? {},
                                        );
                                      },
                                    ),
                              ),
                            ],
                          );
                        },
                      ),
                    ],
                  );
                },
              ),
            ] else ...[
              const SizedBox(height: 40),
              const EmptyState(
                title: 'No active school year found',
                subtitle:
                    'Active school year data and statistics will appear here once a school year is created.',
              ),
            ],
          ],
        );
      },
    );
  }
}

class _Performer {
  final String id;
  final String name;
  final String section;
  int points = 0;
  _Performer(this.id, this.name, this.section);
}
