import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/services/app_controller.dart';
import '../../models/models.dart';
import '../../shared/widgets/admin.dart';
import '../../shared/widgets/app_widgets.dart';
import 'viewmodels/school_admin_viewmodel.dart';

part 'widgets/completed_school_year_card.dart';
part 'widgets/archive_stat_tile.dart';

class SchoolArchiveManagementPage extends StatefulWidget {
  const SchoolArchiveManagementPage({super.key});

  @override
  State<SchoolArchiveManagementPage> createState() =>
      _SchoolArchiveManagementPageState();
}

class _SchoolArchiveManagementPageState
    extends State<SchoolArchiveManagementPage> {
  final Set<String> _deletingIds = {};

  @override
  Widget build(BuildContext context) {
    final app = SchoolAdminViewModelScope.of(context);

    return AdminPage(
      title: 'Completed School Years',
      child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
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
                  childAspectRatio: columns == 1 ? 2.35 : 1.55,
                ),
                itemCount: schoolYears.length,
                itemBuilder: (context, index) {
                  final schoolYear = schoolYears[index];
                  return _CompletedSchoolYearCard(
                    schoolYear: schoolYear,
                    deleting: _deletingIds.contains(schoolYear.id),
                    onDelete: () => _confirmDelete(app, schoolYear),
                  );
                },
              );
            },
          );
        },
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

  Future<void> _confirmDelete(
    SchoolAdminViewModel app,
    SchoolYear schoolYear,
  ) async {
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
    SchoolAdminViewModel app,
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
