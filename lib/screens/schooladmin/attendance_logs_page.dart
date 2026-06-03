import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../core/services/app_controller.dart';
import '../../models/models.dart';
import '../../shared/widgets/app_widgets.dart';
import '../../shared/widgets/admin_widgets.dart';
import '../../core/constants/enums.dart';

part 'widgets/attendance_logs_table.dart';

class AttendanceLogsPage extends StatefulWidget {
  const AttendanceLogsPage({super.key});

  @override
  State<AttendanceLogsPage> createState() => _AttendanceLogsPageState();
}

class _AttendanceLogsPageState extends State<AttendanceLogsPage> {
  final _search = TextEditingController();
  String _roleFilter = '';
  String _typeFilter = '';
  String _statusFilter = '';
  String _syncFilter = '';

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: AdminPage(
        title: 'Logs',
        child: Column(
          children: [
            Wrap(
              spacing: 12,
              runSpacing: 12,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                SizedBox(
                  width: 360,
                  child: TextField(
                    controller: _search,
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.search),
                      labelText: 'Search name, ID, section, scanner, reason',
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                _LogFilterSelect(
                  label: 'Role',
                  value: _roleFilter,
                  options: const ['Student', 'Teacher'],
                  onChanged: (value) => setState(() => _roleFilter = value),
                ),
                _LogFilterSelect(
                  label: 'Type',
                  value: _typeFilter,
                  options: const ['Time In', 'Time Out'],
                  onChanged: (value) => setState(() => _typeFilter = value),
                ),
                _LogFilterSelect(
                  label: 'Status',
                  value: _statusFilter,
                  options: AttendanceStatus.values
                      .map((status) => status.label)
                      .toList(),
                  onChanged: (value) => setState(() => _statusFilter = value),
                ),
                _LogFilterSelect(
                  label: 'Sync',
                  value: _syncFilter,
                  options: SyncStatus.values.map((sync) => sync.label).toList(),
                  onChanged: (value) => setState(() => _syncFilter = value),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const TabBar(
              tabs: [
                Tab(text: 'Attendance Logs'),
                Tab(text: 'Gate Pass Logs'),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: MediaQuery.sizeOf(context).height - 260,
              child: TabBarView(
                children: [
                  SingleChildScrollView(
                    child: AttendanceLogsTable(
                      limit: 200,
                      search: _search.text,
                      roleFilter: _roleFilter,
                      typeFilter: _typeFilter,
                      statusFilter: _statusFilter,
                      syncFilter: _syncFilter,
                    ),
                  ),
                  SingleChildScrollView(
                    child: GatePassLogsTable(
                      limit: 200,
                      search: _search.text,
                      roleFilter: _roleFilter,
                      syncFilter: _syncFilter,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LogFilterSelect extends StatelessWidget {
  const _LogFilterSelect({
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
    return SizedBox(
      width: 160,
      child: DropdownButtonFormField<String>(
        initialValue: value,
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
