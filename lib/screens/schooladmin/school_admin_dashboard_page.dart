import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/constants/enums.dart';
import '../../models/models.dart';
import '../../shared/widgets/admin.dart';
import '../../shared/widgets/app_widgets.dart';
import 'viewmodels/school_admin_viewmodel.dart';

part 'widgets/active_school_year_banner.dart';
part 'widgets/today_breakdown_card.dart';
part 'widgets/weekly_trend_chart.dart';
part 'widgets/leaderboard_card.dart';
part 'widgets/recent_attendance_card.dart';

class SchoolAdminDashboardPage extends StatefulWidget {
  const SchoolAdminDashboardPage({super.key});

  @override
  State<SchoolAdminDashboardPage> createState() =>
      _SchoolAdminDashboardPageState();
}

class _SchoolAdminDashboardPageState extends State<SchoolAdminDashboardPage> {
  Future<SchoolYear?>? _activeSchoolYearFuture;
  final _leaderboardFutures = <String, Future<Map<String, List<_Performer>>>>{};
  final _todayLogStreams =
      <String, Stream<QuerySnapshot<Map<String, dynamic>>>>{};
  final _weeklyTrendStreams =
      <String, Stream<QuerySnapshot<Map<String, dynamic>>>>{};
  final _recentLogStreams =
      <String, Stream<QuerySnapshot<Map<String, dynamic>>>>{};

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _activeSchoolYearFuture ??= SchoolAdminViewModelScope.of(
      context,
    ).attendance.activeSchoolYear();
  }

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

  Future<Map<String, List<_Performer>>> _leaderboardFuture(
    SchoolAdminViewModel app,
    String schoolYearId,
  ) {
    return _leaderboardFutures.putIfAbsent(
      schoolYearId,
      () => _loadLeaderboard(app, schoolYearId),
    );
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> _todayLogsStream(
    SchoolAdminViewModel app,
    String schoolYearId,
    String todayKey,
  ) {
    return _todayLogStreams.putIfAbsent(
      '$schoolYearId:$todayKey',
      () => app.repository
          .schoolYearCollection(schoolYearId, 'attendance_logs')
          .where('dateKey', isEqualTo: todayKey)
          .snapshots(),
    );
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> _weeklyTrendStream(
    SchoolAdminViewModel app,
    String schoolYearId,
  ) {
    final today = DateTime.now();
    final formatter = DateFormat('yyyy-MM-dd');
    final recentDateKeys = [
      for (var daysAgo = 0; daysAgo < 10; daysAgo++)
        formatter.format(today.subtract(Duration(days: daysAgo))),
    ];

    return _weeklyTrendStreams.putIfAbsent(
      '$schoolYearId:${recentDateKeys.first}',
      () => app.repository
          .schoolYearCollection(schoolYearId, 'attendance_logs')
          .where('dateKey', whereIn: recentDateKeys)
          .snapshots(),
    );
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> _recentLogsStream(
    SchoolAdminViewModel app,
    String schoolYearId,
  ) {
    return _recentLogStreams.putIfAbsent(
      schoolYearId,
      () => app.repository
          .schoolYearCollection(schoolYearId, 'attendance_logs')
          .orderBy('timestamp', descending: true)
          .limit(6)
          .snapshots(),
    );
  }

  List<AttendanceLog> _logsFromSnapshot(
    AsyncSnapshot<QuerySnapshot<Map<String, dynamic>>> snapshot,
  ) {
    return (snapshot.data?.docs ?? []).map(AttendanceLog.fromDoc).toList();
  }

  @override
  Widget build(BuildContext context) {
    final app = SchoolAdminViewModelScope.of(context);
    final todayKey = DateFormat('yyyy-MM-dd').format(DateTime.now());

    return FutureBuilder<SchoolYear?>(
      future: _activeSchoolYearFuture,
      builder: (context, activeYearSnapshot) {
        final schoolYear = activeYearSnapshot.data;
        final hasActiveYear = schoolYear != null;

        return AdminPage(
          title: 'Dashboard',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _ActiveSchoolYearBanner(
                schoolYear: schoolYear,
                loading:
                    activeYearSnapshot.connectionState ==
                    ConnectionState.waiting,
              ),
              const SizedBox(height: 20),
              GridView(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 320,
                  mainAxisExtent: 118,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                ),
                children: [
                  ActiveSchoolYearCount(
                    collection: 'students',
                    filters: const {'archived': false},
                    builder: (value) => _DashboardMetricCard(
                      label: 'Total Students',
                      value: value,
                      icon: Icons.school_outlined,
                      color: Colors.teal.shade700,
                    ),
                  ),
                  ActiveSchoolYearCount(
                    collection: 'teachers',
                    filters: const {'archived': false},
                    builder: (value) => _DashboardMetricCard(
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
                    builder: (value) => _DashboardMetricCard(
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
                    builder: (value) => _DashboardMetricCard(
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
                _DashboardAttendanceSection(
                  todayLogs: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                    stream: _todayLogsStream(app, schoolYear.id, todayKey),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const _DashboardLoadingCard(
                          title: "Today's Attendance",
                        );
                      }
                      return _TodayBreakdownCard(
                        logs: _logsFromSnapshot(snapshot),
                      );
                    },
                  ),
                  weeklyTrend:
                      StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                        stream: _weeklyTrendStream(app, schoolYear.id),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const _DashboardLoadingCard(
                              title: 'Attendance Trend',
                            );
                          }
                          return _WeeklyTrendChart(
                            logs: _logsFromSnapshot(snapshot),
                          );
                        },
                      ),
                  leaderboard: FutureBuilder<Map<String, List<_Performer>>>(
                    future: _leaderboardFuture(app, schoolYear.id),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const _DashboardLoadingCard(
                          title: 'Top 10 Early',
                          height: 480,
                        );
                      }
                      return _LeaderboardCard(performers: snapshot.data ?? {});
                    },
                  ),
                  recentLogs:
                      StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                        stream: _recentLogsStream(app, schoolYear.id),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const _DashboardLoadingCard(
                              title: 'Recent Attendance Logs',
                              height: 480,
                            );
                          }
                          return _RecentAttendanceCard(
                            logs: _logsFromSnapshot(snapshot),
                          );
                        },
                      ),
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
          ),
        );
      },
    );
  }
}

