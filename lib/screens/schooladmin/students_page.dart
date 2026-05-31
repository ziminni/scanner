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

class StudentsPage extends StatelessWidget {
  const StudentsPage({super.key});

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
      child: const CollectionTable(
        collection: 'students',
        columns: studentTableFields,
        schoolYearScoped: true,
        onEdit: _openEditStudentDialog,
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
