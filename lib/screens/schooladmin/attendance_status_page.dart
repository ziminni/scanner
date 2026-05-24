import 'package:flutter/material.dart';

import '../../core/services/app_controller.dart';
import '../../shared/widgets/admin_widgets.dart';
import '../../shared/widgets/app_widgets.dart';
import '../../shared/widgets/loading_widget.dart';
import '../../viewmodels/attendance_status_viewmodel.dart';

class AttendanceStatusPage extends StatefulWidget {
  const AttendanceStatusPage({super.key});

  @override
  State<AttendanceStatusPage> createState() => _AttendanceStatusPageState();
}

class _AttendanceStatusPageState extends State<AttendanceStatusPage> {
  late final AttendanceStatusViewModel _viewModel;
  bool _viewModelReady = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_viewModelReady) return;
    _viewModel = AttendanceStatusViewModel(AppScope.of(context));
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
          title: 'Attendance Status',
          actions: [
            OutlinedButton.icon(
              icon: const Icon(Icons.calendar_month_outlined),
              label: Text(_viewModel.selectedDateLabel),
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
              GridView(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 260,
                  mainAxisExtent: 104,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                children: [
                  MetricCard(
                    label: 'Late',
                    value: '${_viewModel.lateCount}',
                    icon: Icons.schedule_outlined,
                  ),
                  MetricCard(
                    label: 'Absent',
                    value: '${_viewModel.absentCount}',
                    icon: Icons.person_off_outlined,
                  ),
                  MetricCard(
                    label: 'Incomplete',
                    value: '${_viewModel.incompleteCount}',
                    icon: Icons.rule_outlined,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  SegmentedButton<AttendanceStatusFilter>(
                    segments: [
                      for (final filter in AttendanceStatusFilter.values)
                        ButtonSegment(value: filter, label: Text(filter.label)),
                    ],
                    selected: {_viewModel.filter},
                    onSelectionChanged: (selection) =>
                        _viewModel.setFilter(selection.first),
                  ),
                  SizedBox(
                    width: 320,
                    child: TextField(
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.search),
                        labelText: 'Search name, ID, section, role',
                      ),
                      onChanged: _viewModel.setSearch,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (_viewModel.busy)
                const LoadingWidget()
              else if (_viewModel.error != null)
                EmptyState(title: _viewModel.error!)
              else if (_viewModel.entries.isEmpty)
                const EmptyState(title: 'No matching attendance status records')
              else
                _AttendanceStatusTable(entries: _viewModel.entries),
            ],
          ),
        );
      },
    );
  }
}

class _AttendanceStatusTable extends StatelessWidget {
  const _AttendanceStatusTable({required this.entries});

  final List<AttendanceStatusEntry> entries;

  @override
  Widget build(BuildContext context) {
    return DataSurface(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columns: const [
            DataColumn(label: Text('ID')),
            DataColumn(label: Text('Name')),
            DataColumn(label: Text('Role')),
            DataColumn(label: Text('Section')),
            DataColumn(label: Text('Status')),
            DataColumn(label: Text('Time In')),
            DataColumn(label: Text('Time Out')),
            DataColumn(label: Text('Details')),
          ],
          rows: [
            for (final entry in entries)
              DataRow(
                cells: [
                  DataCell(Text(entry.personId)),
                  DataCell(Text(entry.fullName)),
                  DataCell(Text(entry.role.label)),
                  DataCell(Text(entry.section.isEmpty ? '-' : entry.section)),
                  DataCell(Text(entry.status.label)),
                  DataCell(Text(entry.timeIn)),
                  DataCell(Text(entry.timeOut)),
                  DataCell(Text(entry.detail)),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
