import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart' as fp;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/services/app_controller.dart';
import '../../models/models.dart';
import '../../shared/widgets/admin_widgets.dart';
import '../../shared/widgets/app_widgets.dart';

class SystemArchiveManagementPage extends StatefulWidget {
  const SystemArchiveManagementPage({super.key});

  @override
  State<SystemArchiveManagementPage> createState() =>
      _SystemArchiveManagementPageState();
}

class _SystemArchiveManagementPageState
    extends State<SystemArchiveManagementPage> {
  final Set<String> _exportingIds = {};
  final Set<String> _deletingIds = {};

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);

    return AdminPage(
      title: 'Completed School Years',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FutureBuilder<SchoolYear?>(
            future: app.attendance.activeSchoolYear(),
            builder: (context, snapshot) {
              final schoolYear = snapshot.data;
              return _ActiveSchoolYearCard(
                schoolYear: schoolYear,
                loading: snapshot.connectionState == ConnectionState.waiting,
              );
            },
          ),
          const SizedBox(height: 24),
          Text(
            'Past School Years',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: app.repository
                .rootCollection('school_years')
                .where('isActive', isEqualTo: false)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final schoolYears =
                  (snapshot.data?.docs ?? [])
                      .where(_isCompletedSchoolYear)
                      .map(SchoolYear.fromDoc)
                      .toList()
                    ..sort(_sortSchoolYearsDescending);

              if (schoolYears.isEmpty) {
                return const EmptyState(
                  title: 'No completed school years yet',
                  subtitle:
                      'Completed or ended school years will appear here once the active school year is archived.',
                );
              }

              return Column(
                children: [
                  for (var index = 0; index < schoolYears.length; index++) ...[
                    SizedBox(
                      width: double.infinity,
                      child: _CompletedSchoolYearCard(
                        schoolYear: schoolYears[index],
                        exporting: _exportingIds.contains(
                          '${schoolYears[index].id}:logs',
                        ),
                        exportingStudents: _exportingIds.contains(
                          '${schoolYears[index].id}:students',
                        ),
                        exportingTeachers: _exportingIds.contains(
                          '${schoolYears[index].id}:teachers',
                        ),
                        exportingGatePassLogs: _exportingIds.contains(
                          '${schoolYears[index].id}:gate_pass_logs',
                        ),
                        deleting: _deletingIds.contains(schoolYears[index].id),
                        onExportExcel: () => _downloadLogs(
                          app,
                          schoolYears[index],
                          _ArchiveExportFormat.excel,
                        ),
                        onExportPdf: () => _downloadLogs(
                          app,
                          schoolYears[index],
                          _ArchiveExportFormat.pdf,
                        ),
                        onExportStudentsExcel: () => _downloadRoster(
                          app,
                          schoolYears[index],
                          _ArchiveRoster.students,
                          _ArchiveExportFormat.excel,
                        ),
                        onExportStudentsPdf: () => _downloadRoster(
                          app,
                          schoolYears[index],
                          _ArchiveRoster.students,
                          _ArchiveExportFormat.pdf,
                        ),
                        onExportTeachersExcel: () => _downloadRoster(
                          app,
                          schoolYears[index],
                          _ArchiveRoster.teachers,
                          _ArchiveExportFormat.excel,
                        ),
                        onExportTeachersPdf: () => _downloadRoster(
                          app,
                          schoolYears[index],
                          _ArchiveRoster.teachers,
                          _ArchiveExportFormat.pdf,
                        ),
                        onExportGatePassExcel: () => _downloadGatePassLogs(
                          app,
                          schoolYears[index],
                          _ArchiveExportFormat.excel,
                        ),
                        onExportGatePassPdf: () => _downloadGatePassLogs(
                          app,
                          schoolYears[index],
                          _ArchiveExportFormat.pdf,
                        ),
                        onDelete: () => _confirmDelete(app, schoolYears[index]),
                      ),
                    ),
                    if (index != schoolYears.length - 1)
                      const SizedBox(height: 16),
                  ],
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  bool _isCompletedSchoolYear(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    final status = data['status']?.toString().toLowerCase();
    return data['isActive'] != true &&
        (data['archived'] == true ||
            status == 'completed' ||
            status == 'ended');
  }

  int _sortSchoolYearsDescending(SchoolYear a, SchoolYear b) {
    final aEnd = a.finalTermEnd ?? DateTime(0);
    final bEnd = b.finalTermEnd ?? DateTime(0);
    final endCompare = bEnd.compareTo(aEnd);
    if (endCompare != 0) return endCompare;
    return b.name.compareTo(a.name);
  }

  Future<void> _downloadLogs(
    AppController app,
    SchoolYear schoolYear,
    _ArchiveExportFormat format,
  ) async {
    final exportKey = '${schoolYear.id}:logs';
    setState(() => _exportingIds.add(exportKey));
    try {
      final snapshot = await app.repository
          .schoolYearCollection(schoolYear.id, 'attendance_logs')
          .get();
      final logs = snapshot.docs.map(AttendanceLog.fromDoc).toList();
      final bytes = format == _ArchiveExportFormat.excel
          ? await app.admin.exportLogsExcel(logs)
          : await app.admin.exportLogsPdf(logs);
      final extension = format == _ArchiveExportFormat.excel ? 'xlsx' : 'pdf';
      final fileName =
          '${_fileSafeName(schoolYear.name)}-attendance-logs.$extension';
      final savedPath = await fp.FilePicker.saveFile(
        dialogTitle: 'Save attendance logs',
        fileName: fileName,
        type: fp.FileType.custom,
        allowedExtensions: [extension],
        bytes: bytes,
      );

      if (!mounted) return;
      if (savedPath == null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Download canceled.')));
        return;
      }

      await app.audit.record(
        action: format == _ArchiveExportFormat.excel
            ? 'archive_logs_export_excel'
            : 'archive_logs_export_pdf',
        actorId: app.currentUser!.id,
        actorName: app.currentUser!.fullName,
        target: schoolYear.name,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Logs saved as $fileName.')));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Download failed: $error')));
    } finally {
      if (mounted) {
        setState(() => _exportingIds.remove(exportKey));
      }
    }
  }

  Future<void> _downloadRoster(
    AppController app,
    SchoolYear schoolYear,
    _ArchiveRoster roster,
    _ArchiveExportFormat format,
  ) async {
    final collection = roster == _ArchiveRoster.students
        ? 'students'
        : 'teachers';
    final exportKey = '${schoolYear.id}:$collection';
    setState(() => _exportingIds.add(exportKey));
    try {
      final snapshot = await app.repository
          .schoolYearCollection(schoolYear.id, collection)
          .get();
      final isExcel = format == _ArchiveExportFormat.excel;
      late final Uint8List bytes;
      if (roster == _ArchiveRoster.students) {
        final students = snapshot.docs.map(Student.fromDoc).toList();
        bytes = isExcel
            ? await app.admin.exportStudentsExcel(students)
            : await app.admin.exportStudentsPdf(students);
      } else {
        final teachers = snapshot.docs.map(Teacher.fromDoc).toList();
        bytes = isExcel
            ? await app.admin.exportTeachersExcel(teachers)
            : await app.admin.exportTeachersPdf(teachers);
      }

      final extension = isExcel ? 'xlsx' : 'pdf';
      final rosterName = roster == _ArchiveRoster.students
          ? 'students'
          : 'teachers';
      final fileName =
          '${_fileSafeName(schoolYear.name)}-$rosterName.$extension';
      final savedPath = await fp.FilePicker.saveFile(
        dialogTitle: 'Save $rosterName',
        fileName: fileName,
        type: fp.FileType.custom,
        allowedExtensions: [extension],
        bytes: bytes,
      );

      if (!mounted) return;
      if (savedPath == null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Download canceled.')));
        return;
      }

      await app.audit.record(
        action: 'archive_${rosterName}_export_$extension',
        actorId: app.currentUser!.id,
        actorName: app.currentUser!.fullName,
        target: schoolYear.name,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('$fileName was downloaded.')));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Download failed: $error')));
    } finally {
      if (mounted) {
        setState(() => _exportingIds.remove(exportKey));
      }
    }
  }

  Future<void> _downloadGatePassLogs(
    AppController app,
    SchoolYear schoolYear,
    _ArchiveExportFormat format,
  ) async {
    final exportKey = '${schoolYear.id}:gate_pass_logs';
    setState(() => _exportingIds.add(exportKey));
    try {
      final snapshot = await app.repository
          .schoolYearCollection(schoolYear.id, 'gate_pass_logs')
          .get();
      final logs = snapshot.docs.map(GatePassLog.fromDoc).toList();
      final isExcel = format == _ArchiveExportFormat.excel;
      final bytes = isExcel
          ? await app.admin.exportGatePassLogsExcel(logs)
          : await app.admin.exportGatePassLogsPdf(logs);
      final extension = isExcel ? 'xlsx' : 'pdf';
      final fileName =
          '${_fileSafeName(schoolYear.name)}-gate-pass-logs.$extension';
      final savedPath = await fp.FilePicker.saveFile(
        dialogTitle: 'Save gate pass logs',
        fileName: fileName,
        type: fp.FileType.custom,
        allowedExtensions: [extension],
        bytes: bytes,
      );

      if (!mounted) return;
      if (savedPath == null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Download canceled.')));
        return;
      }

      await app.audit.record(
        action: 'archive_gate_pass_logs_export_$extension',
        actorId: app.currentUser!.id,
        actorName: app.currentUser!.fullName,
        target: schoolYear.name,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('$fileName was downloaded.')));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Download failed: $error')));
    } finally {
      if (mounted) {
        setState(() => _exportingIds.remove(exportKey));
      }
    }
  }

  Future<void> _confirmDelete(AppController app, SchoolYear schoolYear) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete school year?'),
        content: Text(
          'This permanently deletes ${schoolYear.name} and all of its '
          'students, teachers, attendance logs, gate pass logs, terms, and '
          'reports. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            icon: const Icon(Icons.delete_outline),
            label: const Text('Delete permanently'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _deleteSchoolYear(app, schoolYear);
    }
  }

  Future<void> _deleteSchoolYear(
    AppController app,
    SchoolYear schoolYear,
  ) async {
    setState(() => _deletingIds.add(schoolYear.id));
    try {
      final schoolYearReference = app.repository
          .rootCollection('school_years')
          .doc(schoolYear.id);
      const subcollections = [
        'students',
        'teachers',
        'attendance_logs',
        'gate_pass_logs',
        'terms',
        'reports',
      ];

      for (final subcollection in subcollections) {
        await _deleteCollection(schoolYearReference.collection(subcollection));
      }

      final archivedRecords = await app.repository
          .rootCollection('archives')
          .where('schoolYearId', isEqualTo: schoolYear.id)
          .get();
      for (var index = 0; index < archivedRecords.docs.length; index += 400) {
        final batch = FirebaseFirestore.instance.batch();
        for (final document in archivedRecords.docs.skip(index).take(400)) {
          batch.delete(document.reference);
        }
        await batch.commit();
      }

      await schoolYearReference.delete();
      await app.audit.record(
        action: 'school_year_deleted',
        actorId: app.currentUser!.id,
        actorName: app.currentUser!.fullName,
        target: schoolYear.name,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${schoolYear.name} was permanently deleted.')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to delete school year: $error')),
      );
    } finally {
      if (mounted) {
        setState(() => _deletingIds.remove(schoolYear.id));
      }
    }
  }

  Future<void> _deleteCollection(
    CollectionReference<Map<String, dynamic>> collection,
  ) async {
    while (true) {
      final snapshot = await collection.limit(400).get();
      if (snapshot.docs.isEmpty) return;

      final batch = FirebaseFirestore.instance.batch();
      for (final document in snapshot.docs) {
        batch.delete(document.reference);
      }
      await batch.commit();
    }
  }

  String _fileSafeName(String value) {
    final cleaned = value
        .trim()
        .replaceAll(RegExp(r'[^A-Za-z0-9._-]+'), '-')
        .replaceAll(RegExp(r'-+'), '-');
    return cleaned.isEmpty ? 'school-year' : cleaned;
  }
}

