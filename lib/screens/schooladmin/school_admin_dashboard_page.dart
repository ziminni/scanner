import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/constants/enums.dart';
import '../../core/services/app_controller.dart';
import '../../models/models.dart';
import '../../shared/widgets/admin_widgets.dart';
import '../../shared/widgets/app_widgets.dart';
import 'attendance_logs_page.dart';

class SchoolAdminDashboardPage extends StatefulWidget {
  const SchoolAdminDashboardPage({super.key});

  @override
  State<SchoolAdminDashboardPage> createState() => _SchoolAdminDashboardPageState();
}

class _SchoolAdminDashboardPageState extends State<SchoolAdminDashboardPage> {
  Future<Map<String, List<_Performer>>> _loadLeaderboard(
    AppController app,
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
    final app = AppScope.of(context);
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
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
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
              loading: activeYearSnapshot.connectionState == ConnectionState.waiting,
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
                              Expanded(child: _TodayBreakdownCard(logs: todayLogs)),
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
                                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                      fontWeight: FontWeight.w800,
                                    ),
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
                                    if (perfSnapshot.connectionState == ConnectionState.waiting) {
                                      return const Center(child: CircularProgressIndicator());
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
                                child: FutureBuilder<Map<String, List<_Performer>>>(
                                  future: _loadLeaderboard(app, schoolYear.id),
                                  builder: (context, perfSnapshot) {
                                    if (perfSnapshot.connectionState == ConnectionState.waiting) {
                                      return const Center(child: CircularProgressIndicator());
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
                subtitle: 'Active school year data and statistics will appear here once a school year is created.',
              ),
            ],
          ],
        );
      },
    );
  }
}

class _ActiveSchoolYearBanner extends StatelessWidget {
  const _ActiveSchoolYearBanner({this.schoolYear, required this.loading});

  final SchoolYear? schoolYear;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final title = schoolYear?.name ?? 'No active school year';
    final subtitle = schoolYear == null
        ? 'Create a school year to begin collecting attendance data'
        : _schoolYearRange(schoolYear!);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF026B2F), Color(0xFF03913F)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF026B2F).withAlpha(40),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ACTIVE SCHOOL YEAR',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: Colors.white.withAlpha(190),
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  loading ? 'Loading...' : title,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.white.withAlpha(210),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              schoolYear == null ? 'Inactive' : 'Active',
              style: TextStyle(
                color: schoolYear == null ? Colors.grey.shade800 : const Color(0xFF026B2F),
                fontWeight: FontWeight.w800,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  static String _schoolYearRange(SchoolYear schoolYear) {
    final start = schoolYear.termStarts.whereType<DateTime>().firstOrNull;
    final end = schoolYear.termEnds.whereType<DateTime>().lastOrNull;
    if (start == null && end == null) return 'Date range not set';
    final formatter = DateFormat('MMM d, yyyy');
    return '${start == null ? 'Not set' : formatter.format(start)} - ${end == null ? 'Not set' : formatter.format(end)}';
  }
}

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
              Icon(
                Icons.analytics_outlined,
                color: theme.colorScheme.primary,
              ),
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
              Icon(
                Icons.trending_up,
                color: theme.colorScheme.primary,
              ),
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
                                  color: theme.colorScheme.primary.withAlpha(20),
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
                                      color: theme.colorScheme.primary.withAlpha(40),
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

class _LeaderboardCard extends StatefulWidget {
  const _LeaderboardCard({required this.performers});

  final Map<String, List<_Performer>> performers;

  @override
  State<_LeaderboardCard> createState() => _LeaderboardCardState();
}

class _LeaderboardCardState extends State<_LeaderboardCard>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final students = widget.performers['students'] ?? [];
    final teachers = widget.performers['teachers'] ?? [];

    return DataSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Top 10 Early',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              TabBar(
                controller: _tabController,
                isScrollable: true,
                labelColor: theme.colorScheme.primary,
                unselectedLabelColor: theme.colorScheme.onSurfaceVariant,
                indicatorColor: theme.colorScheme.primary,
                dividerColor: Colors.transparent,
                tabs: const [
                  Tab(
                    icon: Icon(Icons.school_outlined, size: 18),
                    text: 'Students',
                  ),
                  Tab(
                    icon: Icon(Icons.badge_outlined, size: 18),
                    text: 'Teachers',
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 380,
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildLeaderboardTable(students, isStudent: true),
                _buildLeaderboardTable(teachers, isStudent: false),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLeaderboardTable(List<_Performer> list, {required bool isStudent}) {
    if (list.isEmpty) {
      return const Center(child: Text('No check-in rankings available yet.'));
    }

    final theme = Theme.of(context);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SingleChildScrollView(
        child: DataTable(
          horizontalMargin: 8,
          columnSpacing: 16,
          dataRowMinHeight: 32,
          dataRowMaxHeight: 32,
          headingRowHeight: 32,
          columns: [
            const DataColumn(
              label: Text('Rank', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            const DataColumn(
              label: Text('ID', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            const DataColumn(
              label: Text('Name', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            if (isStudent)
              const DataColumn(
                label:
                    Text('Section', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            const DataColumn(
              label:
                  Text('Points', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
          rows: [
            for (var i = 0; i < list.length; i++) ...[
              _buildDataRow(i + 1, list[i], isStudent, theme),
            ],
          ],
        ),
      ),
    );
  }

  DataRow _buildDataRow(
    int rank,
    _Performer performer,
    bool isStudent,
    ThemeData theme,
  ) {
    Color rankColor;
    FontWeight rankWeight = FontWeight.normal;
    Widget rankWidget;

    if (rank == 1) {
      rankColor = const Color(0xFFD4AF37); // Gold
      rankWeight = FontWeight.w900;
      rankWidget = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.emoji_events, color: rankColor, size: 15),
          const SizedBox(width: 4),
          Text(
            '$rank',
            style: TextStyle(color: rankColor, fontWeight: rankWeight),
          ),
        ],
      );
    } else if (rank == 2) {
      rankColor = const Color(0xFFC0C0C0); // Silver
      rankWeight = FontWeight.w800;
      rankWidget = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.emoji_events, color: rankColor, size: 15),
          const SizedBox(width: 4),
          Text(
            '$rank',
            style: TextStyle(color: rankColor, fontWeight: rankWeight),
          ),
        ],
      );
    } else if (rank == 3) {
      rankColor = const Color(0xFFCD7F32); // Bronze
      rankWeight = FontWeight.w800;
      rankWidget = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.emoji_events, color: rankColor, size: 15),
          const SizedBox(width: 4),
          Text(
            '$rank',
            style: TextStyle(color: rankColor, fontWeight: rankWeight),
          ),
        ],
      );
    } else {
      rankWidget = Text('$rank', style: const TextStyle(color: Colors.grey));
    }

    return DataRow(
      cells: [
        DataCell(rankWidget),
        DataCell(Text(performer.id)),
        DataCell(Text(
          performer.name,
          style: const TextStyle(fontWeight: FontWeight.w600),
        )),
        if (isStudent) DataCell(Text(performer.section)),
        DataCell(
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withAlpha(20),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '${performer.points} pts',
              style: TextStyle(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
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
