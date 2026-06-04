import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../core/services/app_controller.dart';
import '../../models/models.dart';
import '../../shared/widgets/app_widgets.dart';
import '../../shared/widgets/admin_widgets.dart';
import '../../core/constants/enums.dart';

part 'widgets/attendance_logs_table.dart';

class AttendanceLogsPage extends StatefulWidget {
  const AttendanceLogsPage({super.key});

  @override
  State<AttendanceLogsPage> createState() => _AttendanceLogsPageState();
}

class _AttendanceLogsPageState extends State<AttendanceLogsPage>
    with SingleTickerProviderStateMixin {
  final _search = TextEditingController();
  late final TabController _tabController;
  String _sectionFilter = '';
  String _scheduleFilter = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_handleTabChanged);
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabChanged);
    _tabController.dispose();
    _search.dispose();
    super.dispose();
  }

  void _handleTabChanged() {
    if (!_tabController.indexIsChanging) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return AdminPage(
      title: 'Attendance Logs',
      child: Column(
        children: [
          _LogFilters(
            search: _search,
            searchLabel: 'Search name, ID, section, scanner',
            filters: [
              _AttendanceContextFilter(
                tabIndex: _tabController.index,
                sectionValue: _sectionFilter,
                scheduleValue: _scheduleFilter,
                onSectionChanged: (value) =>
                    setState(() => _sectionFilter = value),
                onScheduleChanged: (value) =>
                    setState(() => _scheduleFilter = value),
              ),
            ],
            onSearchChanged: () => setState(() {}),
          ),
          const SizedBox(height: 12),
          _AttendanceRoleTabs(
            controller: _tabController,
            search: _search.text,
            sectionFilter: _sectionFilter,
            scheduleFilter: _scheduleFilter,
          ),
        ],
      ),
    );
  }
}

class _AttendanceRoleTabs extends StatelessWidget {
  const _AttendanceRoleTabs({
    required this.controller,
    required this.search,
    required this.sectionFilter,
    required this.scheduleFilter,
  });

  final TabController controller;
  final String search;
  final String sectionFilter;
  final String scheduleFilter;

