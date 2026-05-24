import 'package:flutter/material.dart';

import '../../core/services/app_controller.dart';
import '../../models/models.dart';
import '../../shared/widgets/admin_widgets.dart';
import '../../shared/widgets/form_fields.dart';
import '../../viewmodels/school_year_viewmodel.dart';

class SchoolYearPage extends StatefulWidget {
  const SchoolYearPage({super.key});

  @override
  State<SchoolYearPage> createState() => _SchoolYearPageState();
}

class _SchoolYearPageState extends State<SchoolYearPage> {
  late final SchoolYearViewModel _viewModel;
  bool _viewModelReady = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_viewModelReady) return;
    _viewModel = SchoolYearViewModel(AppScope.of(context));
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
        return AdminPage(
          title: 'School Year',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FutureBuilder<SchoolYear?>(
                future: _viewModel.activeSchoolYear(),
                builder: (context, snapshot) {
                  final active = snapshot.data;
                  if (active != null) {
                    return DataSurface(
                      child: ListTile(
                        leading: const Icon(Icons.event_available_outlined),
                        title: Text('Active school year: ${active.name}'),
                        subtitle: Text(
                          'New school year creation is locked until the active year is archived.',
                        ),
                        trailing: FilledButton.icon(
                          icon: const Icon(Icons.archive_outlined),
                          label: const Text('Archive'),
                          onPressed: () async {
                            await _viewModel.archiveActive(active);
                            if (mounted) setState(() {});
                          },
                        ),
                      ),
                    );
                  }

                  return DataSurface(
                    child: ListTile(
                      leading: const Icon(Icons.event_busy_outlined),
                      title: const Text('No active school year'),
                      subtitle: const Text(
                        'Create a school year to unlock students, teachers, sections, attendance, and scanner modules.',
                      ),
                      trailing: FilledButton.icon(
                        icon: const Icon(Icons.add),
                        label: const Text('Create active school year'),
                        onPressed: () async {
                          final created = await showDialog<bool>(
                            context: context,
                            builder: (_) => const CreateSchoolYearDialog(),
                          );
                          if (created == true && mounted) setState(() {});
                        },
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),
              const CollectionTable(
                collection: 'school_years',
                columns: [
                  'name',
                  'isActive',
                  'archived',
                  'term1Start',
                  'term1End',
                  'term2Start',
                  'term2End',
                  'term3Start',
                  'term3End',
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

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
