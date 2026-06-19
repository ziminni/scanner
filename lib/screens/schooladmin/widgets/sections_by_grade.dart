part of '../sections_page.dart';

class _SectionsByGrade extends StatelessWidget {
  const _SectionsByGrade({required this.search});

  final String search;

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: app.repository.activeSectionsStream(),
      builder: (context, snapshot) {
        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) {
          return const EmptyState(title: 'No sections records yet');
        }

        final query = search.trim().toLowerCase();
        final filteredDocs = docs.where((doc) {
          if (query.isEmpty) return true;
          final data = doc.data();
          return '${data['name']} ${data['gradeLevel']} ${data['adviser']}'
              .toLowerCase()
              .contains(query);
        }).toList();
        if (filteredDocs.isEmpty) {
          return const EmptyState(title: 'No sections found');
        }

        final grouped =
            <String, List<QueryDocumentSnapshot<Map<String, dynamic>>>>{};
        for (final doc in filteredDocs) {
          final grade = (doc.data()['gradeLevel'] as String? ?? '').trim();
          grouped
              .putIfAbsent(grade.isEmpty ? 'No grade level' : grade, () => [])
              .add(doc);
        }

        final gradeLevels = grouped.keys.toList()..sort(_gradeSort);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final gradeLevel in gradeLevels) ...[
              Text(
                _gradeLabel(gradeLevel),
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  for (final doc in grouped[gradeLevel]!..sort(_sectionSort))
                    _SectionCard(
                      data: doc.data(),
                      onOpen: () => showDialog<void>(
                        context: context,
                        builder: (_) =>
                            _SectionDetailsDialog(section: doc.data()),
                      ),
                      onEdit: () => showDialog<void>(
                        context: context,
                        builder: (_) =>
                            _EditSectionDialog(docId: doc.id, data: doc.data()),
                      ),
                      onArchive: () async {
                        await _archiveSectionAndUnassignStudents(
                          context,
                          doc.id,
                          doc.data(),
                        );
                      },
                    ),
                ],
              ),
              const SizedBox(height: 18),
            ],
          ],
        );
      },
    );
  }

  int _gradeSort(String a, String b) {
    final aNumber = int.tryParse(a.replaceAll(RegExp(r'[^0-9]'), ''));
    final bNumber = int.tryParse(b.replaceAll(RegExp(r'[^0-9]'), ''));
    if (aNumber != null && bNumber != null) return aNumber.compareTo(bNumber);
    if (aNumber != null) return -1;
    if (bNumber != null) return 1;
    return a.compareTo(b);
  }

  String _gradeLabel(String gradeLevel) {
    final value = gradeLevel.trim();
    if (value.isEmpty || value == 'No grade level') return value;
    if (value.toLowerCase().startsWith('grade')) return value;
    return 'Grade $value';
  }

  int _sectionSort(
    QueryDocumentSnapshot<Map<String, dynamic>> a,
    QueryDocumentSnapshot<Map<String, dynamic>> b,
  ) {
    final aName = a.data()['name'] as String? ?? '';
    final bName = b.data()['name'] as String? ?? '';
    return aName.compareTo(bName);
  }

  Future<void> _archiveSectionAndUnassignStudents(
    BuildContext context,
    String sectionDocId,
    Map<String, dynamic> section,
  ) async {
    final app = AppScope.of(context);
    final sectionName = (section['name'] as String? ?? '').trim();
    if (sectionName.isEmpty) return;

    await app.repository.archiveGlobalRecord(
      collection: 'sections',
      docId: sectionDocId,
      actorId: app.currentUser!.id,
      actorName: app.currentUser!.fullName,
      target: sectionName,
    );

    final schoolYear = await app.attendance.activeSchoolYear();
    var unassignedCount = 0;
    if (schoolYear != null) {
      final students = await app.repository
          .schoolYearCollection(schoolYear.id, 'students')
          .where('section', isEqualTo: sectionName)
          .where('archived', isEqualTo: false)
          .get();

      var batch = app.firestore.batch();
      var writes = 0;
      for (final student in students.docs) {
        batch.set(student.reference, {
          'section': '',
          'previousSection': sectionName,
          'sectionUnassignedAt': FieldValue.serverTimestamp(),
          'sectionUnassignedReason': 'section_archived',
        }, SetOptions(merge: true));
        writes++;
        unassignedCount++;
        if (writes == 450) {
          await batch.commit();
          batch = app.firestore.batch();
          writes = 0;
        }
      }
      if (writes > 0) await batch.commit();

      await app.audit.record(
        action: 'section_students_unassigned',
        actorId: app.currentUser!.id,
        actorName: app.currentUser!.fullName,
        target: sectionName,
        metadata: {
          'schoolYear': schoolYear.name,
          'studentsUnassigned': unassignedCount,
        },
      );
    }

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          unassignedCount == 0
              ? '$sectionName archived.'
              : '$sectionName archived. $unassignedCount students were unassigned.',
        ),
      ),
    );
  }
}
