part of '../students_page.dart';

class _TransferSectionResult {
  const _TransferSectionResult({
    required this.section,
    required this.studentIds,
  });

  final String section;
  final List<String> studentIds;
}

class _TransferStudentsSectionDialog extends StatefulWidget {
  const _TransferStudentsSectionDialog({required this.students});

  final List<TransferStudentInfo> students;

  @override
  State<_TransferStudentsSectionDialog> createState() =>
      _TransferStudentsSectionDialogState();
}

class _TransferStudentsSectionDialogState
    extends State<_TransferStudentsSectionDialog> {
  String? _selectedSection;
  late final Set<String> _selectedStudentIds;

  @override
  void initState() {
    super.initState();
    _selectedStudentIds = widget.students.map((student) => student.id).toSet();
  }

  @override
  Widget build(BuildContext context) {
    final app = SchoolAdminViewModelScope.of(context);
    return AlertDialog(
      title: const Text('Transfer student/s section'),
      content: SizedBox(
        width: 520,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Selected students',
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            Text(
              '${_selectedStudentIds.length} of ${widget.students.length} selected',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 8),
            Flexible(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 260),
                child: Material(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                  child: ListView.separated(
                    shrinkWrap: true,
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    itemCount: widget.students.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final student = widget.students[index];
                      final selected = _selectedStudentIds.contains(student.id);
                      final subtitleParts = [
                        if (student.lrn.isNotEmpty) 'LRN: ${student.lrn}',
                        if (student.section.isNotEmpty)
                          'Current: ${student.section}'
                        else
                          'Current: Unassigned',
                      ];
                      return CheckboxListTile(
                        dense: true,
                        value: selected,
                        controlAffinity: ListTileControlAffinity.leading,
                        onChanged: (value) {
                          setState(() {
                            if (value ?? false) {
                              _selectedStudentIds.add(student.id);
                            } else {
                              _selectedStudentIds.remove(student.id);
                            }
                          });
                        },
                        title: Text(student.name),
                        subtitle: Text(subtitleParts.join(' • ')),
                      );
                    },
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: app.repository.activeSectionsStream(),
              builder: (context, snapshot) {
                final sectionNames =
                    (snapshot.data?.docs ?? [])
                        .map((doc) => doc.data()['name'] as String? ?? '')
                        .where((name) => name.trim().isNotEmpty)
                        .toSet()
                        .toList()
                      ..sort();

                if (_selectedSection != null &&
                    !sectionNames.contains(_selectedSection)) {
                  _selectedSection = null;
                }

                return DropdownButtonFormField<String>(
                  initialValue: _selectedSection,
                  decoration: const InputDecoration(
                    labelText: 'Transfer to section',
                  ),
                  hint: const Text('Select section'),
                  items: [
                    for (final section in sectionNames)
                      DropdownMenuItem(value: section, child: Text(section)),
                  ],
                  onChanged: sectionNames.isEmpty
                      ? null
                      : (section) => setState(() => _selectedSection = section),
                );
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton.icon(
          icon: const Icon(Icons.meeting_room_outlined),
          label: const Text('Transfer section'),
          onPressed: _selectedSection == null || _selectedStudentIds.isEmpty
              ? null
              : () => Navigator.of(context).pop(
                  _TransferSectionResult(
                    section: _selectedSection!,
                    studentIds: _selectedStudentIds.toList(),
                  ),
                ),
        ),
      ],
    );
  }
}
