part of '../sections_page.dart';

class _SectionDetailsDialog extends StatefulWidget {
  const _SectionDetailsDialog({required this.section});

  final Map<String, dynamic> section;

  @override
  State<_SectionDetailsDialog> createState() => _SectionDetailsDialogState();
}

class _SectionDetailsDialogState extends State<_SectionDetailsDialog> {
  final _search = TextEditingController();
  String _genderFilter = '';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final app = SchoolAdminViewModelScope.of(context);
    final sectionName = widget.section['name'] as String? ?? '';
    final gradeLevel = widget.section['gradeLevel'] as String? ?? '';

    return AlertDialog(
      title: Text(sectionName.isEmpty ? 'Section Details' : sectionName),
      content: SizedBox(
        width: 640,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DataSurface(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Wrap(
                  spacing: 24,
                  runSpacing: 12,
                  children: [
                    _DetailMetric(
                      label: 'Section',
                      value: sectionName.isEmpty ? '-' : sectionName,
                    ),
                    _DetailMetric(
                      label: 'Grade Level',
                      value: gradeLevel.isEmpty ? '-' : gradeLevel,
                    ),
                    _SectionDetailsAdviserMetric(section: widget.section),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
            LayoutBuilder(
              builder: (context, constraints) {
                final compact = constraints.maxWidth < 520;
                final searchField = TextField(
                  controller: _search,
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.search),
                    labelText: 'Search students',
                  ),
                  onChanged: (_) => setState(() {}),
                );
                final genderFilter = GenderDropdownField(
                  value: _genderFilter,
                  includeAll: true,
                  onChanged: (value) {
                    setState(() => _genderFilter = value ?? '');
                  },
                );

                if (compact) {
                  return Column(
                    children: [
                      searchField,
                      const SizedBox(height: 10),
                      genderFilter,
                    ],
                  );
                }
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: searchField),
                    const SizedBox(width: 12),
                    SizedBox(width: 180, child: genderFilter),
                  ],
                );
              },
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 360,
              child: FutureBuilder(
                future: app.attendance.activeSchoolYear(),
                builder: (context, schoolYearSnapshot) {
                  final schoolYear = schoolYearSnapshot.data;
                  if (schoolYear == null) {
                    return const EmptyState(
                      title: 'Create an active school year first',
                    );
                  }

                  return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                    stream: app.repository.studentsBySectionStream(
                      schoolYearId: schoolYear.id,
                      sectionName: sectionName,
                    ),
                    builder: (context, snapshot) {
                      final query = _search.text.trim().toLowerCase();
                      final students =
                          (snapshot.data?.docs ?? [])
                              .map((doc) => doc.data())
                              .where((student) {
                                final gender = _text(student['gender']);
                                if (_genderFilter.isNotEmpty &&
                                    gender.toLowerCase() !=
                                        _genderFilter.toLowerCase()) {
                                  return false;
                                }
                                return query.isEmpty ||
                                    _studentDisplayName(
                                      student,
                                    ).toLowerCase().contains(query);
                              })
                              .toList()
                            ..sort(_studentSort);

                      if (students.isEmpty) {
                        return const EmptyState(
                          title: 'No students found in this section',
                        );
                      }

                      return ListView.separated(
                        itemCount: students.length,
                        separatorBuilder: (_, _) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          return ListTile(
                            dense: true,
                            title: Text(
                              '${index + 1}. ${_studentDisplayName(students[index])}',
                            ),
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ],
    );
  }

  int _studentSort(Map<String, dynamic> a, Map<String, dynamic> b) {
    final lastCompare = _text(a['lastName']).compareTo(_text(b['lastName']));
    if (lastCompare != 0) return lastCompare;
    final firstCompare = _text(a['firstName']).compareTo(_text(b['firstName']));
    if (firstCompare != 0) return firstCompare;
    return _text(a['middleName']).compareTo(_text(b['middleName']));
  }

  String _studentDisplayName(Map<String, dynamic> student) {
    final lastName = _text(student['lastName']);
    final firstName = _text(student['firstName']);
    final middleName = _text(student['middleName']);
    final middleInitial = middleName.isEmpty ? '' : ' ${middleName[0]}.';
    return '$lastName, $firstName$middleInitial'.trim();
  }

  String _text(Object? value) => (value as String? ?? '').trim();
}

class _SectionDetailsAdviserMetric extends StatelessWidget {
  const _SectionDetailsAdviserMetric({required this.section});

  final Map<String, dynamic> section;

  @override
  Widget build(BuildContext context) {
    final app = SchoolAdminViewModelScope.of(context);
    final adviserDocId = (section['adviserDocId'] as String? ?? '').trim();
    if (adviserDocId.isEmpty) {
      return const _DetailMetric(label: 'Adviser', value: 'No adviser');
    }

    return FutureBuilder(
      future: app.attendance.activeSchoolYear(),
      builder: (context, schoolYearSnapshot) {
        final schoolYear = schoolYearSnapshot.data;
        if (schoolYear == null) {
          return const _DetailMetric(label: 'Adviser', value: 'No adviser');
        }

        return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: app.repository
              .schoolYearCollection(schoolYear.id, 'teachers')
              .doc(adviserDocId)
              .snapshots(),
          builder: (context, snapshot) {
            final data = snapshot.data?.data();
            if (data == null || data['archived'] == true) {
              return const _DetailMetric(label: 'Adviser', value: 'No adviser');
            }
            final name = [
              data['lastName'] as String? ?? '',
              data['firstName'] as String? ?? '',
              data['middleName'] as String? ?? '',
            ].where((part) => part.trim().isNotEmpty).join(', ');
            final adviserText = _SectionCard.formatAdviserName(name);
            return _DetailMetric(
              label: 'Adviser',
              value: adviserText.isEmpty ? 'No adviser' : adviserText,
            );
          },
        );
      },
    );
  }
}
