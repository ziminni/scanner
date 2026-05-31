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
    _viewModel = ImportTeachersViewModel(AppScope.of(context));
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
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Spreadsheet columns: teacher id, last name, first name, middle name, birthdate, address, contact number, time in, time out.',
                ),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  icon: const Icon(Icons.attach_file_outlined),
                  label: Text(_viewModel.fileName ?? 'Choose spreadsheet'),
                  onPressed: _viewModel.busy ? null : _viewModel.pickFile,
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
