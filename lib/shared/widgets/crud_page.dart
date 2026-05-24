import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../core/services/app_controller.dart';
import '../../viewmodels/crud_viewmodel.dart';
import 'admin_widgets.dart';
import 'form_fields.dart';

class CrudPage extends StatefulWidget {
  const CrudPage({
    super.key,
    required this.title,
    required this.collection,
    required this.fields,
  });

  final String title;
  final String collection;
  final List<String> fields;

  @override
  State<CrudPage> createState() => CrudPageState();
}

class CrudPageState extends State<CrudPage> {
  late final CrudViewModel _viewModel;
  bool _viewModelReady = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_viewModelReady) return;
    _viewModel = CrudViewModel(
      app: AppScope.of(context),
      collection: widget.collection,
      fields: widget.fields,
    );
    _viewModelReady = true;
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _viewModel,
      builder: (context, _) {
        return AdminPage(
          title: widget.title,
          actions: [
            OutlinedButton.icon(
              icon: const Icon(Icons.download_outlined),
              label: const Text('Template'),
              onPressed: () {},
            ),
            FilledButton.icon(
              icon: const Icon(Icons.add),
              label: const Text('Add'),
              onPressed: _viewModel.busy ? null : _viewModel.addRecord,
            ),
          ],
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  for (final entry in _viewModel.controllers.entries)
                    SizedBox(width: 220, child: _fieldInput(entry)),
                  if (widget.fields.contains('adviser'))
                    SizedBox(
                      width: 220,
                      child: _AdviserDropdown(
                        selected: _viewModel.selectedAdviser,
                        onChanged: _viewModel.setAdviser,
                      ),
                    ),
                  if (widget.fields.contains('assignedTimeIn'))
                    SizedBox(
                      width: 220,
                      child: TimePickerField(
                        label: 'Assigned Time In',
                        value: _viewModel.assignedTimeIn,
                        fallback: const TimeOfDay(hour: 7, minute: 0),
                        onChanged: _viewModel.setAssignedTimeIn,
                      ),
                    ),
                  if (widget.fields.contains('assignedTimeOut'))
                    SizedBox(
                      width: 220,
                      child: TimePickerField(
                        label: 'Assigned Time Out',
                        value: _viewModel.assignedTimeOut,
                        fallback: const TimeOfDay(hour: 17, minute: 0),
                        onChanged: _viewModel.setAssignedTimeOut,
                      ),
                    ),
                ],
              ),
              if (_viewModel.error != null) ...[
                const SizedBox(height: 12),
                Text(
                  _viewModel.error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],
              const SizedBox(height: 16),
              CollectionTable(
                collection: widget.collection,
                columns: widget.fields,
                schoolYearScoped: true,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _fieldInput(MapEntry<String, TextEditingController> entry) {
    if (entry.key == 'birthdate') {
      return BirthdateField(
        value: _viewModel.birthdate,
        onChanged: _viewModel.setBirthdate,
      );
    }
    return TextField(
      controller: entry.value,
      decoration: InputDecoration(labelText: adminLabel(entry.key)),
    );
  }
}

class _AdviserDropdown extends StatelessWidget {
  const _AdviserDropdown({required this.selected, required this.onChanged});

  final TeacherOption? selected;
  final ValueChanged<TeacherOption?> onChanged;

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: (() async* {
        final schoolYear = await app.attendance.activeSchoolYear();
        if (schoolYear == null) return;
        yield* app.firestore
            .collection('school_years')
            .doc(schoolYear.id)
            .collection('teachers')
            .where('archived', isEqualTo: false)
            .snapshots();
      })(),
      builder: (context, snapshot) {
        final teachers = (snapshot.data?.docs ?? []).map((doc) {
          final data = doc.data();
          final firstName = data['firstName'] as String? ?? '';
          final middleName = data['middleName'] as String? ?? '';
          final lastName = data['lastName'] as String? ?? '';
          final name = [
            lastName,
            firstName,
            middleName,
          ].where((part) => part.trim().isNotEmpty).join(', ');
          return TeacherOption(
            docId: doc.id,
            teacherId: data['teacherId'] as String? ?? doc.id,
            name: name.isEmpty ? data['teacherId'] as String? ?? doc.id : name,
          );
        }).toList()..sort((a, b) => a.name.compareTo(b.name));

        final selectedTeacher = teachers.where((teacher) {
          return teacher.docId == selected?.docId;
        }).firstOrNull;

        return DropdownButtonFormField<TeacherOption>(
          initialValue: selectedTeacher,
          decoration: const InputDecoration(labelText: 'Adviser'),
          hint: const Text('Select teacher'),
          items: [
            for (final teacher in teachers)
              DropdownMenuItem(value: teacher, child: Text(teacher.name)),
          ],
          onChanged: teachers.isEmpty ? null : onChanged,
        );
      },
    );
  }
}
