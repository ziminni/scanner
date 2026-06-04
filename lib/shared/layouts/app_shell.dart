import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/colors.dart';
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

    if (user.role == UserRole.staffScanner) {
      return _ScannerShell(
        user: user,
        items: items,
        currentIndex: currentIndex,
        bottomItems: bottomItems,
        bottomIndex: bottomIndex,
        child: child,
      );
    }

    final isCompact = MediaQuery.sizeOf(context).width < 760;
    if (isCompact) {
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
              onPressed: () => _confirmAndLogout(context),
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

    return _AdminDesktopShell(
      user: user,
      items: items,
      currentIndex: currentIndex,
      onLogout: app.logout,
      child: child,
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
          'Archives',
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
          AppRoutes.schoolYears,
          'School Year',
          'Years',
          Icons.calendar_month_outlined,
          Icons.calendar_month,
        ),
        _NavItem(
          AppRoutes.sections,
          'Sections',
          'Sections',
          Icons.groups_outlined,
          Icons.groups,
        ),
        _NavItem(
          AppRoutes.students,
          'Students',
          'Students',
          Icons.school_outlined,
          Icons.school,
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
          'Reports and Exports',
          'Reports',
          Icons.file_download_outlined,
          Icons.file_download,
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

class _AdminDesktopShell extends StatefulWidget {
  const _AdminDesktopShell({
    required this.user,
    required this.items,
    required this.currentIndex,
    required this.onLogout,
    required this.child,
  });

  final AppUser user;
  final List<_NavItem> items;
  final int currentIndex;
  final VoidCallback onLogout;
  final Widget child;

  @override
  State<_AdminDesktopShell> createState() => _AdminDesktopShellState();
}

class _AdminDesktopShellState extends State<_AdminDesktopShell> {
  bool _sidebarCollapsed = false;
  bool _sidebarContentCollapsed = false;
  Timer? _sidebarContentTimer;

  @override
  void dispose() {
    _sidebarContentTimer?.cancel();
    super.dispose();
  }

  void _toggleSidebar() {
    _sidebarContentTimer?.cancel();
    if (_sidebarCollapsed) {
      setState(() => _sidebarCollapsed = false);
      _sidebarContentTimer = Timer(const Duration(milliseconds: 170), () {
        if (!mounted) return;
        setState(() => _sidebarContentCollapsed = false);
      });
      return;
    }
    setState(() {
      _sidebarContentCollapsed = true;
      _sidebarCollapsed = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          _AdminSidebar(
            items: widget.items,
            currentIndex: widget.currentIndex,
            collapsed: _sidebarCollapsed,
            contentCollapsed: _sidebarContentCollapsed,
            onSelected: (index) =>
                context.go(AppRoutes.pathForPage(widget.items[index].id)),
          ),
          Expanded(
            child: Column(
              children: [
                _ContentHeader(
                  user: widget.user,
                  sidebarCollapsed: _sidebarCollapsed,
                  onToggleSidebar: _toggleSidebar,
                  onLogout: widget.onLogout,
                ),
                const Divider(height: 1, thickness: 1),
                Expanded(child: widget.child),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ContentHeader extends StatelessWidget {
  const _ContentHeader({
    required this.user,
    required this.sidebarCollapsed,
    required this.onToggleSidebar,
    required this.onLogout,
  });

  final AppUser user;
  final bool sidebarCollapsed;
  final VoidCallback onToggleSidebar;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64,
      padding: const EdgeInsets.fromLTRB(24, 0, 16, 0),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        border: const Border(bottom: BorderSide(color: Colors.black12)),
      ),
      child: Row(
        children: [
          _HeaderSidebarToggleButton(
            collapsed: sidebarCollapsed,
            onPressed: onToggleSidebar,
          ),
          const SizedBox(width: 12),
          Text(
            user.role.label,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
          ),
          const Spacer(),
          _HeaderAccountMenu(user: user, onLogout: onLogout),
        ],
      ),
    );
  }
}

class _HeaderAccountMenu extends StatelessWidget {
  const _HeaderAccountMenu({required this.user, required this.onLogout});

  final AppUser user;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return PopupMenuButton<_HeaderAccountAction>(
      tooltip: 'Account menu',
      position: PopupMenuPosition.under,
      offset: const Offset(0, 8),
      onSelected: (action) {
        switch (action) {
          case _HeaderAccountAction.profile:
            showDialog<void>(
              context: context,
              builder: (_) => _EditableProfileDialog(user: user),
            );
          case _HeaderAccountAction.logout:
            _confirmAndLogout(context);
        }
      },
      itemBuilder: (context) => const [
        PopupMenuItem(
          value: _HeaderAccountAction.profile,
          child: ListTile(
            leading: Icon(Icons.person_outline),
            title: Text('Profile'),
            contentPadding: EdgeInsets.zero,
          ),
        ),
        PopupMenuDivider(),
        PopupMenuItem(
          value: _HeaderAccountAction.logout,
          child: ListTile(
            leading: Icon(Icons.logout),
            title: Text('Logout'),
            contentPadding: EdgeInsets.zero,
          ),
        ),
      ],
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: theme.colorScheme.primary.withAlpha(28)),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(8),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: theme.colorScheme.primary.withAlpha(38),
              child: Text(
                _initials(user.fullName),
                style: TextStyle(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(width: 12),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 220),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    user.fullName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  Text(
                    user.email,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.keyboard_arrow_down, color: theme.colorScheme.primary),
          ],
        ),
      ),
    );
  }
}

enum _HeaderAccountAction { profile, logout }

class _EditableProfileDialog extends StatefulWidget {
  const _EditableProfileDialog({required this.user, this.scannerStyle = false});

  final AppUser user;
  final bool scannerStyle;

  @override
  State<_EditableProfileDialog> createState() => _EditableProfileDialogState();
}

class _EditableProfileDialogState extends State<_EditableProfileDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _email;
  bool _sendPasswordReset = false;
  bool _busy = false;
  String? _message;
  String? _error;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.user.fullName);
    _email = TextEditingController(text: widget.user.email);
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final primary = widget.scannerStyle
        ? ScannerTheme.primary
        : Theme.of(context).colorScheme.primary;

    return AlertDialog(
      title: const Text('Profile'),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _name,
                  decoration: const InputDecoration(
                    labelText: 'Name',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  textInputAction: TextInputAction.next,
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Name is required.'
                      : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _email,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    prefixIcon: Icon(Icons.mail_outline),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.done,
                  validator: (value) =>
                      value == null || !value.trim().contains('@')
                      ? 'Enter a valid email.'
                      : null,
                ),
                const SizedBox(height: 12),
                CheckboxListTile(
                  value: _sendPasswordReset,
                  onChanged: _busy
                      ? null
                      : (value) {
                          setState(() => _sendPasswordReset = value ?? false);
                        },
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                  title: const Text('Send password reset email'),
                  subtitle: Text(
                    'Firebase will email password reset instructions to ${widget.user.email}.',
                  ),
                ),
                const SizedBox(height: 12),
                _ProfileDetailLine(
                  label: 'Role',
                  value: widget.user.role.label,
                  color: primary,
                ),
                _ProfileDetailLine(
                  label: 'Status',
                  value: widget.user.status.label,
                  color: primary,
                ),
                if (_message != null) ...[
                  const SizedBox(height: 8),
                  Text(_message!, style: TextStyle(color: primary)),
                ],
                if (_error != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    _error!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _busy ? null : () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
        FilledButton.icon(
          style: widget.scannerStyle
              ? FilledButton.styleFrom(
                  backgroundColor: ScannerTheme.primary,
                  foregroundColor: Colors.white,
                )
              : null,
          icon: _busy
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Icon(Icons.save_outlined),
          label: Text(_busy ? 'Saving' : 'Save changes'),
          onPressed: _busy ? null : _save,
        ),
      ],
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _message = null;
      _error = null;
    });
    try {
      final passwordResetRequested = _sendPasswordReset;
      await AppScope.of(context).updateProfile(
        fullName: _name.text,
        email: _email.text,
        sendPasswordReset: passwordResetRequested,
      );
      if (!mounted) return;
      final emailChanged =
          _email.text.trim().toLowerCase() !=
          widget.user.email.trim().toLowerCase();
      setState(() {
        _sendPasswordReset = false;
        _message = [
          'Profile saved.',
          if (emailChanged)
            'A verification email was sent before the email changes.',
          if (passwordResetRequested) 'A password reset email was sent.',
        ].join(' ');
      });
    } on FirebaseAuthException catch (error) {
      if (!mounted) return;
      setState(() => _error = _friendlyAuthError(error));
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = _cleanError(error.toString()));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String _friendlyAuthError(FirebaseAuthException error) {
    return switch (error.code) {
      'requires-recent-login' =>
        'For security, please log out and log in again before changing your email.',
      'invalid-email' => 'Please enter a valid email address.',
      'email-already-in-use' =>
        'That email is already used by another account.',
      'network-request-failed' =>
        'Network connection failed. Please try again when you are online.',
      _ => _cleanError(error.message ?? error.toString()),
    };
  }
}

