part of '../sections_page.dart';

class _AddSectionDialog extends StatefulWidget {
  const _AddSectionDialog();

  @override
  State<_AddSectionDialog> createState() => _AddSectionDialogState();
}

class _AddSectionDialogState extends State<_AddSectionDialog> {
  late final CrudViewModel _viewModel;
  bool _viewModelReady = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_viewModelReady) return;
    _viewModel = CrudViewModel(
      app: AppScope.of(context),
      collection: 'sections',
      fields: SectionsPage._fields,
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
          title: const Text('Add section'),
          content: SizedBox(
            width: 480,
            child: SingleChildScrollView(
              child: Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  for (final entry in _viewModel.controllers.entries)
                    SizedBox(
                      width: 220,
                      child: TextField(
                        controller: entry.value,
                        decoration: InputDecoration(
                          labelText: adminLabel(entry.key),
                        ),
                      ),
                    ),
                  SizedBox(
                    width: 220,
                    child: _AdviserDropdown(
                      selected: _viewModel.selectedAdviser,
                      onChanged: _viewModel.setAdviser,
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
}
