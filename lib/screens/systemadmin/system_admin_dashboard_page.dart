import 'package:flutter/material.dart';

import '../../core/services/app_controller.dart';
import '../../models/enums.dart';
import '../../shared/widgets/app_widgets.dart';
import 'audit_logs_page.dart';
import '../schooladmin/attendance_logs_page.dart';

class SystemAdminDashboardPage extends StatelessWidget {
  const SystemAdminDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final user = app.currentUser!;
    final firestore = app.firestore;
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
                query: firestore.collection('users'),
                builder: (value) => MetricCard(
                  label: 'Total users',
                  value: value,
                  icon: Icons.people_alt_outlined,
                ),
              ),
            FirestoreCount(
              query: firestore
                  .collectionGroup('students')
                  .where('archived', isEqualTo: false),
              builder: (value) => MetricCard(
                label: 'Total students',
                value: value,
                icon: Icons.school_outlined,
              ),
            ),
            FirestoreCount(
              query: firestore
                  .collectionGroup('teachers')
                  .where('archived', isEqualTo: false),
              builder: (value) => MetricCard(
                label: 'Total teachers',
                value: value,
                icon: Icons.badge_outlined,
              ),
            ),
            FirestoreCount(
              query: firestore
                  .collection('users')
                  .where('role', isEqualTo: UserRole.staffScanner.key)
                  .where('status', isEqualTo: 'active'),
              builder: (value) => MetricCard(
                label: 'Active scanner users',
                value: value,
                icon: Icons.qr_code_scanner,
              ),
            ),
            if (!systemAdmin)
              FirestoreCount(
                query: firestore
                    .collectionGroup('attendance_logs')
                    .where(
                      'attendanceStatus',
                      isEqualTo: AttendanceStatus.late.name,
                    ),
                builder: (value) => MetricCard(
                  label: 'Late count',
                  value: value,
                  icon: Icons.schedule_outlined,
                ),
              ),
            if (!systemAdmin)
              FirestoreCount(
                query: firestore
                    .collectionGroup('attendance_logs')
                    .where(
                      'attendanceStatus',
                      isEqualTo: AttendanceStatus.absent.name,
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
