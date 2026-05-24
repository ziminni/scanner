import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/services/app_controller.dart';
import '../../shared/widgets/admin_widgets.dart';
import '../../shared/widgets/app_widgets.dart';
import '../../shared/widgets/loading_widget.dart';
import '../../viewmodels/early_students_viewmodel.dart';

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

class _PeriodSelector extends StatelessWidget {
  const _PeriodSelector({required this.selected, required this.onChanged});

  final EarlyLeaderboardPeriod selected;
  final ValueChanged<EarlyLeaderboardPeriod> onChanged;

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<EarlyLeaderboardPeriod>(
      segments: [
        for (final period in EarlyLeaderboardPeriod.values)
          ButtonSegment(value: period, label: Text(period.label)),
      ],
      selected: {selected},
      onSelectionChanged: (selection) => onChanged(selection.first),
    );
  }
}

class _LeaderboardSummary extends StatelessWidget {
  const _LeaderboardSummary({required this.viewModel});

  final EarlyStudentsViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return DataSurface(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Wrap(
          spacing: 24,
          runSpacing: 12,
          children: [
            _Metric(label: 'Period', value: viewModel.periodLabel),
            _Metric(
              label: 'Students ranked',
              value: '${viewModel.entries.length}',
            ),
            _Metric(
              label: 'Top student',
              value: viewModel.entries.isEmpty
                  ? '-'
                  : viewModel.entries.first.fullName,
            ),
          ],
        ),
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 220,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.labelMedium),
          const SizedBox(height: 4),
          Text(
            value.isEmpty ? '-' : value,
            style: Theme.of(context).textTheme.titleMedium,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _LeaderboardTable extends StatelessWidget {
  const _LeaderboardTable({required this.entries, required this.period});

  final List<EarlyLeaderboardEntry> entries;
  final EarlyLeaderboardPeriod period;

  @override
  Widget build(BuildContext context) {
    final isDaily = period == EarlyLeaderboardPeriod.daily;
    return DataSurface(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columns: [
            const DataColumn(label: Text('Rank')),
            const DataColumn(label: Text('Student ID')),
            const DataColumn(label: Text('Full Name')),
            const DataColumn(label: Text('Section')),
            if (isDaily) const DataColumn(label: Text('Time In')),
            const DataColumn(label: Text('Points')),
            if (!isDaily) const DataColumn(label: Text('Best Daily Rank')),
            if (!isDaily) const DataColumn(label: Text('Average Time In')),
            if (!isDaily) const DataColumn(label: Text('Valid Days')),
          ],
          rows: [
            for (final entry in entries)
              DataRow(
                cells: [
                  DataCell(Text('${entry.rank}')),
                  DataCell(Text(entry.personId)),
                  DataCell(Text(entry.fullName)),
                  DataCell(Text(entry.section.isEmpty ? '-' : entry.section)),
                  if (isDaily) DataCell(Text(entry.timeInText)),
                  DataCell(Text('${entry.points}')),
                  if (!isDaily) DataCell(Text('${entry.bestDailyRank}')),
                  if (!isDaily) DataCell(Text(entry.averageTimeInText)),
                  if (!isDaily) DataCell(Text('${entry.validDays}')),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
