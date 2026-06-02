import 'package:flutter/material.dart';

import '../../core/constants/colors.dart';
import '../../core/services/app_controller.dart';
import '../../core/theme/app_theme.dart';
import '../../features/admin/view/admin_pages.dart';
import '../../features/scanner/view/scanner_screen.dart';
import '../../models/enums.dart';
import '../../models/models.dart';

class AppShell extends StatelessWidget {
  const AppShell({super.key});

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final user = app.currentUser!;
    final screenWidth = MediaQuery.sizeOf(context).width;
    final items = _itemsFor(user.role);
    final currentIndex = items.isEmpty
      ? 0
      : items
        .indexWhere((item) => item.id == app.currentPage)
        .clamp(0, items.length - 1);
    final bottomItems = items.take(5).toList();
    final bottomIndex = bottomItems.isEmpty
      ? 0
      : bottomItems
        .indexWhere((item) => item.id == app.currentPage)
        .clamp(0, bottomItems.length - 1);
    final systemAdmin = user.role == UserRole.systemAdministrator;

    final shell = Scaffold(
      backgroundColor: systemAdmin ? AppColors.adminBackground : null,
      appBar: AppBar(
        titleSpacing: screenWidth >= 900 ? 20 : 12,
        title: screenWidth >= 900
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'ATTENDANCE',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppColors.adminText,
                        ),
                  ),
                  Text(
                    'School Monitoring System',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.adminText.withValues(alpha: 0.72),
                        ),
                  ),
                ],
              )
            : Text(
                'ATTENDANCE',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.adminText,
                    ),
              ),
        actions: [
          IconButton(
            tooltip: 'Notifications',
            icon: const Icon(Icons.notifications_none_outlined),
            onPressed: () {},
          ),
          if (screenWidth >= 1000) ...[
            const VerticalDivider(width: 1, indent: 16, endIndent: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    user.fullName,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  Text(
                    user.role.label,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.adminText.withValues(alpha: 0.72),
                        ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: CircleAvatar(
                radius: 16,
                backgroundColor: AppColors.adminAccent,
                child: Text(
                  _initials(user.fullName),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ] else ...[
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: CircleAvatar(
                radius: 15,
                backgroundColor: AppColors.adminAccent,
                child: Text(
                  _initials(user.fullName),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
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
          final content = _pageFor(context, app.currentPage);
          if (compact) return content;
          return Row(
            children: [
              if (systemAdmin)
                _SystemAdminSidebar(
                  items: items,
                  currentIndex: currentIndex,
                  user: user,
                  onSelected: (index) => app.go(items[index].id),
                )
              else ...[
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
                  onDestinationSelected: (index) => app.go(items[index].id),
                ),
                const VerticalDivider(width: 1),
              ],
              Expanded(child: content),
            ],
          );
        },
      ),
      bottomNavigationBar: MediaQuery.sizeOf(context).width >= 760
          ? null
          : NavigationBar(
              backgroundColor: systemAdmin ? AppColors.adminPrimary : null,
              indicatorColor: systemAdmin
                  ? AppColors.adminAccent.withValues(alpha: 0.18)
                  : null,
              selectedIndex: bottomIndex,
              onDestinationSelected: (index) => app.go(bottomItems[index].id),
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
    return systemAdmin
        ? Theme(data: AppTheme.systemAdmin(Theme.of(context)), child: shell)
        : shell;
  }

  Widget _pageFor(BuildContext context, String pageId) {
    final page = switch (pageId) {
      'dashboard' => const DashboardPage(),
      'users' => const UserManagementPage(),
      'audit' => const AuditLogsPage(),
      'settings' => const SystemSettingsPage(),
      'database' => const DatabaseManagementPage(),
      'archives' => const ArchiveManagementPage(),
      'scannerUsers' => const ScannerUsersPage(),
      'schoolYears' => const SchoolYearPage(),
      'students' => const StudentsPage(),
      'sections' => const SectionsPage(),
      'teachers' => const TeachersPage(),
      'logs' => const AttendanceLogsPage(),
      'attendanceStatus' => const AttendanceStatusPage(),
      'earlyStudents' => const EarlyStudentsPage(),
      'reports' => const ReportsExportPage(),
      'scanner' => const ScannerScreen(),
      _ => const DashboardPage(),
    };
    if (_requiresActiveSchoolYear(pageId)) {
      return _ActiveSchoolYearGate(child: page);
    }
    return page;
  }

  bool _requiresActiveSchoolYear(String pageId) {
    return const {
      'scannerUsers',
      'students',
      'sections',
      'teachers',
      'logs',
      'attendanceStatus',
      'earlyStudents',
      'reports',
      'scanner',
    }.contains(pageId);
  }

  List<_NavItem> _itemsFor(UserRole role) {
    return switch (role) {
      UserRole.systemAdministrator => const [
        _NavItem(
          'dashboard',
          'Dashboard',
          'Home',
          Icons.dashboard_outlined,
          Icons.dashboard,
        ),
        _NavItem(
          'users',
          'User Management',
          'Users',
          Icons.manage_accounts_outlined,
          Icons.manage_accounts,
        ),
        _NavItem(
          'audit',
          'Audit Logs',
          'Audit',
          Icons.fact_check_outlined,
          Icons.fact_check,
        ),
        _NavItem(
          'settings',
          'System Settings',
          'Settings',
          Icons.tune_outlined,
          Icons.tune,
        ),
        _NavItem(
          'database',
          'Database Management',
          'Data',
          Icons.storage_outlined,
          Icons.storage,
        ),
        _NavItem(
          'archives',
          'Archive Management',
          'Archives',
          Icons.archive_outlined,
          Icons.archive,
        ),
      ],
      UserRole.schoolAdministrator => const [
        _NavItem(
          'dashboard',
          'Dashboard',
          'Home',
          Icons.dashboard_outlined,
          Icons.dashboard,
        ),
        _NavItem(
          'scannerUsers',
          'Scanner Users',
          'Scanners',
          Icons.qr_code_scanner,
          Icons.qr_code_scanner,
        ),
        _NavItem(
          'schoolYears',
          'School Year',
          'Years',
          Icons.calendar_month_outlined,
          Icons.calendar_month,
        ),
        _NavItem(
          'students',
          'Students',
          'Students',
          Icons.school_outlined,
          Icons.school,
        ),
        _NavItem(
          'sections',
          'Sections',
          'Sections',
          Icons.groups_outlined,
          Icons.groups,
        ),
        _NavItem(
          'teachers',
          'Teachers',
          'Teachers',
          Icons.badge_outlined,
          Icons.badge,
        ),
        _NavItem(
          'logs',
          'Attendance Logs',
          'Logs',
          Icons.list_alt_outlined,
          Icons.list_alt,
        ),
        _NavItem(
          'attendanceStatus',
          'Attendance Status',
          'Status',
          Icons.warning_amber_outlined,
          Icons.warning,
        ),
        _NavItem(
          'earlyStudents',
          'Early Students',
          'Early',
          Icons.emoji_events_outlined,
          Icons.emoji_events,
        ),
        _NavItem(
          'reports',
          'Reports & Export',
          'Reports',
          Icons.file_download_outlined,
          Icons.file_download,
        ),
        _NavItem(
          'archives',
          'Archives',
          'Archives',
          Icons.archive_outlined,
          Icons.archive,
        ),
      ],
      UserRole.staffScanner => const [
        _NavItem(
          'scanner',
          'Scan IDs',
          'Scan',
          Icons.qr_code_scanner,
          Icons.qr_code_scanner,
        ),
        _NavItem(
          'logs',
          'Logs',
          'Logs',
          Icons.list_alt_outlined,
          Icons.list_alt,
        ),
      ],
    };
  }
}

class _SystemAdminSidebar extends StatelessWidget {
  const _SystemAdminSidebar({
    required this.items,
    required this.currentIndex,
    required this.user,
    required this.onSelected,
  });

  final List<_NavItem> items;
  final int currentIndex;
  final AppUser user;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final sidebarWidth = (screenWidth * 0.18).clamp(168.0, 260.0);
    final horizontalPadding = screenWidth >= 1400 ? 16.0 : 12.0;
    final verticalPadding = screenWidth >= 1400 ? 18.0 : 14.0;

    return Container(
      width: sidebarWidth.toDouble(),
      decoration: BoxDecoration(
        color: AppColors.adminSidebar,
        border: const Border(right: BorderSide(color: AppColors.adminBorder)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ListView.separated(
        padding: EdgeInsets.fromLTRB(
          horizontalPadding,
          verticalPadding,
          horizontalPadding,
          verticalPadding,
        ),
        itemCount: items.length + 1,
        separatorBuilder: (_, i) => const SizedBox(height: 6),
        itemBuilder: (context, index) {
          if (index == items.length) {
            return Container(
              margin: const EdgeInsets.only(top: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.adminSidebarActive.withValues(alpha: 0.72),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: AppColors.adminAccent,
                    child: Text(
                      _initials(user.fullName),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user.role.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                        Text(
                          user.email,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }
          final item = items[index];
          final selected = index == currentIndex;
          return _SystemAdminSidebarItem(
            item: item,
            selected: selected,
            onTap: () => onSelected(index),
          );
        },
      ),
    );
  }
}

String _initials(String fullName) {
  final parts = fullName.trim().split(RegExp(r'\s+'));
  if (parts.isEmpty || parts.first.isEmpty) return 'A';
  if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
  return '${parts.first.substring(0, 1)}${parts[1].substring(0, 1)}'.toUpperCase();
}

class _SystemAdminSidebarItem extends StatelessWidget {
  const _SystemAdminSidebarItem({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  final _NavItem item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textColor = selected
      ? Colors.white
      : Colors.white.withValues(alpha: 0.84);
    final iconColor = selected
      ? Colors.white
      : Colors.white.withValues(alpha: 0.70);
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isCompact = screenWidth < 900;
    final itemHeight = isCompact ? 52.0 : 64.0;
    final fontSize = isCompact ? 13.0 : 14.0;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        hoverColor: AppColors.adminSidebarActive.withValues(alpha: 0.72),
        child: Container(
          height: itemHeight,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: selected ? AppColors.adminSidebarActive : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 6,
                height: itemHeight - 18,
                decoration: BoxDecoration(
                  color: selected ? AppColors.adminAccent : Colors.transparent,
                  borderRadius: const BorderRadius.horizontal(right: Radius.circular(6)),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: selected ? AppColors.adminAccent : AppColors.adminSidebarMuted.withValues(alpha: 0.20),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(selected ? item.selectedIcon : item.icon, color: iconColor),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Tooltip(
                  message: item.label,
                  child: Text(
                    item.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: textColor,
                      fontSize: fontSize,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActiveSchoolYearGate extends StatelessWidget {
  const _ActiveSchoolYearGate({required this.child});

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
                      onPressed: () => app.go('schoolYears'),
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
