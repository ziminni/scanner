import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/constants/enums.dart';
import '../../core/services/app_controller.dart';
import '../../models/models.dart';
import '../../routes/app_routes.dart';
import '../../shared/widgets/admin_widgets.dart';
import '../../shared/widgets/app_widgets.dart';
import 'audit_logs_page.dart';
import '../schooladmin/attendance_logs_page.dart';

class SystemAdminDashboardPage extends StatelessWidget {
  const SystemAdminDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final user = app.currentUser!;
    final systemAdmin = user.role == UserRole.systemAdministrator;

    if (!systemAdmin) {
      return const _SchoolAdminFallbackDashboard();
    }

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          'Comprehensive Dashboard',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'System health, activity, quick actions, and recent events',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 20),
        const _ActiveSchoolYearBanner(),
        const SizedBox(height: 20),
        _SectionTitle(
          icon: Icons.monitor_heart_outlined,
          title: 'System Health',
        ),
        const SizedBox(height: 12),
        _SystemHealthSection(app: app),
        const SizedBox(height: 20),
        _ActivitySection(app: app),
        const SizedBox(height: 20),
        _TwoColumnSection(
          left: _QuickActionsSection(app: app),
          right: const _RecentActivitiesSection(),
        ),
      ],
    );
  }
}

class _SchoolAdminFallbackDashboard extends StatelessWidget {
  const _SchoolAdminFallbackDashboard();

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Dashboard', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 16),
        GridView(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 280,
            mainAxisExtent: 104,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          children: [
            FirestoreCount(
              query: app.repository.activeCollectionGroupQuery('students'),
              builder: (value) => MetricCard(
                label: 'Total students',
                value: value,
                icon: Icons.school_outlined,
              ),
            ),
            FirestoreCount(
              query: app.repository.activeCollectionGroupQuery('teachers'),
              builder: (value) => MetricCard(
                label: 'Total teachers',
                value: value,
                icon: Icons.badge_outlined,
              ),
            ),
            FirestoreCount(
              query: app.repository.activeStaffScannerUsersQuery(),
              builder: (value) => MetricCard(
                label: 'Active scanner users',
                value: value,
                icon: Icons.qr_code_scanner,
              ),
            ),
            FirestoreCount(
              query: app.repository.attendanceStatusCollectionGroupQuery(
                AttendanceStatus.late.name,
              ),
              builder: (value) => MetricCard(
                label: 'Late count',
                value: value,
                icon: Icons.schedule_outlined,
              ),
            ),
            FirestoreCount(
              query: app.repository.attendanceStatusCollectionGroupQuery(
                AttendanceStatus.absent.name,
              ),
              builder: (value) => MetricCard(
                label: 'Absent count',
                value: value,
                icon: Icons.person_off_outlined,
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Text(
          'Recent attendance logs',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 8),
        const AttendanceLogsTable(limit: 10),
      ],
    );
  }
}

class _ActiveSchoolYearBanner extends StatelessWidget {
  const _ActiveSchoolYearBanner();

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final theme = Theme.of(context);
    return FutureBuilder<SchoolYear?>(
      future: app.attendance.activeSchoolYear(),
      builder: (context, snapshot) {
        final schoolYear = snapshot.data;
        final title = schoolYear?.name ?? 'No active school year';
        final subtitle = schoolYear == null
            ? 'Create a school year to begin collecting attendance data'
            : _schoolYearRange(schoolYear);

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: const Color(0xFF047857),
            borderRadius: BorderRadius.circular(16),
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
                      title,
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
              _BannerStatusPill(
                label: schoolYear == null ? 'Inactive' : 'Active',
                active: schoolYear != null,
              ),
            ],
          ),
        );
      },
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

class _BannerStatusPill extends StatelessWidget {
  const _BannerStatusPill({required this.label, required this.active});

