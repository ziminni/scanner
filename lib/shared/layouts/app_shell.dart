// app_shell.dart - Refactored version

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/services/app_controller.dart';
import '../../core/constants/enums.dart';
import '../../models/models.dart';
import '../../routes/app_routes.dart';
import '../../core/constants/colors.dart';

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

    final isCompact = MediaQuery.sizeOf(context).width < 760;

    if (isCompact) {
      // Mobile layout with bottom nav
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
        body: child,
        bottomNavigationBar: NavigationBar(
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

    // Desktop layout: full-height sidebar + content area with integrated header
    return Scaffold(
      body: Row(
        children: [
          // Full-height sidebar
          if (user.role == UserRole.systemAdministrator ||
              user.role == UserRole.schoolAdministrator)
            _AdminSidebar(
              items: items,
              currentIndex: currentIndex,
              user: user,
              onSelected: (index) =>
                  context.go(AppRoutes.pathForPage(items[index].id)),
            )
          else
            _StandardSidebar(
              items: items,
              currentIndex: currentIndex,
              user: user,
              onSelected: (index) =>
                  context.go(AppRoutes.pathForPage(items[index].id)),
            ),

          // Content area with integrated header
          Expanded(
            child: Column(
              children: [
                // Integrated header (replaces AppBar)
                _ContentHeader(user: user, onLogout: app.logout),
                const Divider(height: 1, thickness: 1),
                Expanded(child: child),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<_NavItem> _itemsFor(UserRole role) {
    // ... (keep your existing implementation)
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
          'Completed School Years',
          'History',
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

// New: Content Header (replaces AppBar)
class _ContentHeader extends StatelessWidget {
  const _ContentHeader({required this.user, required this.onLogout});

  final AppUser user;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        border: const Border(bottom: BorderSide(color: Colors.black12)),
      ),
      child: Row(
        children: [
          // Page title could go here dynamically, or keep it simple
          Text(
            user.role.label,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
          ),
          const Spacer(),
          // User info
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.grey.withAlpha(26),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(radius: 16, child: Text(_initials(user.fullName))),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      user.fullName,
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                    Text(
                      user.email,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
                const SizedBox(width: 16),
                IconButton(
                  tooltip: 'Logout',
                  icon: const Icon(Icons.logout),
                  onPressed: onLogout,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Unified Admin Sidebar - Full height with better responsive widths for system & school admins
class _AdminSidebar extends StatelessWidget {
  const _AdminSidebar({
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
    // Better responsive width: min 240px, max 280px, or 16% of screen
    final sidebarWidth = (screenWidth * 0.16).clamp(240.0, 280.0);
    final horizontalPadding = sidebarWidth >= 260 ? 16.0 : 12.0;
    final verticalPadding = 20.0;

    return Container(
      width: sidebarWidth,
      decoration: BoxDecoration(
        color: AppColors.adminSidebar,
        border: const Border(right: BorderSide(color: AppColors.adminBorder)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(12),
            blurRadius: 12,
            offset: const Offset(2, 0),
          ),
        ],
      ),
      child: Column(
        children: [
          // Logo/Brand area at top (using school logo image)
          Container(
            height: 64,
            padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Colors.white10)),
            ),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    image: const DecorationImage(
                      image: AssetImage('assets/img/logo.jpg'),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'ATTENDANCE',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 11,
                          letterSpacing: 0.5,
                        ),
                      ),
                      Text(
                        'School Monitor',
                        style: TextStyle(
                          color: AppColors.mint.withAlpha(200),
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Navigation items
          Expanded(
            child: ListView.separated(
              padding: EdgeInsets.symmetric(vertical: verticalPadding),
              itemCount: items.length,
              separatorBuilder: (_, _) => const SizedBox(height: 4),
              itemBuilder: (context, index) {
                final item = items[index];
                final selected = index == currentIndex;
                return _AdminSidebarItem(
                  item: item,
                  selected: selected,
                  onTap: () => onSelected(index),
                  sidebarWidth: sidebarWidth,
                );
              },
            ),
          ),
          // User profile card at bottom (now properly at bottom)
          Container(
            padding: EdgeInsets.all(horizontalPadding),
            decoration: BoxDecoration(
              color: AppColors.adminSidebarActive.withAlpha(184),
              border: const Border(top: BorderSide(color: Colors.white10)),
            ),
            child: _UserProfileCard(user: user),
          ),
        ],
      ),
    );
  }
}

// Standard Sidebar for non-admin users (using NavigationRail but full-height)
class _StandardSidebar extends StatelessWidget {
  const _StandardSidebar({
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
    const expandedWidth = 240.0;
    final isExpanded = screenWidth > 1100;

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        border: const Border(right: BorderSide(color: Colors.black12)),
      ),
      child: NavigationRail(
        selectedIndex: currentIndex,
        labelType: isExpanded
            ? NavigationRailLabelType.none
            : NavigationRailLabelType.all,
        minWidth: 56,
        groupAlignment: -0.9,
        minExtendedWidth: expandedWidth,
        extended: isExpanded,
        leading: isExpanded ? const SizedBox(height: 64) : null,
        trailing: isExpanded
            ? Padding(
                padding: const EdgeInsets.all(12),
                child: _UserProfileCardCompact(user: user),
              )
            : Tooltip(
                message: user.fullName,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: CircleAvatar(
                    radius: 18,
                    child: Text(_initials(user.fullName)),
                  ),
                ),
              ),
        destinations: [
          for (final item in items)
            NavigationRailDestination(
              icon: Icon(item.icon),
              selectedIcon: Icon(item.selectedIcon),
              label: Text(item.label),
            ),
        ],
        onDestinationSelected: onSelected,
      ),
    );
  }
}

// Reusable user profile card for sidebar bottom
class _UserProfileCard extends StatelessWidget {
  const _UserProfileCard({required this.user});

  final AppUser user;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        CircleAvatar(
          radius: 20,
          backgroundColor: AppColors.adminAccent,
          child: Text(
            _initials(user.fullName),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
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
                style: const TextStyle(color: Colors.white70, fontSize: 11),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// Compact version for collapsed sidebar
class _UserProfileCardCompact extends StatelessWidget {
  const _UserProfileCardCompact({required this.user});

  final AppUser user;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CircleAvatar(
          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
          child: Text(_initials(user.fullName)),
        ),
        const SizedBox(height: 8),
        Text(
          user.role.label,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        Text(
          user.email,
          style: const TextStyle(fontSize: 10),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

// Refactored Sidebar Item with better text handling
class _AdminSidebarItem extends StatelessWidget {
  const _AdminSidebarItem({
    required this.item,
    required this.selected,
    required this.onTap,
    required this.sidebarWidth,
  });

  final _NavItem item;
  final bool selected;
  final VoidCallback onTap;
  final double sidebarWidth;

  @override
  Widget build(BuildContext context) {
    final textColor = selected ? Colors.white : Colors.white.withAlpha(216);
    final iconColor = selected ? Colors.white : Colors.white.withAlpha(179);
    // Dynamic font size based on available width
    final fontSize = sidebarWidth >= 260 ? 14.0 : 13.0;
    final iconSize = sidebarWidth >= 260 ? 24.0 : 22.0;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        hoverColor: AppColors.adminSidebarActive.withAlpha(184),
        child: Container(
          height: 52,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: selected ? AppColors.adminSidebarActive : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              // Left accent bar
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 4,
                height: 32,
                decoration: BoxDecoration(
                  color: selected ? AppColors.adminAccent : Colors.transparent,
                  borderRadius: const BorderRadius.horizontal(
                    right: Radius.circular(4),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Icon container
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: selected
                      ? AppColors.adminAccent
                      : AppColors.adminSidebarMuted.withAlpha(51),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  selected ? item.selectedIcon : item.icon,
                  color: iconColor,
                  size: iconSize,
                ),
              ),
              const SizedBox(width: 12),
              // Label - now with proper ellipsis and flex
              Expanded(
                child: Text(
                  item.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  softWrap: false,
                  style: TextStyle(
                    color: textColor,
                    fontSize: fontSize,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
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

// Helper function
String _initials(String fullName) {
  final parts = fullName.trim().split(RegExp(r'\s+'));
  if (parts.isEmpty || parts.first.isEmpty) return 'A';
  if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
  return '${parts.first.substring(0, 1)}${parts[1].substring(0, 1)}'
      .toUpperCase();
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

// Keep ActiveSchoolYearGate as is...
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
