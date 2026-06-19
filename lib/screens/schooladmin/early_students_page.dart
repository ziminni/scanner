import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/constants/enums.dart';
import '../../core/services/app_controller.dart';
import '../../shared/widgets/admin_widgets.dart';
import '../../shared/widgets/app_widgets.dart';
import '../../shared/widgets/loading_widget.dart';
import 'viewmodels/early_students_viewmodel.dart';

part 'widgets/period_selector.dart';
part 'widgets/role_selector.dart';
part 'widgets/leaderboard_summary.dart';
part 'widgets/metric.dart';
part 'widgets/leaderboard_table.dart';

class EarlyStudentsPage extends StatefulWidget {
  const EarlyStudentsPage({super.key});

  @override
  State<EarlyStudentsPage> createState() => _EarlyStudentsPageState();
}

class _EarlyStudentsPageState extends State<EarlyStudentsPage> {
  late final EarlyStudentsViewModel _viewModel;
  bool _viewModelReady = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_viewModelReady) return;
    _viewModel = EarlyStudentsViewModel(AppScope.of(context));
    _viewModelReady = true;
    _viewModel.load();
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
          title: 'Early Attendance',
          actions: [
            _RoleSelector(
              selected: _viewModel.selectedRole,
              onChanged: _viewModel.setRole,
            ),
            _PeriodSelector(
              selected: _viewModel.period,
              onChanged: _viewModel.setPeriod,
            ),
            OutlinedButton.icon(
              icon: const Icon(Icons.calendar_month_outlined),
              label: Text(
                DateFormat('MMM d, yyyy').format(_viewModel.selectedDate),
              ),
              onPressed: () async {
                final today = DateTime.now();
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _viewModel.selectedDate,
                  firstDate: DateTime(2020),
                  lastDate: DateTime(today.year, today.month, today.day),
                );
                if (picked != null) await _viewModel.setDate(picked);
              },
            ),
          ],
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _LeaderboardSummary(viewModel: _viewModel),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  OutlinedButton.icon(
                    icon: const Icon(Icons.public_outlined),
                    label: const Text('Overall'),
                    onPressed:
                        _viewModel.sectionFilter.isEmpty &&
                            _viewModel.genderFilter.isEmpty &&
                            _viewModel.gradeLevelFilter.isEmpty
                        ? null
                        : _viewModel.clearFilters,
                  ),
                  _EarlyFilterSelect(
                    label: 'Section',
                    value: _viewModel.sectionFilter,
                    options: _viewModel.sections,
                    onChanged: _viewModel.setSectionFilter,
                  ),
                  _EarlyFilterSelect(
                    label: 'Gender',
                    value: _viewModel.genderFilter,
                    options: _viewModel.genders,
                    onChanged: _viewModel.setGenderFilter,
                  ),
                  _EarlyFilterSelect(
                    label: 'Grade Level',
                    value: _viewModel.gradeLevelFilter,
                    options: _viewModel.gradeLevels,
                    onChanged: _viewModel.setGradeLevelFilter,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (_viewModel.busy)
                const LoadingWidget()
              else if (_viewModel.error != null)
                EmptyState(title: _viewModel.error!)
              else if (_viewModel.entries.isEmpty)
                const EmptyState(title: 'No early ranking records found')
              else
                _LeaderboardTable(
                  entries: _viewModel.entries,
                  period: _viewModel.period,
                  selectedRole: _viewModel.selectedRole,
                ),
            ],
          ),
        );
      },
    );
  }
}

class _EarlyFilterSelect extends StatelessWidget {
  const _EarlyFilterSelect({
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
  });

  final String label;
  final String value;
  final List<String> options;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final displayValue = value.isEmpty || options.contains(value) ? value : '';
    return SizedBox(
      width: 180,
      child: DropdownButtonFormField<String>(
        initialValue: displayValue,
        decoration: InputDecoration(labelText: label),
        items: [
          const DropdownMenuItem(value: '', child: Text('All')),
          for (final option in options)
            DropdownMenuItem(value: option, child: Text(option)),
        ],
        onChanged: (next) => onChanged(next ?? ''),
      ),
    );
  }
}
