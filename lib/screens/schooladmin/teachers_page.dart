import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/services/app_controller.dart';
import '../../shared/widgets/admin_widgets.dart';
import '../../shared/widgets/app_widgets.dart';
import '../../shared/widgets/form_fields.dart';
import 'viewmodels/crud_viewmodel.dart';
import 'viewmodels/import_teachers_viewmodel.dart';

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
            onSearchChanged: () => setState(() {}),
            onScheduleChanged: (value) =>
                setState(() => _scheduleFilter = value),
          ),
          const SizedBox(height: 12),
          _TeachersTable(search: _search.text, scheduleFilter: _scheduleFilter),
        ],
      ),
    );
  }
}

class _TeachersFilterBar extends StatelessWidget {
  const _TeachersFilterBar({
    required this.search,
    required this.scheduleFilter,
    required this.onSearchChanged,
    required this.onScheduleChanged,
  });

  final TextEditingController search;
  final String scheduleFilter;
  final VoidCallback onSearchChanged;
  final ValueChanged<String> onScheduleChanged;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 560;
        final searchWidth = compact
            ? constraints.maxWidth
            : (constraints.maxWidth - 172).clamp(360.0, 720.0).toDouble();
        return SizedBox(
          width: constraints.maxWidth,
          child: Wrap(
            spacing: 12,
            runSpacing: 12,
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              SizedBox(
                width: searchWidth,
                child: TextField(
                  controller: search,
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.search),
                    labelText: 'Search teacher name, ID, or contact',
                  ),
                  onChanged: (_) => onSearchChanged(),
                ),
              ),
              SizedBox(
                width: 160,
                child: DropdownButtonFormField<String>(
                  initialValue: scheduleFilter,
                  decoration: const InputDecoration(labelText: 'Schedule'),
                  items: const [
                    DropdownMenuItem(value: '', child: Text('All')),
                    DropdownMenuItem(
                      value: '07:00 - 16:00',
                      child: Text('07:00 - 16:00'),
                    ),
                    DropdownMenuItem(
                      value: '07:30 - 16:30',
                      child: Text('07:30 - 16:30'),
                    ),
                  ],
                  onChanged: (value) => onScheduleChanged(value ?? ''),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
