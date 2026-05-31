import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../core/services/app_controller.dart';
import '../../models/models.dart';
import '../../shared/widgets/app_widgets.dart';
import '../../shared/widgets/admin_widgets.dart';

part 'widgets/attendance_logs_table.dart';

class AttendanceLogsPage extends StatefulWidget {
  const AttendanceLogsPage({super.key});

  @override
  State<AttendanceLogsPage> createState() => _AttendanceLogsPageState();
}

class _AttendanceLogsPageState extends State<AttendanceLogsPage> {
  final _search = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return AdminPage(
      title: 'Attendance Logs',
      child: Column(
        children: [
          TextField(
            controller: _search,
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search),
              labelText: 'Search name, ID, section, scanner',
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 12),
          AttendanceLogsTable(limit: 200, search: _search.text),
        ],
      ),
    );
  }
}
