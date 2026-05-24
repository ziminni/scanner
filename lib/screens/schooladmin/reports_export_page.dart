import 'package:flutter/material.dart';

import '../../core/services/app_controller.dart';
import '../../models/models.dart';
import '../../shared/widgets/admin_widgets.dart';
import 'attendance_logs_page.dart';

class ReportsExportPage extends StatelessWidget {
  const ReportsExportPage({super.key});

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    return AdminPage(
      title: 'Reports & Export',
      actions: [
        OutlinedButton.icon(
          icon: const Icon(Icons.table_view_outlined),
          label: const Text('Prepare Excel'),
          onPressed: () async {
            final schoolYear = await app.attendance.activeSchoolYear();
            if (schoolYear == null) return;
            final docs = await app.firestore
                .collection('school_years')
                .doc(schoolYear.id)
                .collection('attendance_logs')
                .limit(500)
                .get();
            await app.admin.exportLogsExcel(
              docs.docs.map(AttendanceLog.fromDoc).toList(),
            );
            await app.audit.record(
              action: 'attendance_export_excel',
              actorId: app.currentUser!.id,
              actorName: app.currentUser!.fullName,
            );
          },
        ),
        OutlinedButton.icon(
          icon: const Icon(Icons.picture_as_pdf_outlined),
          label: const Text('Prepare PDF'),
          onPressed: () async {
            final schoolYear = await app.attendance.activeSchoolYear();
            if (schoolYear == null) return;
            final docs = await app.firestore
                .collection('school_years')
                .doc(schoolYear.id)
                .collection('attendance_logs')
                .limit(500)
                .get();
            await app.admin.exportLogsPdf(
              docs.docs.map(AttendanceLog.fromDoc).toList(),
            );
            await app.audit.record(
              action: 'attendance_export_pdf',
              actorId: app.currentUser!.id,
              actorName: app.currentUser!.fullName,
            );
          },
        ),
      ],
      child: const AttendanceLogsTable(limit: 200),
    );
  }
}
