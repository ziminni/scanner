import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../models/models.dart';
import '../../shared/widgets/app_widgets.dart';
import '../../shared/widgets/admin.dart';
import '../../core/constants/enums.dart';
import 'viewmodels/school_admin_viewmodel.dart';

part 'widgets/attendance_role_tabs.dart';
part 'widgets/attendance_context_filter.dart';
part 'widgets/gate_pass_logs_page.dart';
part 'widgets/gate_pass_role_tabs.dart';
part 'widgets/log_filters.dart';
part 'widgets/log_filter_select.dart';

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