class _ProfileDetailLine extends StatelessWidget {
  const _ProfileDetailLine({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(color: color, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 2),
          Text(value.isEmpty ? '-' : value),
        ],
      ),
    );
  }
}

String _cleanError(String message) {
  return message
      .replaceFirst('Bad state: ', '')
      .replaceFirst('Exception: ', '')
      .replaceFirst(RegExp(r'^\[firebase_auth/[^]]+\]\s*'), '')
      .trim();
}

class _AdminSidebar extends StatelessWidget {
  const _AdminSidebar({
    required this.items,
    required this.currentIndex,
    required this.collapsed,
    required this.contentCollapsed,
    required this.onSelected,
  });

  final List<_NavItem> items;
  final int currentIndex;
  final bool collapsed;
  final bool contentCollapsed;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final expandedWidth = (screenWidth * 0.17).clamp(280.0, 320.0);
    final sidebarWidth = collapsed ? 92.0 : expandedWidth;
    final horizontalPadding = sidebarWidth >= 320 ? 22.0 : 18.0;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      width: sidebarWidth,
      clipBehavior: Clip.hardEdge,
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
          Container(
            height: 88,
            padding: EdgeInsets.symmetric(
              horizontal: contentCollapsed ? 10 : horizontalPadding,
            ),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Colors.white10)),
            ),
            child: contentCollapsed
                ? const Center(child: _SidebarLogo(size: 46))
                : Row(
                    children: [
                      const _SidebarLogo(size: 54),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              'LEON GARCIA',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                fontSize: 15,
                              ),
                            ),
                            Text(
                              'School Monitor',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: AppColors.mint.withAlpha(200),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
          ),
          Expanded(
            child: ListView.separated(
              padding: EdgeInsets.fromLTRB(
                contentCollapsed ? 12 : horizontalPadding * 0.72,
                22,
                contentCollapsed ? 12 : horizontalPadding * 0.72,
                22,
              ),
              itemCount: items.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final item = items[index];
                final selected = index == currentIndex;
                return _AdminSidebarItem(
                  item: item,
                  selected: selected,
                  collapsed: contentCollapsed,
                  onTap: () => onSelected(index),
                  sidebarWidth: sidebarWidth,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _SidebarLogo extends StatelessWidget {
  const _SidebarLogo({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(size >= 50 ? 12 : 10),
        image: const DecorationImage(
          image: AssetImage('assets/img/logo.jpg'),
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}

class _HeaderSidebarToggleButton extends StatelessWidget {
  const _HeaderSidebarToggleButton({
    required this.collapsed,
    required this.onPressed,
  });

  final bool collapsed;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Tooltip(
      message: collapsed ? 'Open sidebar' : 'Close sidebar',
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(collapsed ? Icons.menu_open : Icons.menu, size: 22),
        style: IconButton.styleFrom(
          foregroundColor: theme.colorScheme.primary,
          backgroundColor: theme.colorScheme.primary.withAlpha(18),
          hoverColor: theme.colorScheme.primary.withAlpha(30),
          fixedSize: const Size(40, 40),
        ),
      ),
    );
  }
}

class _AdminSidebarItem extends StatelessWidget {
  const _AdminSidebarItem({
    required this.item,
    required this.selected,
    required this.collapsed,
    required this.onTap,
    required this.sidebarWidth,
  });

  final _NavItem item;
  final bool selected;
  final bool collapsed;
  final VoidCallback onTap;
  final double sidebarWidth;

  @override
  Widget build(BuildContext context) {
    final textColor = selected ? Colors.white : Colors.white.withAlpha(216);
    final iconColor = selected ? Colors.white : Colors.white.withAlpha(179);
    final fontSize = sidebarWidth >= 320 ? 15.0 : 14.0;
    final iconSize = sidebarWidth >= 320 ? 24.0 : 22.0;

    final button = Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        hoverColor: AppColors.adminSidebarActive.withAlpha(184),
        child: Container(
          height: collapsed ? 56 : 58,
          padding: EdgeInsets.symmetric(horizontal: collapsed ? 0 : 14),
          decoration: BoxDecoration(
            color: selected ? AppColors.adminSidebarActive : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: collapsed
                ? MainAxisAlignment.center
                : MainAxisAlignment.start,
            children: [
              Container(
                width: collapsed ? 46 : 44,
                height: collapsed ? 46 : 44,
                decoration: BoxDecoration(
                  color: selected
                      ? AppColors.adminAccent
                      : AppColors.adminSidebarMuted.withAlpha(51),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  selected ? item.selectedIcon : item.icon,
                  color: iconColor,
                  size: iconSize,
                ),
              ),
              if (!collapsed) ...[
                const SizedBox(width: 14),
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
            ],
          ),
        ),
      ),
    );

    return collapsed ? Tooltip(message: item.label, child: button) : button;
  }
}

class _ScannerShell extends StatelessWidget {
  const _ScannerShell({
    required this.user,
    required this.items,
    required this.currentIndex,
    required this.bottomItems,
    required this.bottomIndex,
    required this.child,
  });

  final AppUser user;
  final List<_NavItem> items;
  final int currentIndex;
  final List<_NavItem> bottomItems;
  final int bottomIndex;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ScannerTheme.background,
      appBar: AppBar(
        titleSpacing: 12,
        backgroundColor: ScannerTheme.surfaceSoft,
        foregroundColor: ScannerTheme.text,
        title: const _ScannerHeaderTitle(),
        actions: [
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
        ],
      ),
      endDrawer: _ScannerAccountDrawer(user: user),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 760;
          final extended = constraints.maxWidth > 1100;
          if (compact) return child;
          return Row(
            children: [
              ColoredBox(
                color: ScannerTheme.surfaceSoft,
                child: _ScannerNavigationRail(
                  items: items,
                  currentIndex: currentIndex,
                  extended: extended,
                ),
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
              backgroundColor: ScannerTheme.surfaceSoft,
              indicatorColor: ScannerTheme.primarySoft,
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
                  builder: (_) =>
                      _EditableProfileDialog(user: user, scannerStyle: true),
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

Future<void> _confirmAndLogout(BuildContext context) async {
  final app = AppScope.of(context);
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (_) => const _LogoutConfirmationDialog(),
  );
  if (confirmed != true || !context.mounted) return;
  await app.logout();
}

class _LogoutConfirmationDialog extends StatelessWidget {
  const _LogoutConfirmationDialog();

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
