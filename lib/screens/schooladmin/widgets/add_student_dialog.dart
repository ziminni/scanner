part of '../students_page.dart';

class _AddStudentDialog extends StatefulWidget {
  const _AddStudentDialog();

  @override
  State<_AddStudentDialog> createState() => _AddStudentDialogState();
}

class _AddStudentDialogState extends State<_AddStudentDialog> {
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
        return AlertDialog(
          title: const Text('Add student'),
          content: SizedBox(
            width: 720,
            child: SingleChildScrollView(
              child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
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
                        const SizedBox(
                          width: double.infinity,
                          child: Text(
                            'Create a section first before adding students.',
                          ),
                        ),
                      if (_viewModel.message != null)
                        SizedBox(
                          width: double.infinity,
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
            ),
          ),
          actions: [
            TextButton(
              onPressed: _viewModel.busy ? null : () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton.icon(
              icon: _viewModel.busy
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.add),
              label: const Text('Add'),
              onPressed: _viewModel.busy || _viewModel.selectedSection == null
                  ? null
                  : () async {
                      await _viewModel.addStudent();
                      if (_viewModel.message == null && context.mounted) {
                        Navigator.pop(context);
                      }
                    },
            ),
          ],
        );
      },
    );
  }
}
