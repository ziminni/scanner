import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../core/utils/download_file.dart';
import '../../models/models.dart';
import '../../shared/widgets/admin.dart';
import 'viewmodels/school_admin_viewmodel.dart';

part 'widgets/template_download_card.dart';
part 'widgets/report_export_card.dart';

class ReportsExportPage extends StatelessWidget {
  const ReportsExportPage({super.key});

  @override
  Widget build(BuildContext context) {
    return AdminPage(
      title: 'Reports & Export',
      child: Wrap(
        spacing: 16,
        runSpacing: 16,
        children: const [
          _ReportExportCard(
            title: 'All Attendance Logs',
            description:
                'Download every attendance scan recorded in the active school year since scanning started.',
            icon: Icons.fact_check_outlined,
            reportType: _ReportType.attendance,
            formats: [_ReportFormat.excel, _ReportFormat.pdf],
          ),
          _ReportExportCard(
            title: 'All Gate Pass Logs',
            description:
                'Download every gate pass exit and return record from the active school year.',
            icon: Icons.directions_walk_outlined,
            reportType: _ReportType.gatePass,
            formats: [_ReportFormat.excel, _ReportFormat.pdf],
          ),
          _TemplateDownloadCard(
            title: 'Student Import Template',
            description:
                'Download the spreadsheet template for bulk importing students.',
            icon: Icons.school_outlined,
            fileName: 'Students-template.xlsx',
            assetPath: 'assets/templates/Students-template-v3.xlsx',
          ),
          _TemplateDownloadCard(
            title: 'Teacher Import Template',
            description:
                'Download the spreadsheet template for bulk importing teachers.',
            icon: Icons.badge_outlined,
            fileName: 'Teachers-template.xlsx',
            assetPath: 'assets/templates/Teachers-template-v2.xlsx',
          ),
        ],
      ),
    );
  }
}

enum _ReportType {
  attendance(
    collectionName: 'attendance_logs',
    emptyLabel: 'attendance',
    fileLabel: 'attendance',
    auditLabel: 'attendance',
  ),
  gatePass(
    collectionName: 'gate_pass_logs',
    emptyLabel: 'gate pass',
    fileLabel: 'gate-pass',
    auditLabel: 'gate_pass',
  );

  const _ReportType({
    required this.collectionName,
    required this.emptyLabel,
    required this.fileLabel,
    required this.auditLabel,
  });

  final String collectionName;
  final String emptyLabel;
  final String fileLabel;
  final String auditLabel;
}

enum _ReportFormat {
  excel(
    'Excel',
    'xlsx',
    'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
    Icons.table_view_outlined,
  ),
  pdf('PDF', 'pdf', 'application/pdf', Icons.picture_as_pdf_outlined);

  const _ReportFormat(this.label, this.extension, this.mimeType, this.icon);

  final String label;
  final String extension;
  final String mimeType;
  final IconData icon;
}
