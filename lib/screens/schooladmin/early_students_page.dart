import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/services/app_controller.dart';
import '../../shared/widgets/admin_widgets.dart';
import '../../shared/widgets/app_widgets.dart';
import '../../shared/widgets/loading_widget.dart';
import 'viewmodels/early_students_viewmodel.dart';

part 'widgets/period_selector.dart';
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
          title: 'Early Students',
          actions: [
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
                ),
            ],
          ),
        );
      },
    );
  }
}
