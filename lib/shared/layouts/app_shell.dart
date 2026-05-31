import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/services/app_controller.dart';
import '../../core/constants/enums.dart';
import '../../routes/app_routes.dart';

class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.currentPage, required this.child});

  final String currentPage;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final user = app.currentUser!;
    final items = _itemsFor(user.role);
    final currentIndex = items
        .indexWhere((item) => item.id == currentPage)
        .clamp(0, items.length - 1);
    final bottomItems = items.take(5).toList();
    final bottomIndex = bottomItems
        .indexWhere((item) => item.id == currentPage)
        .clamp(0, bottomItems.length - 1);

    return Scaffold(
      appBar: AppBar(
        title: Text(user.role.label),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Center(child: Text(user.fullName)),
          ),
          IconButton(
            tooltip: 'Logout',
            icon: const Icon(Icons.logout),
            onPressed: app.logout,
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 760;
          final extended = constraints.maxWidth > 1100;
          if (compact) return child;
          return Row(
            children: [
              NavigationRail(
                selectedIndex: currentIndex,
                labelType: extended
                    ? NavigationRailLabelType.none
                    : NavigationRailLabelType.all,
                minExtendedWidth: 220,
                extended: extended,
                destinations: [
                  for (final item in items)
                    NavigationRailDestination(
                      icon: Icon(item.icon),
                      selectedIcon: Icon(item.selectedIcon),
                      label: Text(item.label),
                    ),
                ],
                onDestinationSelected: (index) =>
                    context.go(AppRoutes.pathForPage(items[index].id)),
              ),
              const VerticalDivider(width: 1),
              Expanded(child: child),
            ],
          );
        },
      ),
      bottomNavigationBar: MediaQuery.sizeOf(context).width >= 760
          ? null
          : NavigationBar(
              selectedIndex: bottomIndex,
              onDestinationSelected: (index) =>
                  context.go(AppRoutes.pathForPage(bottomItems[index].id)),
              destinations: [
                for (final item in bottomItems)
                  NavigationDestination(
                    icon: Icon(item.icon),
                    selectedIcon: Icon(item.selectedIcon),
                    label: item.shortLabel,
                  ),
              ],
            ),
    );
  }

  List<_NavItem> _itemsFor(UserRole role) {
    return switch (role) {
      UserRole.systemAdministrator => const [
        _NavItem(
          AppRoutes.dashboard,
          'Dashboard',
          'Home',
          Icons.dashboard_outlined,
          Icons.dashboard,
        ),
        _NavItem(
          AppRoutes.users,
          'User Management',
          'Users',
          Icons.manage_accounts_outlined,
          Icons.manage_accounts,
        ),
        _NavItem(
          AppRoutes.audit,
          'Audit Logs',
          'Audit',
          Icons.fact_check_outlined,
          Icons.fact_check,
        ),
        _NavItem(
          AppRoutes.settings,
          'System Settings',
          'Settings',
          Icons.tune_outlined,
          Icons.tune,
        ),
        _NavItem(
          AppRoutes.database,
          'Database Management',
          'Data',
          Icons.storage_outlined,
          Icons.storage,
        ),
        _NavItem(
          AppRoutes.archives,
          'Archive Management',
          'Archives',
          Icons.archive_outlined,
          Icons.archive,
        ),
      ],
      UserRole.schoolAdministrator => const [
        _NavItem(
          AppRoutes.dashboard,
          'Dashboard',
          'Home',
          Icons.dashboard_outlined,
          Icons.dashboard,
        ),
        _NavItem(
          AppRoutes.scannerUsers,
          'Scanner Users',
          'Scanners',
          Icons.qr_code_scanner,
          Icons.qr_code_scanner,
        ),
        _NavItem(
          AppRoutes.schoolYears,
          'School Year',
          'Years',
          Icons.calendar_month_outlined,
          Icons.calendar_month,
        ),
        _NavItem(
          AppRoutes.students,
          'Students',
          'Students',
          Icons.school_outlined,
          Icons.school,
        ),
        _NavItem(
          AppRoutes.sections,
          'Sections',
          'Sections',
          Icons.groups_outlined,
          Icons.groups,
        ),
        _NavItem(
          AppRoutes.teachers,
          'Teachers',
          'Teachers',
          Icons.badge_outlined,
          Icons.badge,
        ),
        _NavItem(
          AppRoutes.logs,
          'Attendance Logs',
          'Logs',
          Icons.list_alt_outlined,
          Icons.list_alt,
        ),
        _NavItem(
          AppRoutes.attendanceStatus,
          'Attendance Status',
          'Status',
          Icons.warning_amber_outlined,
          Icons.warning,
        ),
        _NavItem(
          AppRoutes.earlyStudents,
          'Early Students',
          'Early',
          Icons.emoji_events_outlined,
          Icons.emoji_events,
        ),
        _NavItem(
          AppRoutes.reports,
          'Reports & Export',
          'Reports',
          Icons.file_download_outlined,
          Icons.file_download,
        ),
        _NavItem(
          AppRoutes.archives,
          'Archives',
          'Archives',
          Icons.archive_outlined,
          Icons.archive,
        ),
      ],
      UserRole.staffScanner => const [
        _NavItem(
          AppRoutes.scanner,
          'Scan IDs',
          'Scan',
          Icons.qr_code_scanner,
          Icons.qr_code_scanner,
        ),
        _NavItem(
          AppRoutes.logs,
          'Logs',
          'Logs',
          Icons.list_alt_outlined,
          Icons.list_alt,
        ),
      ],
    };
  }
}

class ActiveSchoolYearGate extends StatelessWidget {
  const ActiveSchoolYearGate({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    return FutureBuilder(
      future: app.attendance.activeSchoolYear(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.data == null) {
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.calendar_month_outlined,
                      size: 48,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Create a school year first',
                      style: Theme.of(context).textTheme.headlineSmall,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'In order to access this page, create and activate a school year first.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    FilledButton.icon(
                      icon: const Icon(Icons.add),
                      label: const Text('Go to School Year'),
                      onPressed: () => context.go(
                        AppRoutes.pathForPage(AppRoutes.schoolYears),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }
        return child;
      },
    );
  }
}

class _NavItem {
  const _NavItem(
    this.id,
    this.label,
    this.shortLabel,
    this.icon,
    this.selectedIcon,
  );

  final String id;
  final String label;
  final String shortLabel;
  final IconData icon;
  final IconData selectedIcon;
}
