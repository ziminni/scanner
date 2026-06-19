import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../core/services/app_controller.dart';
import '../../shared/widgets/admin_widgets.dart';
import '../../shared/widgets/form_fields.dart';
import '../../shared/widgets/gender_dropdown_field.dart';
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
            stream: AppScope.of(context).repository.activeSectionsStream(),
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
            search: _search.text,
            filters: {
              if (_sectionFilter.isNotEmpty) 'section': _sectionFilter,
              if (_genderFilter.isNotEmpty) 'gender': _genderFilter,
            },
            onEdit: _openEditStudentDialog,
          ),
        ],
      ),
    );
  }
}

class _StudentsFilterBar extends StatelessWidget {
  const _StudentsFilterBar({
    required this.search,
    required this.sectionFilter,
    required this.genderFilter,
    required this.sections,
    required this.onSearchChanged,
    required this.onSectionChanged,
    required this.onGenderChanged,
  });

  final TextEditingController search;
  final String sectionFilter;
  final String genderFilter;
  final List<String> sections;
  final VoidCallback onSearchChanged;
  final ValueChanged<String> onSectionChanged;
  final ValueChanged<String> onGenderChanged;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 760;
        final searchWidth = compact
            ? constraints.maxWidth
            : (constraints.maxWidth - 372).clamp(320.0, 720.0).toDouble();
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
                    labelText: 'Search student name, LRN, section',
                  ),
                  onChanged: (_) => onSearchChanged(),
                ),
              ),
              _FilterSelect(
                label: 'Section',
                value: sectionFilter,
                options: sections,
                onChanged: onSectionChanged,
              ),
              SizedBox(
                width: 180,
                child: GenderDropdownField(
                  value: genderFilter,
                  includeAll: true,
                  onChanged: (value) => onGenderChanged(value ?? ''),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _UnassignedStudentsNotice extends StatelessWidget {
  const _UnassignedStudentsNotice({required this.onView});

  final VoidCallback onView;

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final theme = Theme.of(context);
    return FutureBuilder(
      future: app.attendance.activeSchoolYear(),
      builder: (context, schoolYearSnapshot) {
        final schoolYear = schoolYearSnapshot.data;
        if (schoolYear == null) return const SizedBox.shrink();

        return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: app.repository
              .schoolYearCollection(schoolYear.id, 'students')
              .where('archived', isEqualTo: false)
              .snapshots(),
          builder: (context, snapshot) {
            final unassignedCount = (snapshot.data?.docs ?? []).where((doc) {
              final section = (doc.data()['section'] as String? ?? '').trim();
              return section.isEmpty;
            }).length;
            if (unassignedCount == 0) return const SizedBox.shrink();

            return Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: theme.colorScheme.errorContainer.withAlpha(95),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: theme.colorScheme.error.withAlpha(70),
                ),
              ),
              child: Wrap(
                spacing: 12,
                runSpacing: 10,
                crossAxisAlignment: WrapCrossAlignment.center,
                alignment: WrapAlignment.spaceBetween,
                children: [
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 720),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.warning_amber_outlined,
                          color: theme.colorScheme.error,
                        ),
                        const SizedBox(width: 10),
                        Flexible(
                          child: Text(
                            '$unassignedCount active ${unassignedCount == 1 ? 'student has' : 'students have'} no assigned section. Please assign ${unassignedCount == 1 ? 'this student' : 'them'} to a section.',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onErrorContainer,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  TextButton.icon(
                    onPressed: onView,
                    icon: const Icon(Icons.visibility_outlined),
                    label: const Text('View unassigned'),
                  ),
                ],
              ),
            );
          },
        );
      },
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
