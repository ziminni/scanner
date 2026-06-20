import 'package:flutter/material.dart';

import '../../shared/widgets/admin.dart';
import 'attendance_logs_page.dart';

class ScannerUsersPage extends StatelessWidget {
  const ScannerUsersPage({super.key});

  @override
  Widget build(BuildContext context) => const AdminPage(
    title: 'Scanner Users',
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CollectionTable(
          collection: 'users',
          columns: ['fullName', 'email', 'status', 'lastLoginAt'],
        ),
        SizedBox(height: 20),
        Text('Scanner activity'),
        SizedBox(height: 8),
        AttendanceLogsTable(limit: 50),
      ],
    ),
  );
}
