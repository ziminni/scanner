import 'package:flutter/material.dart';

import '../../core/services/app_controller.dart';
import '../../models/models.dart';
import '../../shared/widgets/admin_widgets.dart';
import '../../shared/widgets/form_fields.dart';
import 'viewmodels/create_school_year_viewmodel.dart';
import 'viewmodels/school_year_viewmodel.dart';

part 'widgets/create_school_year_dialog.dart';

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
