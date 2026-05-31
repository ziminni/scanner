part of '../sections_page.dart';

class _SectionsByGrade extends StatelessWidget {
  const _SectionsByGrade();

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

        final grouped =
            <String, List<QueryDocumentSnapshot<Map<String, dynamic>>>>{};
        for (final doc in docs) {
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
              Text(gradeLevel, style: Theme.of(context).textTheme.titleMedium),
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
                        await app.repository.archiveGlobalRecord(
                          collection: 'sections',
                          docId: doc.id,
                          actorId: app.currentUser!.id,
                          actorName: app.currentUser!.fullName,
                          target: doc.data()['name'] as String? ?? doc.id,
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

  int _sectionSort(
    QueryDocumentSnapshot<Map<String, dynamic>> a,
    QueryDocumentSnapshot<Map<String, dynamic>> b,
  ) {
    final aName = a.data()['name'] as String? ?? '';
    final bName = b.data()['name'] as String? ?? '';
    return aName.compareTo(bName);
  }
}
