part of '../attendance_logs_page.dart';

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
