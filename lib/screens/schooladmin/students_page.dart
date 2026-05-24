import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../core/services/app_controller.dart';
import '../../shared/widgets/admin_widgets.dart';
import '../../shared/widgets/form_fields.dart';
import '../../viewmodels/students_viewmodel.dart';

class StudentsPage extends StatefulWidget {
  const StudentsPage({super.key});

  @override
  State<StudentsPage> createState() => _StudentsPageState();
}

class _StudentsPageState extends State<StudentsPage> {
  late final StudentsViewModel _viewModel;
  bool _viewModelReady = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_viewModelReady) return;
    _viewModel = StudentsViewModel(AppScope.of(context));
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
          title: 'Students',
          actions: [
            OutlinedButton.icon(
              icon: const Icon(Icons.download_outlined),
              label: const Text('Template'),
              onPressed: () {},
            ),
            FilledButton.icon(
              icon: const Icon(Icons.add),
              label: const Text('Add student'),
              onPressed: _viewModel.selectedSection == null
                  ? null
                  : _viewModel.addStudent,
            ),
          ],
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: _viewModel.sectionsStream,
                builder: (context, snapshot) {
                  final sectionNames =
                      (snapshot.data?.docs ?? [])
                          .map((doc) => doc.data()['name'] as String? ?? '')
                          .where((name) => name.trim().isNotEmpty)
                          .toSet()
                          .toList()
                        ..sort();

                  if (_viewModel.selectedSection != null &&
                      !sectionNames.contains(_viewModel.selectedSection)) {
                    _viewModel.selectSection(null);
                  }

                  return Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      for (final entry in _viewModel.controllers.entries)
                        SizedBox(
                          width: 220,
                          child: entry.key == 'birthdate'
                              ? BirthdateField(
                                  value: _viewModel.birthdate,
                                  onChanged: _viewModel.setBirthdate,
                                )
                              : TextField(
                                  controller: entry.value,
                                  decoration: InputDecoration(
                                    labelText: adminLabel(entry.key),
                                  ),
                                ),
                        ),
                      SizedBox(
                        width: 220,
                        child: DropdownButtonFormField<String>(
                          initialValue: _viewModel.selectedSection,
                          decoration: const InputDecoration(
                            labelText: 'Section',
                          ),
                          hint: const Text('Select section'),
                          items: [
                            for (final section in sectionNames)
                              DropdownMenuItem(
                                value: section,
                                child: Text(section),
                              ),
                          ],
                          onChanged: sectionNames.isEmpty
                              ? null
                              : _viewModel.selectSection,
                        ),
                      ),
                      if (sectionNames.isEmpty)
                        const Padding(
                          padding: EdgeInsets.only(top: 16),
                          child: Text(
                            'Create a section first before adding students.',
                          ),
                        ),
                      if (_viewModel.message != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 16),
                          child: Text(
                            _viewModel.message!,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.error,
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 16),
              const CollectionTable(
                collection: 'students',
                columns: studentFields,
                schoolYearScoped: true,
              ),
            ],
          ),
        );
      },
    );
  }
}
