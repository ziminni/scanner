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
        return AlertDialog(
          title: const Text('Add teacher'),
          content: SizedBox(
            width: 720,
            child: SingleChildScrollView(
              child: Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  for (final entry in _viewModel.controllers.entries)
                    SizedBox(width: 220, child: _fieldInput(entry)),
                  SizedBox(
                    width: 220,
                    child: TimePickerField(
                      label: 'Assigned Time In',
                      value: _viewModel.assignedTimeIn,
                      fallback: const TimeOfDay(hour: 7, minute: 0),
                      onChanged: _viewModel.setAssignedTimeIn,
                    ),
                  ),
                  SizedBox(
                    width: 220,
                    child: TimePickerField(
                      label: 'Assigned Time Out',
                      value: _viewModel.assignedTimeOut,
                      fallback: const TimeOfDay(hour: 17, minute: 0),
                      onChanged: _viewModel.setAssignedTimeOut,
                    ),
                  ),
                  if (_viewModel.error != null)
                    SizedBox(
                      width: double.infinity,
                      child: Text(
                        _viewModel.error!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
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
      decoration: InputDecoration(labelText: adminLabel(entry.key)),
    );
  }
}
