import 'package:flutter/material.dart';

import '../../core/services/app_controller.dart';
import '../../core/constants/enums.dart';
import '../../shared/widgets/app_widgets.dart';
import 'attendance_logs_page.dart';
import '../systemadmin/audit_logs_page.dart';

class SchoolAdminDashboardPage extends StatelessWidget {
  const SchoolAdminDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final user = app.currentUser!;
    final systemAdmin = user.role == UserRole.systemAdministrator;

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
            if (systemAdmin)
              FirestoreCount(
                query: app.repository.usersQuery(),
                builder: (value) => MetricCard(
                  label: 'Total users',
                  value: value,
                  icon: Icons.people_alt_outlined,
                ),
              ),
            ActiveSchoolYearCount(
              collection: 'students',
              filters: const {'archived': false},
              builder: (value) => MetricCard(
                label: 'Total students',
                value: value,
                icon: Icons.school_outlined,
              ),
            ),
            ActiveSchoolYearCount(
              collection: 'teachers',
              filters: const {'archived': false},
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
            if (!systemAdmin)
              ActiveSchoolYearCount(
                collection: 'attendance_logs',
                filters: {'attendanceStatus': AttendanceStatus.late.name},
                builder: (value) => MetricCard(
                  label: 'Late count',
                  value: value,
                  icon: Icons.schedule_outlined,
                ),
              ),
            if (!systemAdmin)
              ActiveSchoolYearCount(
                collection: 'attendance_logs',
                filters: {'attendanceStatus': AttendanceStatus.absent.name},
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
          systemAdmin ? 'Recent system activities' : 'Recent attendance logs',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 8),
        systemAdmin
            ? const AuditLogsList(limit: 8)
            : const AttendanceLogsTable(limit: 10),
      ],
    );
  }
}