  final String label;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: active ? const Color(0xFF047857) : Colors.grey.shade800,
          fontWeight: FontWeight.w800,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _SystemHealthSection extends StatelessWidget {
  const _SystemHealthSection({required this.app});

  final AppController app;

  @override
  Widget build(BuildContext context) {
    return _DashboardCardGrid(
      children: [
        _CountDashboardCard(
          title: 'Database Size',
          subtitle: 'Tracked records',
          icon: Icons.storage_outlined,
          iconColor: Colors.purple,
          future: _totalRecordCount(app),
          formatter: (value) => value.toString(),
        ),
        _CountDashboardCard(
          title: 'Storage Usage',
          subtitle: 'Backup storage',
          icon: Icons.inventory_2_outlined,
          iconColor: Colors.orange,
          future: app.admin.storageUsageBytes(),
          formatter: _formatBytes,
        ),
        _CountDashboardCard(
          title: 'Audit Events',
          subtitle: 'System activity log',
          icon: Icons.fact_check_outlined,
          iconColor: Colors.blue,
          query: app.repository.rootCollection('audit_logs'),
        ),
        _CountDashboardCard(
          title: 'Backups',
          subtitle: 'Database snapshots',
          icon: Icons.backup_outlined,
          iconColor: Colors.green,
          query: app.repository.rootCollection('backups'),
        ),
      ],
    );
  }

  Future<int> _totalRecordCount(AppController app) async {
    final snapshots = await Future.wait([
      app.repository.rootCollection('users').count().get(),
      app.repository.rootCollection('school_years').count().get(),
      app.repository.rootCollection('sections').count().get(),
      app.repository.collectionGroup('students').count().get(),
      app.repository.collectionGroup('teachers').count().get(),
      app.repository.collectionGroup('attendance_logs').count().get(),
    ]);
    return snapshots.fold<int>(
      0,
      (total, snapshot) => total + (snapshot.count ?? 0),
    );
  }
}

class _ActivitySection extends StatelessWidget {
  const _ActivitySection({required this.app});

  final AppController app;

  @override
  Widget build(BuildContext context) {
    return DataSurface(
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          _CompactActivityLabel(),
          _ActivityChip(
            label: 'Students',
            icon: Icons.school_outlined,
            color: Colors.green,
            query: app.repository.activeCollectionGroupQuery('students'),
          ),
          _ActivityChip(
            label: 'Teachers',
            icon: Icons.badge_outlined,
            color: Colors.teal,
            query: app.repository.activeCollectionGroupQuery('teachers'),
          ),
          _ActivityChip(
            label: 'Attendance',
            icon: Icons.list_alt_outlined,
            color: Colors.indigo,
            query: app.repository.collectionGroup('attendance_logs'),
          ),
          _ActivityChip(
            label: 'Late',
            icon: Icons.schedule_outlined,
            color: Colors.orange,
            query: app.repository.attendanceStatusCollectionGroupQuery(
              AttendanceStatus.late.name,
            ),
          ),
        ],
      ),
    );
  }
}

