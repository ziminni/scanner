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
    _viewModel = StudentsViewModel(SchoolAdminViewModelScope.of(context).app);
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
        final theme = Theme.of(context);
        return AlertDialog(
          titlePadding: const EdgeInsets.fromLTRB(24, 22, 24, 0),
          contentPadding: const EdgeInsets.fromLTRB(24, 16, 24, 12),
          actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 18),
          title: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withAlpha(24),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.school_outlined,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Add student',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          content: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
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

                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Register a student under the active school year and assign a section.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 18),
                      for (final entry in _viewModel.controllers.entries)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 14),
                          child: entry.key == 'birthdate'
                              ? BirthdateField(
                                  value: _viewModel.birthdate,
                                  onChanged: _viewModel.setBirthdate,
                                )
                              : TextField(
                                  controller: entry.value,
                                  enabled: !_viewModel.busy,
                                  textInputAction: TextInputAction.next,
                                  decoration: InputDecoration(
                                    labelText: _studentFieldLabel(entry.key),
                                    prefixIcon: Icon(
                                      _studentFieldIcon(entry.key),
                                    ),
                                  ),
                                ),
                        ),
                      GenderDropdownField(
                        value: _viewModel.selectedGender,
                        enabled: !_viewModel.busy,
                        onChanged: _viewModel.selectGender,
                      ),
                      const SizedBox(height: 14),
                      DropdownButtonFormField<String>(
                        initialValue: _viewModel.selectedSection,
                        decoration: const InputDecoration(
                          labelText: 'Section',
                          prefixIcon: Icon(Icons.groups_outlined),
                        ),
                        hint: const Text('Select section'),
                        items: [
                          for (final section in sectionNames)
                            DropdownMenuItem(
                              value: section,
                              child: Text(section),
                            ),
                        ],
                        onChanged: sectionNames.isEmpty || _viewModel.busy
                            ? null
                            : _viewModel.selectSection,
                      ),
                      if (sectionNames.isEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: Text(
                            'Create a section first before adding students.',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      if (_viewModel.message != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: theme.colorScheme.errorContainer,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Text(
                                _viewModel.message!,
                                style: TextStyle(
                                  color: theme.colorScheme.error,
                                ),
                              ),
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
              onPressed:
                  _viewModel.busy ||
                      _viewModel.selectedSection == null ||
                      _viewModel.selectedGender == null
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

  String _studentFieldLabel(String key) {
    return switch (key) {
      'lrn' => 'LRN',
      'guardianName' => 'Guardian name',
      'guardianContact' => 'Guardian contact',
      _ => adminLabel(key),
    };
  }

  IconData _studentFieldIcon(String key) {
    return switch (key) {
      'lrn' => Icons.badge_outlined,
      'lastName' || 'firstName' || 'middleName' => Icons.person_outline,
      'address' => Icons.home_outlined,
      'guardianName' || 'guardianContact' => Icons.contact_phone_outlined,
      _ => Icons.edit_outlined,
    };
  }
}