enum _ArchiveExportFormat { excel, pdf }

enum _ArchiveRoster { students, teachers }

class _ActiveSchoolYearCard extends StatelessWidget {
  const _ActiveSchoolYearCard({
    required this.schoolYear,
    required this.loading,
  });

  final SchoolYear? schoolYear;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final app = AppScope.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: const Color(0xFF047857),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ACTIVE SCHOOL YEAR',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: Colors.white70,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Text(
                        loading
                            ? 'Loading...'
                            : schoolYear?.name ?? 'No active school year',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    if (schoolYear != null) ...[
                      const SizedBox(width: 16),
                      FutureBuilder<int>(
                        future: app.admin.schoolYearStorageUsageBytes(
                          schoolYear!.id,
                        ),
                        builder: (context, snapshot) {
                          final usage = snapshot.hasData
                              ? _formatArchiveBytes(snapshot.data!)
                              : 'Calculating...';
                          return _SchoolYearUsageBadge(value: usage);
                        },
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  schoolYear == null
                      ? 'Create a school year to begin collecting records.'
                      : _SchoolYearDateRange.format(schoolYear!),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.white.withValues(alpha: 0.82),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SchoolYearUsageBadge extends StatelessWidget {
  const _SchoolYearUsageBadge({required this.value});

  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.24)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.storage_outlined, color: Colors.white, size: 18),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Firestore usage',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: Colors.white70,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                value,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CompletedSchoolYearCard extends StatefulWidget {
  const _CompletedSchoolYearCard({
    required this.schoolYear,
    required this.exporting,
    required this.exportingStudents,
    required this.exportingTeachers,
    required this.exportingGatePassLogs,
    required this.deleting,
    required this.onExportExcel,
    required this.onExportPdf,
    required this.onExportStudentsExcel,
    required this.onExportStudentsPdf,
    required this.onExportTeachersExcel,
    required this.onExportTeachersPdf,
    required this.onExportGatePassExcel,
    required this.onExportGatePassPdf,
    required this.onDelete,
  });

  final SchoolYear schoolYear;
  final bool exporting;
  final bool exportingStudents;
  final bool exportingTeachers;
  final bool exportingGatePassLogs;
  final bool deleting;
  final VoidCallback onExportExcel;
  final VoidCallback onExportPdf;
  final VoidCallback onExportStudentsExcel;
  final VoidCallback onExportStudentsPdf;
  final VoidCallback onExportTeachersExcel;
  final VoidCallback onExportTeachersPdf;
  final VoidCallback onExportGatePassExcel;
  final VoidCallback onExportGatePassPdf;
  final VoidCallback onDelete;

  @override
  State<_CompletedSchoolYearCard> createState() =>
      _CompletedSchoolYearCardState();
}

class _CompletedSchoolYearCardState extends State<_CompletedSchoolYearCard> {
  bool _expanded = false;
  Future<int>? _storageUsageFuture;
  String? _storageSchoolYearId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_storageSchoolYearId != widget.schoolYear.id) {
      _storageSchoolYearId = widget.schoolYear.id;
      _storageUsageFuture = AppScope.of(
        context,
      ).admin.schoolYearStorageUsageBytes(widget.schoolYear.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final app = AppScope.of(context);

    return DataSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.schoolYear.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _dateRange(widget.schoolYear),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  FutureBuilder<int>(
                    future: _storageUsageFuture,
                    builder: (context, snapshot) {
                      return _PastSchoolYearUsageBadge(
                        value: snapshot.hasData
                            ? _formatArchiveBytes(snapshot.data!)
                            : 'Calculating...',
                      );
                    },
                  ),
                  const SizedBox(width: 8),
                  AnimatedRotation(
                    turns: _expanded ? 0.25 : 0,
                    duration: const Duration(milliseconds: 180),
                    child: const Icon(Icons.chevron_right),
                  ),
                ],
              ),
            ),
          ),
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: Padding(
              padding: const EdgeInsets.only(top: 16),
              child: FutureBuilder<_ArchivedSchoolYearStats>(
                future: _ArchivedSchoolYearStats.load(
                  app,
                  widget.schoolYear.id,
                ),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const LinearProgressIndicator();
                  }
                  if (snapshot.hasError) {
                    return Text(
                      'Unable to load school year details.',
                      style: TextStyle(color: theme.colorScheme.error),
                    );
                  }

                  final stats = snapshot.data!;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      FullWidthHorizontalTable(
                        child: DataTable(
                          headingRowHeight: 44,
                          dataRowMinHeight: 48,
                          dataRowMaxHeight: 48,
                          columns: const [
                            DataColumn(label: Text('Data')),
                            DataColumn(label: Text('Records')),
                            DataColumn(label: Text('Actions')),
                          ],
                          rows: [
                            _archiveDataRow(
                              'Students',
                              stats.students,
                              actions: _downloadActions(
                                loading: widget.exportingStudents,
                                excelTooltip: 'Download students as Excel',
                                pdfTooltip: 'Download students as PDF',
                                onExcel: widget.onExportStudentsExcel,
                                onPdf: widget.onExportStudentsPdf,
                              ),
                            ),
                            _archiveDataRow(
                              'Teachers',
                              stats.teachers,
                              actions: _downloadActions(
                                loading: widget.exportingTeachers,
                                excelTooltip: 'Download teachers as Excel',
                                pdfTooltip: 'Download teachers as PDF',
                                onExcel: widget.onExportTeachersExcel,
                                onPdf: widget.onExportTeachersPdf,
                              ),
                            ),
                            _archiveDataRow(
                              'Attendance Logs',
                              stats.attendanceLogs,
                              actions: _downloadActions(
                                loading: widget.exporting,
                                excelTooltip: 'Download logs as Excel',
                                pdfTooltip: 'Download logs as PDF',
                                onExcel: widget.onExportExcel,
                                onPdf: widget.onExportPdf,
                              ),
                            ),
                            _archiveDataRow(
                              'Gate Pass Logs',
                              stats.gatePassLogs,
                              actions: _downloadActions(
                                loading: widget.exportingGatePassLogs,
                                excelTooltip:
                                    'Download gate pass logs as Excel',
                                pdfTooltip: 'Download gate pass logs as PDF',
                                onExcel: widget.onExportGatePassExcel,
                                onPdf: widget.onExportGatePassPdf,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Align(
                        alignment: Alignment.centerRight,
                        child: FilledButton.icon(
                          style: FilledButton.styleFrom(
                            backgroundColor: theme.colorScheme.error,
                            foregroundColor: theme.colorScheme.onError,
                          ),
                          onPressed: widget.deleting ? null : widget.onDelete,
                          icon: widget.deleting
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.delete_outline),
                          label: Text(
                            widget.deleting
                                ? 'Deleting...'
                                : 'Delete school year',
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
            crossFadeState: _expanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 180),
          ),
        ],
      ),
    );
  }

  DataRow _archiveDataRow(String label, int count, {Widget? actions}) {
    return DataRow(
      cells: [
        DataCell(
          Row(
            children: [
              Icon(_dataIcon(label), size: 18),
              const SizedBox(width: 8),
              Text(label),
            ],
          ),
        ),
        DataCell(Text(count.toString())),
        DataCell(actions ?? const Text('-')),
      ],
    );
  }

  Widget _downloadActions({
    required bool loading,
    required String excelTooltip,
    required String pdfTooltip,
    required VoidCallback onExcel,
    required VoidCallback onPdf,
  }) {
    if (loading) {
      return const SizedBox(
        width: 18,
        height: 18,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    }
    return Wrap(
      spacing: 4,
      children: [
        IconButton(
          tooltip: excelTooltip,
          icon: const Icon(Icons.table_view_outlined),
          onPressed: onExcel,
        ),
        IconButton(
          tooltip: pdfTooltip,
          icon: const Icon(Icons.picture_as_pdf_outlined),
          onPressed: onPdf,
        ),
      ],
    );
  }

  IconData _dataIcon(String label) {
    return switch (label) {
      'Students' => Icons.school_outlined,
      'Teachers' => Icons.badge_outlined,
      'Attendance Logs' => Icons.fact_check_outlined,
      'Gate Pass Logs' => Icons.directions_walk_outlined,
      'Terms' => Icons.date_range_outlined,
      _ => Icons.description_outlined,
    };
  }

  String _dateRange(SchoolYear schoolYear) {
    return _SchoolYearDateRange.format(schoolYear);
  }
}

class _PastSchoolYearUsageBadge extends StatelessWidget {
  const _PastSchoolYearUsageBadge({required this.value});

  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.storage_outlined,
            size: 17,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(width: 7),
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Firestore usage',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              Text(
                value,
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ArchivedSchoolYearStats {
  const _ArchivedSchoolYearStats({
    required this.students,
    required this.teachers,
    required this.attendanceLogs,
    required this.gatePassLogs,
  });

  final int students;
  final int teachers;
  final int attendanceLogs;
  final int gatePassLogs;

  static Future<_ArchivedSchoolYearStats> load(
    AppController app,
    String schoolYearId,
  ) async {
    const collections = [
      'students',
      'teachers',
      'attendance_logs',
      'gate_pass_logs',
    ];
    final results = await Future.wait([
      for (final collection in collections)
        app.repository
            .schoolYearCollection(schoolYearId, collection)
            .count()
            .get(),
    ]);

    return _ArchivedSchoolYearStats(
      students: results[0].count ?? 0,
      teachers: results[1].count ?? 0,
      attendanceLogs: results[2].count ?? 0,
      gatePassLogs: results[3].count ?? 0,
    );
  }
}

class _SchoolYearDateRange {
  static String format(SchoolYear schoolYear) {
    final start = _firstDate(schoolYear.termStarts);
    final end = _lastDate(schoolYear.termEnds);
    if (start == null && end == null) return 'Date range not set';

    final formatter = DateFormat('MMM d, yyyy');
    final startText = start == null ? 'Not set' : formatter.format(start);
    final endText = end == null ? 'Not set' : formatter.format(end);
    return '$startText - $endText';
  }

  static DateTime? _firstDate(List<DateTime?> dates) {
    for (final date in dates) {
      if (date != null) return date;
    }
    return null;
  }

  static DateTime? _lastDate(List<DateTime?> dates) {
    for (final date in dates.reversed) {
      if (date != null) return date;
    }
    return null;
  }
}

String _formatArchiveBytes(int bytes) {
  if (bytes <= 0) return '0 B';
  const units = ['B', 'KB', 'MB', 'GB', 'TB'];
  var size = bytes.toDouble();
  var unitIndex = 0;
  while (size >= 1024 && unitIndex < units.length - 1) {
    size /= 1024;
    unitIndex++;
  }
  final decimals = size >= 10 || unitIndex == 0 ? 0 : 1;
  return '${size.toStringAsFixed(decimals)} ${units[unitIndex]}';
}
