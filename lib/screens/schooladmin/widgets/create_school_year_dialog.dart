part of '../school_year_page.dart';

class CreateSchoolYearDialog extends StatefulWidget {
  const CreateSchoolYearDialog({super.key});

  @override
  State<CreateSchoolYearDialog> createState() => _CreateSchoolYearDialogState();
}

class _CreateSchoolYearDialogState extends State<CreateSchoolYearDialog> {
  late final CreateSchoolYearViewModel _viewModel;
  bool _viewModelReady = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_viewModelReady) return;
    _viewModel = CreateSchoolYearViewModel(AppScope.of(context));
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
          title: const Text('Create active school year'),
          content: SizedBox(
            width: 560,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      SizedBox(
                        width: 180,
                        child: TextField(
                          controller: _viewModel.yearStart,
                          decoration: const InputDecoration(
                            labelText: 'Start year',
                            hintText: '2026',
                          ),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const Text('-'),
                      SizedBox(
                        width: 180,
                        child: TextField(
                          controller: _viewModel.yearEnd,
                          decoration: const InputDecoration(
                            labelText: 'End year',
                            hintText: '2027',
                          ),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      for (var index = 0; index < 3; index++) ...[
                        DateButton(
                          label:
                              '${index + 1}${index == 0
                                  ? 'st'
                                  : index == 1
                                  ? 'nd'
                                  : 'rd'} Term Start',
                          value: _viewModel.termStarts[index],
                          onPick: (date) =>
                              _viewModel.setTermStart(index, date),
                        ),
                        DateButton(
                          label:
                              '${index + 1}${index == 0
                                  ? 'st'
                                  : index == 1
                                  ? 'nd'
                                  : 'rd'} Term End',
                          value: _viewModel.termEnds[index],
                          onPick: (date) => _viewModel.setTermEnd(index, date),
                        ),
                      ],
                    ],
                  ),
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
              onPressed: _viewModel.busy
                  ? null
                  : () => Navigator.pop(context, false),
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
              label: const Text('Create'),
              onPressed: _viewModel.busy
                  ? null
                  : () async {
                      final created = await _viewModel.create();
                      if (created && context.mounted) {
                        Navigator.pop(context, true);
                      }
                    },
            ),
          ],
        );
      },
    );
  }
}
