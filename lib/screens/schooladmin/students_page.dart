import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../core/services/app_controller.dart';
import '../../shared/widgets/admin_widgets.dart';
import '../../shared/widgets/form_fields.dart';
import 'viewmodels/import_students_viewmodel.dart';
import 'viewmodels/students_viewmodel.dart';

part 'widgets/add_student_dialog.dart';
part 'widgets/import_students_dialog.dart';
part 'widgets/edit_student_dialog.dart';

class StudentsPage extends StatefulWidget {
  const StudentsPage({super.key});

  @override
  State<StudentsPage> createState() => _StudentsPageState();
}

class _StudentsPageState extends State<StudentsPage> {
  final _search = TextEditingController();
  String _sectionFilter = '';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AdminPage(
      title: 'Students',
      actions: [
        OutlinedButton.icon(
          icon: const Icon(Icons.archive_outlined),
          label: const Text('Archives'),
          onPressed: () => showDialog<void>(
            context: context,
            builder: (_) => const ArchivedRecordsDialog(
              title: 'Archived Students',
              collection: 'students',
              schoolYearScoped: true,
              columns: [
                'lrn',
                'fullName',
                'birthdate',
                'section',
                'archivedAt',
              ],
            ),
          ),
        ),
        OutlinedButton.icon(
          icon: const Icon(Icons.upload_file_outlined),
          label: const Text('Import students'),
          onPressed: () => showDialog<void>(
            context: context,
            builder: (_) => const _ImportStudentsDialog(),
          ),
        ),
        FilledButton.icon(
          icon: const Icon(Icons.add),
          label: const Text('Add student'),
          onPressed: () => showDialog<void>(
            context: context,
            builder: (_) => const _AddStudentDialog(),
          ),
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: AppScope.of(context).repository.activeSectionsStream(),
            builder: (context, snapshot) {
              final sections =
                  (snapshot.data?.docs ?? [])
                      .map((doc) => doc.data()['name'] as String? ?? '')
                      .where((name) => name.trim().isNotEmpty)
                      .toSet()
                      .toList()
                    ..sort();
              if (_sectionFilter.isNotEmpty &&
                  !sections.contains(_sectionFilter)) {
                _sectionFilter = '';
              }

              return LayoutBuilder(
                builder: (context, constraints) {
                  final searchWidth = (constraints.maxWidth - 192)
                      .clamp(360.0, 720.0)
                      .toDouble();
                  return Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      SizedBox(
                        width: searchWidth,
                        child: TextField(
                          controller: _search,
                          decoration: const InputDecoration(
                            prefixIcon: Icon(Icons.search),
                            labelText: 'Search student name, LRN, section',
                          ),
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                      _FilterSelect(
                        label: 'Section',
                        value: _sectionFilter,
                        options: sections,
                        onChanged: (value) =>
                            setState(() => _sectionFilter = value),
                      ),
                    ],
                  );
                },
              );
            },
          ),
          const SizedBox(height: 12),
          CollectionTable(
            collection: 'students',
            columns: studentTableFields,
            schoolYearScoped: true,
            search: _search.text,
            filters: {if (_sectionFilter.isNotEmpty) 'section': _sectionFilter},
            onEdit: _openEditStudentDialog,
          ),
        ],
      ),
    );
  }
}

class _FilterSelect extends StatelessWidget {
  const _FilterSelect({
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
  });

  final String label;
  final String value;
  final List<String> options;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final displayValue = value.isEmpty || options.contains(value) ? value : '';
    return SizedBox(
      width: 180,
      child: DropdownButtonFormField<String>(
        initialValue: displayValue,
        decoration: InputDecoration(labelText: label),
        items: [
          const DropdownMenuItem(value: '', child: Text('All')),
          for (final option in options)
            DropdownMenuItem(value: option, child: Text(option)),
        ],
        onChanged: (next) => onChanged(next ?? ''),
      ),
    );
  }
}

void _openEditStudentDialog(
  BuildContext context,
  String docId,
  Map<String, dynamic> data,
  String? schoolYearId,
) {
  if (schoolYearId == null) return;
  showDialog<void>(
    context: context,
    builder: (_) => _EditStudentDialog(
      schoolYearId: schoolYearId,
      docId: docId,
      data: data,
    ),
  );
}
