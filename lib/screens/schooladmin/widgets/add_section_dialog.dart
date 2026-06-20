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
      app: SchoolAdminViewModelScope.of(context).app,
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
                  Icons.groups_outlined,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Add section',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          content: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Create a section and assign an adviser from the active school year.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 18),
                  for (final entry in _viewModel.controllers.entries)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: TextField(
                        controller: entry.value,
                        enabled: !_viewModel.busy,
                        keyboardType: entry.key == 'gradeLevel'
                            ? TextInputType.number
                            : TextInputType.text,
                        textInputAction: TextInputAction.next,
                        decoration: InputDecoration(
                          labelText: entry.key == 'name'
                              ? 'Section name'
                              : adminLabel(entry.key),
                          prefixIcon: Icon(
                            entry.key == 'gradeLevel'
                                ? Icons.school_outlined
                                : Icons.class_outlined,
                          ),
                        ),
                      ),
                    ),
                  _AdviserDropdown(
                    selected: _viewModel.selectedAdviser,
                    onChanged: _viewModel.busy ? (_) {} : _viewModel.setAdviser,
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
}
