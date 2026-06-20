part of '../attendance_logs_page.dart';

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
