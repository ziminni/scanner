part of '../teachers_page.dart';

class _ImportTeachersDialog extends StatefulWidget {
  const _ImportTeachersDialog();

  @override
  State<_ImportTeachersDialog> createState() => _ImportTeachersDialogState();
}

class _ImportTeachersDialogState extends State<_ImportTeachersDialog> {
  late final ImportTeachersViewModel _viewModel;
  bool _viewModelReady = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_viewModelReady) return;
    _viewModel = ImportTeachersViewModel(
      SchoolAdminViewModelScope.of(context).app,
    );
    _viewModelReady = true;
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _viewModel,
      builder: (context, _) {
        return AlertDialog(
          title: const Text('Import teachers'),
          content: SizedBox(
            width: 520,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Spreadsheet columns: teacher id, last name, first name, middle name, gender, birthdate, address, contact number, time in, time out.',
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.attach_file_outlined),
                      label: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          _viewModel.fileName ?? 'Choose spreadsheet',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      onPressed: _viewModel.busy ? null : _viewModel.pickFile,
                      style: OutlinedButton.styleFrom(
                        alignment: Alignment.centerLeft,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Required file type: .xlsx',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  if (_viewModel.importedCount > 0) ...[
                    const SizedBox(height: 12),
                    Text('${_viewModel.importedCount} teachers imported.'),
                  ],
                  if (_viewModel.error != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      _viewModel.error!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ],
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
                  : const Icon(Icons.upload_file_outlined),
              label: const Text('Import'),
              onPressed: _viewModel.busy || !_viewModel.hasFile
                  ? null
                  : () async {
                      final imported = await _viewModel.importTeachers();
                      if (imported && context.mounted) {
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
