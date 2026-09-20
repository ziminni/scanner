part of '../sections_page.dart';

class _SectionsByGrade extends StatefulWidget {
  const _SectionsByGrade({required this.search});

  final String search;

  @override
  State<_SectionsByGrade> createState() => _SectionsByGradeState();
}

class _SectionsByGradeState extends State<_SectionsByGrade> {
  String? _selectedGrade;
  final Set<String> _selectedSectionIds = {};
  bool _bulkBusy = false;
  SchoolAdminViewModel? _app;
  Future<SchoolYear?>? _activeSchoolYearFuture;
  Stream<QuerySnapshot<Map<String, dynamic>>>? _sectionsStream;
  final Map<String, Stream<QuerySnapshot<Map<String, dynamic>>>>
  _studentStreams = {};

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_app != null) return;
    final app = SchoolAdminViewModelScope.of(context);
    _app = app;
    _activeSchoolYearFuture = app.attendance.activeSchoolYear();
    _sectionsStream = app.repository.activeSectionsStream();
  }

  @override
  Widget build(BuildContext context) {
    final app = _app!;
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _sectionsStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const AdminCardGridSkeleton();
        }
        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) {
          return const EmptyState(title: 'No sections records yet');
        }
        return FutureBuilder<SchoolYear?>(
          future: _activeSchoolYearFuture,
          builder: (context, schoolYearSnapshot) {
            if (schoolYearSnapshot.connectionState == ConnectionState.waiting) {
              return const AdminCardGridSkeleton();
            }
            final schoolYear = schoolYearSnapshot.data;
            if (schoolYear == null) {
              return _buildContent(context, docs, const []);
            }
            return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _studentStreams.putIfAbsent(
                schoolYear.id,
                () => app.repository
                    .schoolYearCollection(schoolYear.id, 'students')
                    .where('archived', isEqualTo: false)
                    .snapshots(),
              ),
              builder: (context, studentsSnapshot) {
                if (studentsSnapshot.connectionState ==
                    ConnectionState.waiting) {
                  return const AdminCardGridSkeleton();
                }
                return _buildContent(
                  context,
                  docs,
                  studentsSnapshot.data?.docs ?? const [],
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildContent(
    BuildContext context,
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
    List<QueryDocumentSnapshot<Map<String, dynamic>>> students,
  ) {
    final studentCounts = <String, int>{};
    for (final student in students) {
      final sectionKey = _normalizedSectionKey(
        student.data()['section'] as String? ?? '',
      );
      if (sectionKey.isNotEmpty) {
        studentCounts.update(
          sectionKey,
          (current) => current + 1,
          ifAbsent: () => 1,
        );
      }
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
    final selectedGrade = gradeLevels.contains(_selectedGrade)
        ? _selectedGrade!
        : gradeLevels.first;
    _selectedGrade = selectedGrade;

    final query = widget.search.trim().toLowerCase();
    final gradeDocs = grouped[selectedGrade]!..sort(_sectionSort);
    final filteredDocs = gradeDocs.where((doc) {
      if (query.isEmpty) return true;
      final data = doc.data();
      return '${data['name']} ${data['gradeLevel']} ${data['adviser']}'
          .toLowerCase()
          .contains(query);
    }).toList();
    final allSectionIds = docs.map((doc) => doc.id).toSet();
    _selectedSectionIds.removeWhere((id) => !allSectionIds.contains(id));
    final selectedVisibleCount = filteredDocs
        .where((doc) => _selectedSectionIds.contains(doc.id))
        .length;
    final allVisibleSelected =
        filteredDocs.isNotEmpty && selectedVisibleCount == filteredDocs.length;
    final selectedDocs = docs
        .where((doc) => _selectedSectionIds.contains(doc.id))
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (final gradeLevel in gradeLevels) ...[
                _GradeTab(
                  label: _gradeLabel(gradeLevel),
                  count: grouped[gradeLevel]!.length,
                  selected: gradeLevel == selectedGrade,
                  onTap: () => setState(() => _selectedGrade = gradeLevel),
                ),
                if (gradeLevel != gradeLevels.last) const SizedBox(width: 8),
              ],
            ],
          ),
        ),
        const SizedBox(height: 14),
        DataSurface(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(4, 2, 4, 10),
                child: _SectionToolbar(
                  selectedCount: selectedDocs.length,
                  busy: _bulkBusy,
                  onAdd: () => showDialog<void>(
                    context: context,
                    builder: (_) => const _AddSectionDialog(),
                  ),
                  onEdit: selectedDocs.length == 1
                      ? () {
                          final section = selectedDocs.single;
                          showDialog<void>(
                            context: context,
                            builder: (_) => _EditSectionDialog(
                              docId: section.id,
                              data: section.data(),
                            ),
                          );
                        }
                      : null,
                  onDownload: selectedDocs.isEmpty
                      ? null
                      : () => _downloadSelectedQr(context, selectedDocs),
                  onDelete: selectedDocs.isEmpty
                      ? null
                      : () => _confirmDeleteSelected(context, selectedDocs),
                ),
              ),
              _SectionsTableHeader(
                value: allVisibleSelected
                    ? true
                    : selectedVisibleCount > 0
                    ? null
                    : false,
                onChanged: (selected) =>
                    _setVisibleSelected(filteredDocs, selected == true),
              ),
              if (filteredDocs.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 32),
                  child: EmptyState(title: 'No sections found'),
                )
              else
                for (var index = 0; index < filteredDocs.length; index++) ...[
                  if (index > 0)
                    Divider(
                      height: 1,
                      color: Theme.of(context).colorScheme.outlineVariant,
                    ),
                  _buildSectionRow(context, filteredDocs[index], studentCounts),
                ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSectionRow(
    BuildContext context,
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
    Map<String, int> studentCounts,
  ) {
    final name = doc.data()['name'] as String? ?? '';
    return _SectionCard(
      data: doc.data(),
      studentCount: studentCounts[_normalizedSectionKey(name)] ?? 0,
      selected: _selectedSectionIds.contains(doc.id),
      onSelected: (selected) => setState(() {
        if (selected) {
          _selectedSectionIds.add(doc.id);
        } else {
          _selectedSectionIds.remove(doc.id);
        }
      }),
      onOpen: () => showDialog<void>(
        context: context,
        builder: (_) => _SectionDetailsDialog(section: doc.data()),
      ),
    );
  }

  void _setVisibleSelected(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
    bool selected,
  ) {
    setState(() {
      for (final doc in docs) {
        if (selected) {
          _selectedSectionIds.add(doc.id);
        } else {
          _selectedSectionIds.remove(doc.id);
        }
      }
    });
  }

  Future<void> _downloadSelectedQr(
    BuildContext context,
    List<QueryDocumentSnapshot<Map<String, dynamic>>> selectedDocs,
  ) async {
    final app = SchoolAdminViewModelScope.of(context);
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _bulkBusy = true);
    var downloaded = 0;
    final failures = <String>[];
    try {
      final exporter = SectionQrExporter(app.app);
      for (final doc in selectedDocs) {
        final name = doc.data()['name'] as String? ?? 'Section';
        try {
          await exporter.downloadSectionZip(doc.data());
          downloaded++;
        } catch (_) {
          failures.add(name);
        }
      }
      if (!mounted) return;
      final message = failures.isEmpty
          ? '$downloaded section QR ZIP${downloaded == 1 ? '' : 's'} downloaded.'
          : '$downloaded downloaded. No active students found in: ${failures.join(', ')}.';
      messenger.showSnackBar(SnackBar(content: Text(message)));
    } finally {
      if (mounted) setState(() => _bulkBusy = false);
    }
  }

  Future<void> _confirmDeleteSelected(
    BuildContext context,
    List<QueryDocumentSnapshot<Map<String, dynamic>>> selectedDocs,
  ) async {
    final names = selectedDocs
        .map((doc) => (doc.data()['name'] as String? ?? '').trim())
        .where((name) => name.isNotEmpty)
        .toList();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          'Delete ${selectedDocs.length} section${selectedDocs.length == 1 ? '' : 's'}?',
        ),
        content: Text(
          'This permanently deletes ${names.join(', ')} and unassigns active students in the selected sections. This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(dialogContext).colorScheme.error,
              foregroundColor: Theme.of(dialogContext).colorScheme.onError,
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
            icon: const Icon(Icons.delete_outline),
            label: const Text('Delete permanently'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    await _deleteSelectedSections(selectedDocs);
  }

  Future<void> _deleteSelectedSections(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> selectedDocs,
  ) async {
    final app = SchoolAdminViewModelScope.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final selectedNames = {
      for (final doc in selectedDocs)
        _normalizedSectionKey(doc.data()['name'] as String? ?? ''):
            (doc.data()['name'] as String? ?? '').trim(),
    }..remove('');
    setState(() => _bulkBusy = true);
    var unassignedCount = 0;
    try {
      final schoolYear = await app.attendance.activeSchoolYear();
      if (schoolYear != null && selectedNames.isNotEmpty) {
        final students = await app.repository
            .schoolYearCollection(schoolYear.id, 'students')
            .where('archived', isEqualTo: false)
            .get();
        var batch = app.firestore.batch();
        var writes = 0;
        for (final student in students.docs) {
          final sectionName = student.data()['section'] as String? ?? '';
          final sectionKey = _normalizedSectionKey(sectionName);
          if (!selectedNames.containsKey(sectionKey)) continue;
          batch.set(student.reference, {
            'section': '',
            'previousSection': sectionName,
            'sectionUnassignedAt': FieldValue.serverTimestamp(),
            'sectionUnassignedReason': 'section_deleted',
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
      }

      var deleteBatch = app.firestore.batch();
      var deleteWrites = 0;
      for (final section in selectedDocs) {
        deleteBatch.delete(section.reference);
        deleteWrites++;
        if (deleteWrites == 450) {
          await deleteBatch.commit();
          deleteBatch = app.firestore.batch();
          deleteWrites = 0;
        }
      }
      if (deleteWrites > 0) await deleteBatch.commit();

      await app.audit.record(
        action: 'sections_bulk_deleted',
        actorId: app.currentUser!.id,
        actorName: app.currentUser!.fullName,
        target: '${selectedDocs.length} sections',
        metadata: {
          'sectionNames': selectedNames.values.toList(),
          'studentsUnassigned': unassignedCount,
        },
      );
      if (!mounted) return;
      setState(_selectedSectionIds.clear);
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            '${selectedDocs.length} section${selectedDocs.length == 1 ? '' : 's'} deleted. $unassignedCount student${unassignedCount == 1 ? '' : 's'} unassigned.',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text('Could not delete sections: $error')),
      );
    } finally {
      if (mounted) setState(() => _bulkBusy = false);
    }
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
}

String _normalizedSectionKey(String value) {
  return value.trim().replaceAll(RegExp(r'\s+'), ' ').toLowerCase();
}
