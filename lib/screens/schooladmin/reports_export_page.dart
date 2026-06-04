import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/services/app_controller.dart';
import '../../core/utils/download_file.dart';
import '../../models/models.dart';
import '../../shared/widgets/admin_widgets.dart';

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
            formats: [_ReportFormat.excel, _ReportFormat.pdf],
          ),
          _TemplateDownloadCard(
            title: 'Student Import Template',
            description:
                'Download the spreadsheet template for bulk importing students.',
            icon: Icons.school_outlined,
            fileName: 'Students-template.xlsx',
            assetPath: 'assets/templates/Students-template.xlsx',
          ),
          _TemplateDownloadCard(
            title: 'Teacher Import Template',
            description:
                'Download the spreadsheet template for bulk importing teachers.',
            icon: Icons.badge_outlined,
            fileName: 'Teachers-template.xlsx',
            assetPath: 'assets/templates/Teachers-template.xlsx',
          ),
        ],
      ),
    );
  }
}

class _TemplateDownloadCard extends StatelessWidget {
  const _TemplateDownloadCard({
    required this.title,
    required this.description,
    required this.icon,
    required this.fileName,
    required this.assetPath,
  });

  final String title;
  final String description;
  final IconData icon;
  final String fileName;
  final String assetPath;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      width: 420,
      child: DataSurface(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withAlpha(24),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: theme.colorScheme.primary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        description,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: () => _downloadTemplate(context),
              icon: const Icon(Icons.download_outlined),
              label: const Text('Download Template'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _downloadTemplate(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final bytes = await _loadTemplateBytes();
      downloadBytes(
        fileName: fileName,
        bytes: bytes,
        mimeType:
            'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
      );
      messenger.showSnackBar(SnackBar(content: Text('$title downloaded.')));
    } catch (error) {
      messenger.showSnackBar(
        SnackBar(content: Text('Could not download template: $error')),
      );
    }
  }

  Future<Uint8List> _loadTemplateBytes() async {
    try {
      final data = await rootBundle.load(assetPath);
      return data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
    } catch (_) {
      final bundle = NetworkAssetBundle(Uri.base);
      final data = await bundle.load('assets/$assetPath');
      return data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
    }
  }
}

class _ReportExportCard extends StatefulWidget {
  const _ReportExportCard({
    required this.title,
    required this.description,
    required this.icon,
    required this.formats,
  });

  final String title;
  final String description;
  final IconData icon;
  final List<_ReportFormat> formats;

  @override
  State<_ReportExportCard> createState() => _ReportExportCardState();
}

class _ReportExportCardState extends State<_ReportExportCard> {
  _ReportFormat? _busyFormat;

  bool get _busy => _busyFormat != null;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      width: 420,
      child: DataSurface(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withAlpha(24),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(widget.icon, color: theme.colorScheme.primary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.description,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                for (final format in widget.formats)
                  FilledButton.icon(
                    onPressed: _busy ? null : () => _download(context, format),
                    icon: _busyFormat == format
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Icon(format.icon),
                    label: Text(
                      _busyFormat == format
                          ? 'Preparing ${format.label}'
                          : 'Download ${format.label}',
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _download(BuildContext context, _ReportFormat format) async {
    final app = AppScope.of(context);
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _busyFormat = format);
    try {
      final schoolYear = await app.attendance.activeSchoolYear();
      if (schoolYear == null) {
        messenger.showSnackBar(
          const SnackBar(content: Text('Create an active school year first.')),
        );
        return;
      }

      final snapshot = await app.repository.attendanceLogsAll(
        schoolYearId: schoolYear.id,
      );
      final logs = snapshot.docs.map(AttendanceLog.fromDoc).toList();
      if (logs.isEmpty) {
        messenger.showSnackBar(
          const SnackBar(content: Text('No attendance logs to export yet.')),
        );
        return;
      }

      final bytes = format == _ReportFormat.excel
          ? await app.admin.exportLogsExcel(logs)
          : await app.admin.exportLogsPdf(logs);
      downloadBytes(
        fileName:
            '${_fileSafeName(schoolYear.name)}-all-attendance-logs.${format.extension}',
        bytes: bytes,
        mimeType: format.mimeType,
      );
      await app.audit.record(
        action: 'attendance_export_${format.extension}',
        actorId: app.currentUser!.id,
        actorName: app.currentUser!.fullName,
        target: schoolYear.name,
        metadata: {'logCount': logs.length},
      );
      messenger.showSnackBar(
        SnackBar(content: Text('${format.label} report downloaded.')),
      );
    } catch (error) {
      messenger.showSnackBar(
        SnackBar(content: Text('Could not download report: $error')),
      );
    } finally {
      if (mounted) setState(() => _busyFormat = null);
    }
  }

  String _fileSafeName(String value) {
    return value
        .trim()
        .replaceAll(RegExp(r'[^A-Za-z0-9._-]+'), '-')
        .replaceAll(RegExp(r'-+'), '-')
        .replaceAll(RegExp(r'^-|-$'), '');
  }
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
