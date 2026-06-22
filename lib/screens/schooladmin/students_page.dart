import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../shared/widgets/admin.dart';
import '../../shared/widgets/form_fields.dart';
import '../../shared/widgets/gender_dropdown_field.dart';
import 'viewmodels/import_students_viewmodel.dart';
import 'viewmodels/students_viewmodel.dart';
import 'viewmodels/school_admin_viewmodel.dart';

part 'widgets/students_filter_bar.dart';
part 'widgets/unassigned_students_notice.dart';
part 'widgets/students_filter_select.dart';

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
  String _genderFilter = '';

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
                'gender',
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
            stream: SchoolAdminViewModelScope.of(
              context,
            ).repository.activeSectionsStream(),
            builder: (context, snapshot) {
              final sections =
                  (snapshot.data?.docs ?? [])
                      .map((doc) => doc.data()['name'] as String? ?? '')
                      .where((name) => name.trim().isNotEmpty)
                      .toSet()
                      .toList()
                    ..sort();
              final sectionOptions = ['Unassigned', ...sections];
              if (_sectionFilter.isNotEmpty &&
                  !sectionOptions.contains(_sectionFilter)) {
                _sectionFilter = '';
              }

              return _StudentsFilterBar(
                search: _search,
                sectionFilter: _sectionFilter,
                genderFilter: _genderFilter,
                sections: sectionOptions,
                onSearchChanged: () => setState(() {}),
                onSectionChanged: (value) =>
                    setState(() => _sectionFilter = value),
                onGenderChanged: (value) =>
                    setState(() => _genderFilter = value),
              );
            },
          ),
          const SizedBox(height: 12),
          _UnassignedStudentsNotice(
            onView: () => setState(() => _sectionFilter = 'Unassigned'),
          ),
          const SizedBox(height: 12),
          CollectionTable(
            collection: 'students',
            columns: studentTableFields,
            schoolYearScoped: true,
            confirmArchive: true,
            enableBulkArchive: true,
            showArchiveAction: false,
            teacherTableStyle: true,
            itemLabel: 'students',
            columnLabels: const {
              'lrn': 'LRN',
              'fullName': 'Name',
              'guardianName': 'Guardian',
              'guardianContact': 'Guardian Contact',
            },
            search: _search.text,
            filters: {
              if (_sectionFilter.isNotEmpty) 'section': _sectionFilter,
              if (_genderFilter.isNotEmpty) 'gender': _genderFilter,
            },
            onRowTap: (context, _, data, _) => showDialog<void>(
              context: context,
              builder: (_) => RecordDetailsDialog(
                title: 'Student Details',
                data: data,
                columns: studentTableFields,
              ),
            ),
            onEdit: _openEditStudentDialog,
          ),
        ],
      ),
    );
  }
}
