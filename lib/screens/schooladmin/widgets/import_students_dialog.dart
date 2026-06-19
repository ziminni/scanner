part of '../students_page.dart';

class _ImportStudentsDialog extends StatefulWidget {
  const _ImportStudentsDialog();

  @override
  State<_ImportStudentsDialog> createState() => _ImportStudentsDialogState();
}

class _ImportStudentsDialogState extends State<_ImportStudentsDialog> {
  late final ImportStudentsViewModel _viewModel;
  bool _viewModelReady = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_viewModelReady) return;
    _viewModel = ImportStudentsViewModel(AppScope.of(context));
    _viewModelReady = true;
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _viewModel,
      builder: (context, _) {
        return AlertDialog(
          title: const Text('Import students'),
          content: SizedBox(
            width: 560,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Spreadsheet columns: LRN, last name, first name, middle name, gender, birthdate, address, guardian name, guardian contact.',
                  ),
                  const SizedBox(height: 16),
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
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (mounted) _viewModel.selectSection(null);
                        });
                      }
                      final selectedSection =
                          sectionNames.contains(_viewModel.selectedSection)
                          ? _viewModel.selectedSection
                          : null;

                      return DropdownButtonFormField<String>(
                        initialValue: selectedSection,
                        decoration: const InputDecoration(
                          labelText: 'Import to section',
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
                      );
                    },
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
                    Text('${_viewModel.importedCount} students imported.'),
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
              onPressed:
                  _viewModel.busy ||
                      !_viewModel.hasFile ||
                      _viewModel.selectedSection == null
                  ? null
                  : () async {
                      final imported = await _viewModel.importStudents();
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
