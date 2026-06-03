import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/enums.dart';
import '../../core/services/app_controller.dart';
import '../../models/models.dart';
import '../../routes/app_routes.dart';
import '../../screens/scanner/scanner_theme.dart';

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
      backgroundColor: user.role == UserRole.staffScanner
          ? ScannerTheme.background
          : null,
      appBar: AppBar(
        titleSpacing: user.role == UserRole.staffScanner ? 12 : null,
        backgroundColor: user.role == UserRole.staffScanner
            ? ScannerTheme.surfaceSoft
            : null,
        foregroundColor: user.role == UserRole.staffScanner
            ? ScannerTheme.text
            : null,
        title: user.role == UserRole.staffScanner
            ? const _ScannerHeaderTitle()
            : Text(user.role.label),
        actions: user.role == UserRole.staffScanner
            ? [
                Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: Builder(
                    builder: (context) => IconButton(
                      tooltip: 'Menu',
                      icon: const Icon(Icons.menu),
                      onPressed: () => Scaffold.of(context).openEndDrawer(),
                    ),
                  ),
                ),
              ]
            : [
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
      endDrawer: user.role == UserRole.staffScanner
          ? _ScannerAccountDrawer(user: user)
          : null,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 760;
          final extended = constraints.maxWidth > 1100;
          if (compact) return child;
          return Row(
            children: [
              if (user.role == UserRole.staffScanner)
                ColoredBox(
                  color: ScannerTheme.surfaceSoft,
                  child: _ScannerNavigationRail(
                    items: items,
                    currentIndex: currentIndex,
                    extended: extended,
                  ),
                )
              else
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
              backgroundColor: user.role == UserRole.staffScanner
                  ? ScannerTheme.surfaceSoft
                  : null,
              indicatorColor: user.role == UserRole.staffScanner
                  ? ScannerTheme.primarySoft
                  : null,
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
          AppRoutes.scannerHome,
          'Home',
          'Home',
          Icons.home_outlined,
          Icons.home,
        ),
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

class _ScannerAccountDrawer extends StatelessWidget {
  const _ScannerAccountDrawer({required this.user});

  final AppUser user;

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    return Drawer(
      width: 280,
      backgroundColor: ScannerTheme.background,
      child: SafeArea(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: const BoxDecoration(color: ScannerTheme.surfaceSoft),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      ClipOval(
                        child: Image.asset(
                          'assets/images/school_logo.jpeg',
                          width: 52,
                          height: 52,
                          fit: BoxFit.cover,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Leon Garcia National Highschool',
                          style: TextStyle(
                            color: ScannerTheme.text,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Padding(
                    padding: EdgeInsets.only(left: 64),
                    child: Text(
                      'Scanner',
                      style: TextStyle(
                        color: ScannerTheme.primary,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            ListTile(
              leading: const Icon(Icons.person_outline),
              title: const Text('Profile'),
              onTap: () {
                Navigator.of(context).pop();
                showDialog<void>(
                  context: context,
                  builder: (_) => _ScannerProfileDialog(user: user),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings_outlined),
              title: const Text('Settings'),
              onTap: () {
                Navigator.of(context).pop();
                context.go(AppRoutes.scannerSettingsPath);
              },
            ),
            const Spacer(),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text('Logout'),
              onTap: () async {
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (_) => const _ScannerLogoutDialog(),
                );
                if (confirmed != true || !context.mounted) return;
                Navigator.of(context).pop();
                await app.logout();
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _ScannerProfileDialog extends StatelessWidget {
  const _ScannerProfileDialog({required this.user});

  final AppUser user;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Profile'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ProfileLine(label: 'Name', value: user.fullName),
          _ProfileLine(label: 'Email', value: user.email),
          _ProfileLine(label: 'Role', value: user.role.label),
          _ProfileLine(label: 'Status', value: user.status.label),
        ],
      ),
      actions: [
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: ScannerTheme.primary,
            foregroundColor: Colors.white,
          ),
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }
}

class _ProfileLine extends StatelessWidget {
  const _ProfileLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: ScannerTheme.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(value.isEmpty ? '-' : value),
        ],
      ),
    );
  }
}

class _ScannerLogoutDialog extends StatelessWidget {
  const _ScannerLogoutDialog();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Logout'),
      content: const Text('Are you sure you want to logout?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: ScannerTheme.primary,
            foregroundColor: Colors.white,
          ),
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('Logout'),
        ),
      ],
    );
  }
}

class _ScannerNavigationRail extends StatelessWidget {
  const _ScannerNavigationRail({
    required this.items,
    required this.currentIndex,
    required this.extended,
  });

  final List<_NavItem> items;
  final int currentIndex;
  final bool extended;

  @override
  Widget build(BuildContext context) {
    return NavigationRail(
      backgroundColor: ScannerTheme.surfaceSoft,
      selectedIndex: currentIndex,
      selectedIconTheme: const IconThemeData(color: ScannerTheme.primary),
      selectedLabelTextStyle: const TextStyle(color: ScannerTheme.primary),
      indicatorColor: ScannerTheme.primarySoft,
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
    );
  }
}

class _ScannerHeaderTitle extends StatefulWidget {
  const _ScannerHeaderTitle();

  @override
  State<_ScannerHeaderTitle> createState() => _ScannerHeaderTitleState();
}

class _ScannerHeaderTitleState extends State<_ScannerHeaderTitle> {
  final Connectivity _connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _subscription;
  bool _isOnline = false;

  @override
  void initState() {
    super.initState();
    _loadStatus();
    _subscription = _connectivity.onConnectivityChanged.listen(_setStatus);
  }

  Future<void> _loadStatus() async {
    _setStatus(await _connectivity.checkConnectivity());
  }

  void _setStatus(List<ConnectivityResult> result) {
    if (!mounted) return;
    setState(() {
      _isOnline = result.any((status) => status != ConnectivityResult.none);
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ClipOval(
          child: Image.asset(
            'assets/images/school_logo.jpeg',
            width: 36,
            height: 36,
            fit: BoxFit.cover,
          ),
        ),
        const SizedBox(width: 10),
        const Flexible(
          child: Text('Leon Garcia', overflow: TextOverflow.ellipsis),
        ),
        const SizedBox(width: 8),
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: _isOnline ? const Color(0xFF2E7D4F) : Colors.grey,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 1.5),
          ),
        ),
      ],
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
