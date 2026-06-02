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
          SizedBox(
            width: 380,
            child: TextField(
              controller: _search,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                labelText: 'Search student name, LRN, section',
              ),
              onChanged: (_) => setState(() {}),
            ),
          ),
          const SizedBox(height: 12),
          CollectionTable(
            collection: 'students',
            columns: studentTableFields,
            schoolYearScoped: true,
            search: _search.text,
            onEdit: _openEditStudentDialog,
          ),
        ],
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
