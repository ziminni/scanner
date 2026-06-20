import 'package:flutter/material.dart';

import '../../shared/widgets/admin.dart';
import '../../shared/widgets/app_widgets.dart';
import '../../shared/widgets/loading_widget.dart';
import 'viewmodels/attendance_status_viewmodel.dart';
import '../../core/constants/enums.dart';
import 'viewmodels/school_admin_viewmodel.dart';

part 'widgets/status_filter_select.dart';

part 'widgets/attendance_status_table.dart';

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
    _viewModel = AttendanceStatusViewModel(
      SchoolAdminViewModelScope.of(context).app,
    );
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
              SizedBox(
                width: double.infinity,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SegmentedButton<AttendanceStatusFilter>(
                    segments: [
                      for (final filter in AttendanceStatusFilter.values)
                        ButtonSegment(value: filter, label: Text(filter.label)),
                    ],
                    selected: {_viewModel.filter},
                    onSelectionChanged: (selection) =>
                        _viewModel.setFilter(selection.first),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
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
                  _StatusFilterSelect(
                    label: 'Role',
                    value: _viewModel.roleFilter,
                    options: const ['Student', 'Teacher'],
                    onChanged: _viewModel.setRoleFilter,
                  ),
                  _StatusFilterSelect(
                    label: 'Section',
                    value: _viewModel.sectionFilter,
                    options: _viewModel.sections,
                    onChanged: _viewModel.setSectionFilter,
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