class _DashboardAttendanceSection extends StatelessWidget {
  const _DashboardAttendanceSection({
    required this.todayLogs,
    required this.weeklyTrend,
    required this.leaderboard,
    required this.recentLogs,
  });

  final Widget todayLogs;
  final Widget weeklyTrend;
  final Widget leaderboard;
  final Widget recentLogs;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth < 960) {
              return Column(
                children: [todayLogs, const SizedBox(height: 20), weeklyTrend],
              );
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: todayLogs),
                const SizedBox(width: 20),
                Expanded(child: weeklyTrend),
              ],
            );
          },
        ),
        const SizedBox(height: 24),
        LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth < 760) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [leaderboard, const SizedBox(height: 24), recentLogs],
              );
            }

            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 3, child: leaderboard),
                const SizedBox(width: 20),
                Expanded(flex: 2, child: recentLogs),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _DashboardLoadingCard extends StatelessWidget {
  const _DashboardLoadingCard({required this.title, this.height = 260});

  final String title;
  final double height;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return RepaintBoundary(
      child: Container(
        width: double.infinity,
        height: height,
        padding: const EdgeInsets.all(18),
        decoration: _dashboardCardDecoration(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w900,
              ),
            ),
            const Expanded(child: Center(child: CircularProgressIndicator())),
          ],
        ),
      ),
    );
  }
}

BoxDecoration _dashboardCardDecoration(BuildContext context) {
  return BoxDecoration(
    color: Theme.of(context).cardTheme.color ?? Colors.white,
    border: Border.all(color: Theme.of(context).dividerColor.withAlpha(70)),
    borderRadius: BorderRadius.circular(22),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withAlpha(7),
        blurRadius: 12,
        offset: const Offset(0, 4),
      ),
    ],
  );
}

class _DashboardCardHeader extends StatelessWidget {
  const _DashboardCardHeader({
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  final String title;
  final String subtitle;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withAlpha(22),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: theme.colorScheme.primary),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DashboardMetricCard extends StatelessWidget {
  const _DashboardMetricCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return RepaintBoundary(
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: _dashboardCardDecoration(context),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withAlpha(24),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      color: theme.colorScheme.onSurface,
                      fontWeight: FontWeight.w900,
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

class _Performer {
  final String id;
  final String name;
  final String section;
  int points = 0;
  _Performer(this.id, this.name, this.section);
}
