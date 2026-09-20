import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/constants/assets.dart';
import '../../core/utils/download_file.dart';
import '../../core/utils/section_qr_worker_client.dart';
import '../../models/models.dart';
import '../../shared/widgets/admin.dart';
import 'viewmodels/school_admin_viewmodel.dart';

part 'widgets/template_download_card.dart';
part 'widgets/report_export_card.dart';
part 'widgets/teacher_qr_download_card.dart';

class ReportsExportPage extends StatelessWidget {
  const ReportsExportPage({super.key});

  @override
  Widget build(BuildContext context) {
    return AdminPage(
      title: 'Reports & Export',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          _ExportSection(
            title: 'Reports',
            description:
                'Download attendance and gate pass records for the active school year.',
            children: [
              _ReportExportCard(
                title: 'Attendance Logs',
                description:
                    'Export every attendance scan, or choose a specific month.',
                icon: Icons.fact_check_outlined,
                reportType: _ReportType.attendance,
                formats: [_ReportFormat.excel, _ReportFormat.pdf],
              ),
              _ReportExportCard(
                title: 'Gate Pass Logs',
                description:
                    'Export every gate pass exit and return record, or choose a specific month.',
                icon: Icons.directions_walk_outlined,
                reportType: _ReportType.gatePass,
                formats: [_ReportFormat.excel, _ReportFormat.pdf],
              ),
            ],
          ),
          SizedBox(height: 24),
          _ExportSection(
            title: 'Templates & QR',
            description:
                'Get import templates and QR assets used by school admin workflows.',
            children: [
              _TemplateDownloadCard(
                title: 'Student Import Template',
                description:
                    'Download the spreadsheet template for bulk importing students.',
                icon: Icons.school_outlined,
                fileName: 'Students-template.xlsx',
                assetPath: AppAssets.studentImportTemplate,
              ),
              _TemplateDownloadCard(
                title: 'Teacher Import Template',
                description:
                    'Download the spreadsheet template for bulk importing teachers.',
                icon: Icons.badge_outlined,
                fileName: 'Teachers-template.xlsx',
                assetPath: AppAssets.teacherImportTemplate,
              ),
              _TeacherQrDownloadCard(),
            ],
          ),
        ],
      ),
    );
  }
}

class _ExportSection extends StatelessWidget {
  const _ExportSection({
    required this.title,
    required this.description,
    required this.children,
  });

  final String title;
  final String description;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          description,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 14),
        LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 900;
            final cardWidth = wide
                ? ((constraints.maxWidth - 16) / 2).floorToDouble()
                : constraints.maxWidth;
            return Wrap(
              spacing: 16,
              runSpacing: 16,
              children: [
                for (final child in children)
                  SizedBox(width: cardWidth, child: child),
              ],
            );
          },
        ),
      ],
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
