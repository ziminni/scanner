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
  final Set<String> _deletingIds = {};
  final Set<String> _exportingIds = {};

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

              return LayoutBuilder(
                builder: (context, constraints) {
                  final width = constraints.maxWidth;
                  final columns = width >= 1180
                      ? 3
                      : width >= 760
                      ? 2
                      : 1;

                  return GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: columns,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: columns == 1 ? 4.4 : 2.55,
                    ),
                    itemCount: schoolYears.length,
                    itemBuilder: (context, index) {
                      final schoolYear = schoolYears[index];
                      return _CompletedSchoolYearCard(
                        schoolYear: schoolYear,
                        deleting: _deletingIds.contains(schoolYear.id),
                        exporting: _exportingIds.contains(schoolYear.id),
                        onDelete: () => _confirmDelete(app, schoolYear),
                        onExportExcel: () => _downloadLogs(
                          app,
                          schoolYear,
                          _ArchiveExportFormat.excel,
                        ),
                        onExportPdf: () => _downloadLogs(
                          app,
                          schoolYear,
                          _ArchiveExportFormat.pdf,
                        ),
                      );
                    },
                  );
                },
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

  Future<void> _confirmDelete(AppController app, SchoolYear schoolYear) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete school year?'),
        content: Text(
          'This will permanently delete ${schoolYear.name}, including its students, teachers, and attendance records. This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton.icon(
            icon: const Icon(Icons.delete_outline),
            label: const Text('Delete'),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _deletingIds.add(schoolYear.id));
    try {
      await _deleteSchoolYear(app, schoolYear);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('${schoolYear.name} deleted.')));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Delete failed: $error')));
    } finally {
      if (mounted) {
        setState(() => _deletingIds.remove(schoolYear.id));
      }
    }
  }

  Future<void> _deleteSchoolYear(
    AppController app,
    SchoolYear schoolYear,
  ) async {
    if (schoolYear.isActive) {
      throw StateError('Active school years cannot be deleted.');
    }

    for (final collection in ['students', 'teachers', 'attendance_logs']) {
      await _deleteCollection(
        app.repository.schoolYearCollection(schoolYear.id, collection),
      );
    }

    final archiveDocs = await app.repository
        .rootCollection('archives')
        .where('schoolYearId', isEqualTo: schoolYear.id)
        .get();
    for (final doc in archiveDocs.docs) {
      await doc.reference.delete();
    }

    await app.repository
        .rootCollection('school_years')
        .doc(schoolYear.id)
        .delete();
    await app.audit.record(
      action: 'school_year_deleted',
      actorId: app.currentUser!.id,
      actorName: app.currentUser!.fullName,
      target: schoolYear.name,
    );
  }

  Future<void> _downloadLogs(
    AppController app,
    SchoolYear schoolYear,
    _ArchiveExportFormat format,
  ) async {
    setState(() => _exportingIds.add(schoolYear.id));
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
        setState(() => _exportingIds.remove(schoolYear.id));
      }
    }
  }

  String _fileSafeName(String value) {
    final cleaned = value
        .trim()
        .replaceAll(RegExp(r'[^A-Za-z0-9._-]+'), '-')
        .replaceAll(RegExp(r'-+'), '-');
    return cleaned.isEmpty ? 'school-year' : cleaned;
  }

  Future<void> _deleteCollection(
    CollectionReference<Map<String, dynamic>> collection,
  ) async {
    while (true) {
      final snapshot = await collection.limit(400).get();
      if (snapshot.docs.isEmpty) return;

      final batch = FirebaseFirestore.instance.batch();
      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    }
  }
}

enum _ArchiveExportFormat { excel, pdf }

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
                Text(
                  loading
                      ? 'Loading...'
                      : schoolYear?.name ?? 'No active school year',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                  ),
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
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              schoolYear == null ? 'Inactive' : 'Active',
              style: TextStyle(
                color: schoolYear == null
                    ? Colors.grey.shade800
                    : const Color(0xFF047857),
                fontWeight: FontWeight.w800,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CompletedSchoolYearCard extends StatelessWidget {
  const _CompletedSchoolYearCard({
    required this.schoolYear,
    required this.deleting,
    required this.exporting,
    required this.onDelete,
    required this.onExportExcel,
    required this.onExportPdf,
  });

  final SchoolYear schoolYear;
  final bool deleting;
  final bool exporting;
  final VoidCallback onDelete;
  final VoidCallback onExportExcel;
  final VoidCallback onExportPdf;

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final theme = Theme.of(context);

    return DataSurface(
      child: FutureBuilder<_SchoolYearStats>(
        future: _SchoolYearStats.load(app, schoolYear.id),
        builder: (context, snapshot) {
          final stats = snapshot.data;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          schoolYear.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _dateRange(schoolYear),
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
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      FilledButton.icon(
                        icon: deleting
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.delete_outline),
                        label: const Text('Delete'),
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: deleting ? null : onDelete,
                      ),
                      const SizedBox(width: 6),
                      PopupMenuButton<_ArchiveExportFormat>(
                        tooltip: 'More archive actions',
                        enabled: !exporting,
                        icon: exporting
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.keyboard_arrow_down),
                        onSelected: (format) {
                          switch (format) {
                            case _ArchiveExportFormat.excel:
                              onExportExcel();
                            case _ArchiveExportFormat.pdf:
                              onExportPdf();
                          }
                        },
                        itemBuilder: (context) => const [
                          PopupMenuItem(
                            value: _ArchiveExportFormat.excel,
                            child: ListTile(
                              leading: Icon(Icons.table_view_outlined),
                              title: Text('Download logs as Excel'),
                              dense: true,
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                          PopupMenuItem(
                            value: _ArchiveExportFormat.pdf,
                            child: ListTile(
                              leading: Icon(Icons.picture_as_pdf_outlined),
                              title: Text('Download logs as PDF'),
                              dense: true,
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 18),
              if (snapshot.connectionState == ConnectionState.waiting)
                const LinearProgressIndicator()
              else
                Row(
                  children: [
                    Expanded(
                      child: _StatTile(
                        label: 'Students',
                        value: (stats?.students ?? 0).toString(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _StatTile(
                        label: 'Teachers',
                        value: (stats?.teachers ?? 0).toString(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _StatTile(
                        label: 'Attendance',
                        value: (stats?.attendanceLogs ?? 0).toString(),
                      ),
                    ),
                  ],
                ),
            ],
          );
        },
      ),
    );
  }

  String _dateRange(SchoolYear schoolYear) {
    return _SchoolYearDateRange.format(schoolYear);
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

class _StatTile extends StatelessWidget {
  const _StatTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _SchoolYearStats {
  const _SchoolYearStats({
    required this.students,
    required this.teachers,
    required this.attendanceLogs,
  });

  final int students;
  final int teachers;
  final int attendanceLogs;

  static Future<_SchoolYearStats> load(
    AppController app,
    String schoolYearId,
  ) async {
    final results = await Future.wait([
      app.repository
          .schoolYearCollection(schoolYearId, 'students')
          .count()
          .get(),
      app.repository
          .schoolYearCollection(schoolYearId, 'teachers')
          .count()
          .get(),
      app.repository
          .schoolYearCollection(schoolYearId, 'attendance_logs')
          .count()
          .get(),
    ]);

    return _SchoolYearStats(
      students: results[0].count ?? 0,
      teachers: results[1].count ?? 0,
      attendanceLogs: results[2].count ?? 0,
    );
  }
}
