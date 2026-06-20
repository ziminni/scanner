part of '../reports_export_page.dart';

class _ReportExportCard extends StatefulWidget {
  const _ReportExportCard({
    required this.title,
    required this.description,
    required this.icon,
    required this.reportType,
    required this.formats,
  });

  final String title;
  final String description;
  final IconData icon;
  final _ReportType reportType;
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
    final app = SchoolAdminViewModelScope.of(context);
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

      final snapshot = await app.repository
          .schoolYearCollection(schoolYear.id, widget.reportType.collectionName)
          .get();
      if (snapshot.docs.isEmpty) {
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              'No ${widget.reportType.emptyLabel} logs to export yet.',
            ),
          ),
        );
        return;
      }

      late final Uint8List bytes;
      if (widget.reportType == _ReportType.attendance) {
        final logs = snapshot.docs.map(AttendanceLog.fromDoc).toList();
        bytes = format == _ReportFormat.excel
            ? await app.admin.exportLogsExcel(logs)
            : await app.admin.exportLogsPdf(logs);
      } else {
        final logs = snapshot.docs.map(GatePassLog.fromDoc).toList();
        bytes = format == _ReportFormat.excel
            ? await app.admin.exportGatePassLogsExcel(logs)
            : await app.admin.exportGatePassLogsPdf(logs);
      }
      downloadBytes(
        fileName:
            '${_fileSafeName(schoolYear.name)}-all-${widget.reportType.fileLabel}-logs.${format.extension}',
        bytes: bytes,
        mimeType: format.mimeType,
      );
      await app.audit.record(
        action: '${widget.reportType.auditLabel}_export_${format.extension}',
        actorId: app.currentUser!.id,
        actorName: app.currentUser!.fullName,
        target: schoolYear.name,
        metadata: {'logCount': snapshot.docs.length},
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
