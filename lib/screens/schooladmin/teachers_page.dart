import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/models.dart';
import '../../shared/widgets/admin.dart';
import '../../shared/widgets/app_widgets.dart';
import '../../shared/widgets/form_fields.dart';
import '../../shared/widgets/gender_dropdown_field.dart';
import 'viewmodels/crud_viewmodel.dart';
import 'viewmodels/import_teachers_viewmodel.dart';
import 'viewmodels/school_admin_viewmodel.dart';

part 'widgets/teachers_filter_bar.dart';

part 'widgets/teachers_table.dart';
part 'widgets/import_teachers_dialog.dart';
part 'widgets/add_teacher_dialog.dart';
part 'widgets/edit_teacher_dialog.dart';

class TeachersPage extends StatefulWidget {
  const TeachersPage({super.key});

  static const fields = [
    'teacherId',
    'lastName',
    'firstName',
    'middleName',
    'gender',
    'birthdate',
    'address',
    'contactNumber',
    'assignedTimeIn',
    'assignedTimeOut',
    'status',
  ];

  @override
  State<TeachersPage> createState() => _TeachersPageState();
}

class _TeachersPageState extends State<TeachersPage> {
  final _search = TextEditingController();
  String _scheduleFilter = '';
  String _genderFilter = '';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AdminPage(
      title: 'Teachers',
      actions: [
        OutlinedButton.icon(
          icon: const Icon(Icons.archive_outlined),
          label: const Text('Archives'),
          onPressed: () => showDialog<void>(
            context: context,
            builder: (_) => const ArchivedRecordsDialog(
              title: 'Archived Teachers',
              collection: 'teachers',
              schoolYearScoped: true,
              columns: [
                'teacherId',
                'fullName',
                'gender',
                'birthdate',
                'address',
                'contactNumber',
                'archivedAt',
              ],
            ),
          ),
        ),
        OutlinedButton.icon(
          icon: const Icon(Icons.upload_file_outlined),
          label: const Text('Import teachers'),
          onPressed: () => showDialog<void>(
            context: context,
            builder: (_) => const _ImportTeachersDialog(),
          ),
        ),
        FilledButton.icon(
          icon: const Icon(Icons.add),
          label: const Text('Add teacher'),
          onPressed: () => showDialog<void>(
            context: context,
            builder: (_) => const _AddTeacherDialog(),
          ),
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _TeachersFilterBar(
            search: _search,
            scheduleFilter: _scheduleFilter,
            genderFilter: _genderFilter,
            onSearchChanged: () => setState(() {}),
            onScheduleChanged: (value) =>
                setState(() => _scheduleFilter = value),
            onGenderChanged: (value) => setState(() => _genderFilter = value),
          ),
          const SizedBox(height: 12),
          _TeachersTable(
            search: _search.text,
            scheduleFilter: _scheduleFilter,
            genderFilter: _genderFilter,
          ),
        ],
      ),
    );
  }
}
