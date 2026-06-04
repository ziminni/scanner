part of '../teachers_page.dart';

class _AddTeacherDialog extends StatefulWidget {
  const _AddTeacherDialog();

  @override
  State<_AddTeacherDialog> createState() => _AddTeacherDialogState();
}

class _AddTeacherDialogState extends State<_AddTeacherDialog> {
  late final CrudViewModel _viewModel;
  bool _viewModelReady = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_viewModelReady) return;
    _viewModel = CrudViewModel(
      app: AppScope.of(context),
      collection: 'teachers',
      fields: TeachersPage.fields,
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
                  Icons.badge_outlined,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Add teacher',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          content: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Register a teacher and set the assigned attendance schedule.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 18),
                  for (final entry in _viewModel.controllers.entries)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: _fieldInput(entry),
                    ),
                  TimePickerField(
                    label: 'Assigned Time In',
                    value: _viewModel.assignedTimeIn,
                    fallback: const TimeOfDay(hour: 7, minute: 0),
                    onChanged: _viewModel.setAssignedTimeIn,
                  ),
                  const SizedBox(height: 14),
                  TimePickerField(
                    label: 'Assigned Time Out',
                    value: _viewModel.assignedTimeOut,
                    fallback: const TimeOfDay(hour: 17, minute: 0),
                    onChanged: _viewModel.setAssignedTimeOut,
                  ),
                  if (_viewModel.error != null)
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
                            _viewModel.error!,
                            style: TextStyle(color: theme.colorScheme.error),
                          ),
                        ),
                      ),
                    ),
                ],
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
              onPressed: _viewModel.busy
                  ? null
                  : () async {
                      await _viewModel.addRecord();
                      if (_viewModel.error == null && context.mounted) {
                        Navigator.pop(context);
                      }
                    },
            ),
          ],
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
      enabled: !_viewModel.busy,
      textInputAction: TextInputAction.next,
      decoration: InputDecoration(
        labelText: _teacherFieldLabel(entry.key),
        prefixIcon: Icon(_teacherFieldIcon(entry.key)),
      ),
    );
  }

  String _teacherFieldLabel(String key) {
    return switch (key) {
      'teacherId' => 'Teacher ID',
      'contactNumber' => 'Contact number',
      _ => adminLabel(key),
    };
  }

  IconData _teacherFieldIcon(String key) {
    return switch (key) {
      'teacherId' => Icons.badge_outlined,
      'lastName' || 'firstName' || 'middleName' => Icons.person_outline,
      'address' => Icons.home_outlined,
      'contactNumber' => Icons.phone_outlined,
      _ => Icons.edit_outlined,
    };
  }
}