class _CompactActivityLabel extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(right: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.timeline_outlined,
            size: 18,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(width: 6),
          Text(
            'Activity',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActivityChip extends StatelessWidget {
  const _ActivityChip({
    required this.label,
    required this.icon,
    required this.color,
    required this.query,
  });

  final String label;
  final IconData icon;
  final Color color;
  final Query<Map<String, dynamic>> query;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return FutureBuilder<AggregateQuerySnapshot>(
      future: query.count().get(),
      builder: (context, snapshot) {
        final value = (snapshot.data?.count ?? 0).toString();
        return Container(
          height: 42,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: color.withAlpha(20),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color.withAlpha(70)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 17, color: color),
              const SizedBox(width: 8),
              Text(
                value,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _QuickActionsSection extends StatelessWidget {
  const _QuickActionsSection({required this.app});

  final AppController app;

  @override
  Widget build(BuildContext context) {
    return _DashboardPanel(
      title: 'Quick Actions',
      icon: Icons.flash_on_outlined,
      child: Column(
        children: [
          _QuickActionButton(
            icon: Icons.person_add_alt,
            label: 'Manage users',
            onPressed: () => context.go(AppRoutes.usersPath),
          ),
          _QuickActionButton(
            icon: Icons.backup_outlined,
            label: 'Backup database',
            onPressed: () async {
              await app.admin.backupDatabase(app.currentUser!);
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Database backup created.')),
              );
            },
          ),
          _QuickActionButton(
            icon: Icons.storage_outlined,
            label: 'Database management',
            onPressed: () => context.go(AppRoutes.databasePath),
          ),
          _QuickActionButton(
            icon: Icons.history_outlined,
            label: 'School year history',
            onPressed: () => context.go(AppRoutes.archivesPath),
          ),
          _QuickActionButton(
            icon: Icons.tune_outlined,
            label: 'System settings',
            onPressed: () => context.go(AppRoutes.settingsPath),
          ),
        ],
      ),
    );
  }
}

class _RecentActivitiesSection extends StatelessWidget {
  const _RecentActivitiesSection();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.history_outlined,
              size: 20,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(width: 8),
            Text(
              'Recent Activities',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        const AuditLogsList(limit: 8),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.icon, required this.title});

  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, size: 20, color: theme.colorScheme.primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _TwoColumnSection extends StatelessWidget {
  const _TwoColumnSection({required this.left, required this.right});

  final Widget left;
  final Widget right;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 900) {
          return Column(
            children: [
              left,
              const SizedBox(height: 20),
              right,
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: left),
            const SizedBox(width: 20),
            Expanded(child: right),
          ],
        );
      },
    );
  }
}

class _DashboardCardGrid extends StatelessWidget {
  const _DashboardCardGrid({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return GridView.extent(
      maxCrossAxisExtent: 300,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 2.15,
      crossAxisSpacing: 14,
      mainAxisSpacing: 14,
      children: children,
    );
  }
}

class _DashboardPanel extends StatelessWidget {
  const _DashboardPanel({
    required this.title,
    required this.icon,
    required this.child,
  });

  final String title;
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DataSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _CountDashboardCard extends StatelessWidget {
  const _CountDashboardCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.iconColor,
    this.query,
    this.future,
    this.formatter,
    this.compact = false,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color iconColor;
  final Query<Map<String, dynamic>>? query;
  final Future<int>? future;
  final String Function(int value)? formatter;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final query = this.query;
    final future = this.future;
    if (query != null) {
      return FutureBuilder<AggregateQuerySnapshot>(
        future: query.count().get(),
        builder: (context, snapshot) => _DashboardStatCard(
          title: title,
          subtitle: subtitle,
          value: _formatValue(snapshot.data?.count ?? 0),
          icon: icon,
          iconColor: iconColor,
          compact: compact,
        ),
      );
    }
    return FutureBuilder<int>(
      future: future,
      builder: (context, snapshot) => _DashboardStatCard(
        title: title,
        subtitle: subtitle,
        value: _formatValue(snapshot.data ?? 0),
        icon: icon,
        iconColor: iconColor,
        compact: compact,
      ),
    );
  }

  String _formatValue(int value) => formatter?.call(value) ?? value.toString();
}

class _DashboardStatCard extends StatelessWidget {
  const _DashboardStatCard({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.icon,
    required this.iconColor,
    this.compact = false,
  });

  final String title;
  final String subtitle;
  final String value;
  final IconData icon;
  final Color iconColor;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: EdgeInsets.all(compact ? 12 : 18),
      decoration: BoxDecoration(
        color: theme.cardTheme.color ?? Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(8),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: (compact
                          ? theme.textTheme.titleLarge
                          : theme.textTheme.headlineSmall)
                      ?.copyWith(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Container(
            width: compact ? 34 : 42,
            height: compact ? 34 : 42,
            decoration: BoxDecoration(
              color: iconColor.withAlpha(28),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: compact ? 18 : 22),
          ),
        ],
      ),
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: OutlinedButton.icon(
        icon: Icon(icon),
        label: Text(label),
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(double.infinity, 44),
          alignment: Alignment.centerLeft,
        ),
      ),
    );
  }
}

String _formatBytes(int bytes) {
  if (bytes <= 0) return '0 B';
  const units = ['B', 'KB', 'MB', 'GB', 'TB'];
  var size = bytes.toDouble();
  var unitIndex = 0;
  while (size >= 1024 && unitIndex < units.length - 1) {
    size /= 1024;
    unitIndex++;
  }
  final decimals = size >= 10 || unitIndex == 0 ? 0 : 1;
  return '${size.toStringAsFixed(decimals)} ${units[unitIndex]}';
}
