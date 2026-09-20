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
  _ReportScope? _busyScope;
  DateTime _selectedMonth = DateTime(DateTime.now().year, DateTime.now().month);

  bool get _busy => _busyFormat != null;
  bool get _supportsMonthExport =>
      widget.reportType == _ReportType.attendance ||
      widget.reportType == _ReportType.gatePass;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DataSurface(
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
                  onPressed: _busy
                      ? null
                      : () =>
                            _download(context, format, scope: _ReportScope.all),
                  icon: _busyFormat == format && _busyScope == _ReportScope.all
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
                    _busyFormat == format && _busyScope == _ReportScope.all
                        ? 'Preparing ${format.label}'
                        : 'Download ${format.label}',
                  ),
                ),
            ],
          ),
          if (_supportsMonthExport) ...[
            const SizedBox(height: 16),
            Divider(color: theme.colorScheme.outlineVariant),
            const SizedBox(height: 12),
            Text(
              'Specific month',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                OutlinedButton.icon(
                  onPressed: _busy ? null : () => _pickMonth(context),
                  icon: const Icon(Icons.calendar_month_outlined),
                  label: Text(DateFormat('MMMM yyyy').format(_selectedMonth)),
                ),
                for (final format in widget.formats)
                  FilledButton.icon(
                    onPressed: _busy
                        ? null
                        : () => _download(
                            context,
                            format,
                            scope: _ReportScope.month,
                          ),
                    icon:
                        _busyFormat == format &&
                            _busyScope == _ReportScope.month
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
                      _busyFormat == format && _busyScope == _ReportScope.month
                          ? 'Preparing ${format.label}'
                          : 'Download ${format.label}',
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _pickMonth(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedMonth,
      firstDate: DateTime(2000),
      lastDate: DateTime(DateTime.now().year + 1, 12, 31),
      helpText: 'Select any day in the month',
    );
    if (picked == null || !mounted) return;
    setState(() => _selectedMonth = DateTime(picked.year, picked.month));
  }

  Future<void> _download(
    BuildContext context,
    _ReportFormat format, {
    required _ReportScope scope,
  }) async {
    final app = SchoolAdminViewModelScope.of(context);
    final messenger = ScaffoldMessenger.of(context);
    setState(() {
      _busyFormat = format;
      _busyScope = scope;
    });
    try {
      final schoolYear = await app.attendance.activeSchoolYear();
      if (schoolYear == null) {
        messenger.showSnackBar(
          const SnackBar(content: Text('Create an active school year first.')),
        );
        return;
      }

      final snapshot = scope == _ReportScope.month
          ? await app.repository
                .schoolYearCollection(
                  schoolYear.id,
                  widget.reportType.collectionName,
                )
                .where(
                  'timestamp',
                  isGreaterThanOrEqualTo: Timestamp.fromDate(_selectedMonth),
                )
                .where(
                  'timestamp',
                  isLessThan: Timestamp.fromDate(
                    DateTime(_selectedMonth.year, _selectedMonth.month + 1),
                  ),
                )
                .get()
          : widget.reportType == _ReportType.attendance
          ? await app.repository.attendanceLogsAll(schoolYearId: schoolYear.id)
          : await app.repository
                .schoolYearCollection(
                  schoolYear.id,
                  widget.reportType.collectionName,
                )
                .get();
      if (snapshot.docs.isEmpty) {
        final monthLabel = DateFormat('MMMM yyyy').format(_selectedMonth);
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              scope == _ReportScope.month
                  ? 'No ${widget.reportType.emptyLabel} logs found for $monthLabel.'
                  : 'No ${widget.reportType.emptyLabel} logs to export yet.',
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
      final monthFileLabel = DateFormat('yyyy-MM').format(_selectedMonth);
      downloadBytes(
        fileName: scope == _ReportScope.month
            ? '${_fileSafeName(schoolYear.name)}-$monthFileLabel-${widget.reportType.fileLabel}-logs.${format.extension}'
            : '${_fileSafeName(schoolYear.name)}-all-${widget.reportType.fileLabel}-logs.${format.extension}',
        bytes: bytes,
        mimeType: format.mimeType,
      );
      await app.audit.record(
        action:
            '${widget.reportType.auditLabel}_${scope.auditPart}_export_${format.extension}',
        actorId: app.currentUser!.id,
        actorName: app.currentUser!.fullName,
        target: schoolYear.name,
        metadata: {
          'logCount': snapshot.docs.length,
          if (scope == _ReportScope.month) 'month': monthFileLabel,
        },
      );
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            scope == _ReportScope.month
                ? '${format.label} report for ${DateFormat('MMMM yyyy').format(_selectedMonth)} downloaded.'
                : '${format.label} report downloaded.',
          ),
        ),
      );
    } catch (error) {
      messenger.showSnackBar(
        SnackBar(content: Text('Could not download report: $error')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _busyFormat = null;
          _busyScope = null;
        });
      }
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

enum _ReportScope {
  all('all'),
  month('month');

  const _ReportScope(this.auditPart);

  final String auditPart;
}