  @override
  Widget build(BuildContext context) {
    final tableHeight = (MediaQuery.sizeOf(context).height - 300)
        .clamp(420.0, 900.0)
        .toDouble();
    return Column(
      children: [
        Material(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          child: TabBar(
            controller: controller,
            dividerColor: Colors.transparent,
            labelColor: Theme.of(context).colorScheme.primary,
            unselectedLabelColor: Theme.of(
              context,
            ).colorScheme.onSurfaceVariant,
            indicatorSize: TabBarIndicatorSize.tab,
            indicator: BoxDecoration(
              color: Theme.of(
                context,
              ).colorScheme.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            tabs: const [
              Tab(icon: Icon(Icons.school_outlined), text: 'Students'),
              Tab(icon: Icon(Icons.badge_outlined), text: 'Teachers'),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: tableHeight,
          child: TabBarView(
            controller: controller,
            children: [
              AttendanceLogsTable(
                limit: 200,
                search: search,
                roleFilter: PersonRole.student.label,
                sectionFilter: sectionFilter,
              ),
              AttendanceLogsTable(
                limit: 200,
                search: search,
                roleFilter: PersonRole.teacher.label,
                teacherScheduleFilter: scheduleFilter,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _AttendanceContextFilter extends StatelessWidget {
  const _AttendanceContextFilter({
    required this.tabIndex,
    required this.sectionValue,
    required this.scheduleValue,
    required this.onSectionChanged,
    required this.onScheduleChanged,
  });

  final int tabIndex;
  final String sectionValue;
  final String scheduleValue;
  final ValueChanged<String> onSectionChanged;
  final ValueChanged<String> onScheduleChanged;

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    if (tabIndex == 0) {
      return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: app.repository.activeSectionsStream(),
        builder: (context, snapshot) {
          final sections =
              snapshot.data?.docs
                  .map((doc) => (doc.data()['name'] as String? ?? '').trim())
                  .where((name) => name.isNotEmpty)
                  .toSet()
                  .toList()
                ?..sort();
          final options = sections ?? const <String>[];
          return _LogFilterSelect(
            label: 'Section',
            value: options.contains(sectionValue) ? sectionValue : '',
            options: options,
            onChanged: onSectionChanged,
          );
        },
      );
    }

    return FutureBuilder<SchoolYear?>(
      future: app.attendance.activeSchoolYear(),
      builder: (context, schoolYearSnapshot) {
        final schoolYear = schoolYearSnapshot.data;
        if (schoolYear == null) {
          return _LogFilterSelect(
            label: 'Schedule',
            value: '',
            options: const [],
            onChanged: onScheduleChanged,
          );
        }
        return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: app.repository.activeTeachersStream(schoolYear.id),
          builder: (context, snapshot) {
            final schedules =
                snapshot.data?.docs
                    .map((doc) {
                      final data = doc.data();
                      final timeIn =
                          data['assignedTimeIn'] as String? ?? '07:00';
                      final timeOut =
                          data['assignedTimeOut'] as String? ?? '17:00';
                      return '$timeIn - $timeOut';
                    })
                    .where((schedule) => schedule.trim().isNotEmpty)
                    .toSet()
                    .toList()
                  ?..sort();
            final options = schedules ?? const <String>[];
            return _LogFilterSelect(
              label: 'Schedule',
              value: options.contains(scheduleValue) ? scheduleValue : '',
              options: options,
              onChanged: onScheduleChanged,
            );
          },
        );
      },
    );
  }
}

class GatePassLogsPage extends StatefulWidget {
  const GatePassLogsPage({super.key});

  @override
  State<GatePassLogsPage> createState() => _GatePassLogsPageState();
}

class _GatePassLogsPageState extends State<GatePassLogsPage>
    with SingleTickerProviderStateMixin {
  final _search = TextEditingController();
  late final TabController _tabController;
  String _sectionFilter = '';
  String _scheduleFilter = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_handleTabChanged);
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabChanged);
    _tabController.dispose();
    _search.dispose();
    super.dispose();
  }

  void _handleTabChanged() {
    if (!_tabController.indexIsChanging) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return AdminPage(
      title: 'Gate Pass Logs',
      child: Column(
        children: [
          _LogFilters(
            search: _search,
            searchLabel: 'Search name, ID, section, scanner, reason',
            filters: [
              _AttendanceContextFilter(
                tabIndex: _tabController.index,
                sectionValue: _sectionFilter,
                scheduleValue: _scheduleFilter,
                onSectionChanged: (value) =>
                    setState(() => _sectionFilter = value),
                onScheduleChanged: (value) =>
                    setState(() => _scheduleFilter = value),
              ),
            ],
            onSearchChanged: () => setState(() {}),
          ),
          const SizedBox(height: 12),
          _GatePassRoleTabs(
            controller: _tabController,
            search: _search.text,
            sectionFilter: _sectionFilter,
            scheduleFilter: _scheduleFilter,
          ),
        ],
      ),
    );
  }
}

class _GatePassRoleTabs extends StatelessWidget {
  const _GatePassRoleTabs({
    required this.controller,
    required this.search,
    required this.sectionFilter,
    required this.scheduleFilter,
  });

  final TabController controller;
  final String search;
  final String sectionFilter;
  final String scheduleFilter;

  @override
  Widget build(BuildContext context) {
    final tableHeight = (MediaQuery.sizeOf(context).height - 300)
        .clamp(420.0, 900.0)
        .toDouble();
    return Column(
      children: [
        Material(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          child: TabBar(
            controller: controller,
            dividerColor: Colors.transparent,
            labelColor: Theme.of(context).colorScheme.primary,
            unselectedLabelColor: Theme.of(
              context,
            ).colorScheme.onSurfaceVariant,
            indicatorSize: TabBarIndicatorSize.tab,
            indicator: BoxDecoration(
              color: Theme.of(
                context,
              ).colorScheme.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            tabs: const [
              Tab(icon: Icon(Icons.school_outlined), text: 'Students'),
              Tab(icon: Icon(Icons.badge_outlined), text: 'Teachers'),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: tableHeight,
          child: TabBarView(
            controller: controller,
            children: [
              GatePassLogsTable(
                limit: 200,
                search: search,
                roleFilter: PersonRole.student.label,
                sectionFilter: sectionFilter,
              ),
              GatePassLogsTable(
                limit: 200,
                search: search,
                roleFilter: PersonRole.teacher.label,
                teacherScheduleFilter: scheduleFilter,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _LogFilters extends StatelessWidget {
  const _LogFilters({
    required this.search,
    required this.searchLabel,
    required this.filters,
    required this.onSearchChanged,
  });

  final TextEditingController search;
  final String searchLabel;
  final List<Widget> filters;
  final VoidCallback onSearchChanged;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final filterWidth = filters.length * 172;
        final searchWidth = (constraints.maxWidth - filterWidth - 12)
            .clamp(360.0, 720.0)
            .toDouble();
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            SizedBox(
              width: searchWidth,
              child: TextField(
                controller: search,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.search),
                  labelText: searchLabel,
                ),
                onChanged: (_) => onSearchChanged(),
              ),
            ),
            ...filters,
          ],
        );
      },
    );
  }
}

class _LogFilterSelect extends StatelessWidget {
  const _LogFilterSelect({
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
  });

  final String label;
  final String value;
  final List<String> options;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 160,
      child: DropdownButtonFormField<String>(
        initialValue: value,
        decoration: InputDecoration(labelText: label),
        items: [
          const DropdownMenuItem(value: '', child: Text('All')),
          for (final option in options)
            DropdownMenuItem(value: option, child: Text(option)),
        ],
        onChanged: (next) => onChanged(next ?? ''),
      ),
    );
  }
}
