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
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AdminPage(
      title: 'Attendance Logs',
      child: Column(
        children: [
          _LogFilters(
            search: _search,
            searchLabel: 'Search name, ID, section, scanner',
            filters: [
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
            onSearchChanged: () => setState(() {}),
          ),
          const SizedBox(height: 12),
          AttendanceLogsTable(
            limit: 200,
            search: _search.text,
            roleFilter: _roleFilter,
            typeFilter: _typeFilter,
            statusFilter: _statusFilter,
            syncFilter: _syncFilter,
          ),
        ],
      ),
    );
  }
}

class GatePassLogsPage extends StatefulWidget {
  const GatePassLogsPage({super.key});

  @override
  State<GatePassLogsPage> createState() => _GatePassLogsPageState();
}

class _GatePassLogsPageState extends State<GatePassLogsPage> {
  final _search = TextEditingController();
  String _roleFilter = '';
  String _syncFilter = '';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AdminPage(
      title: 'Gate Pass Logs',
      child: Column(
        children: [
          _LogFilters(
            search: _search,
            searchLabel: 'Search name, ID, section, scanner, reason',
            filters: [
              _LogFilterSelect(
                label: 'Role',
                value: _roleFilter,
                options: const ['Student', 'Teacher'],
                onChanged: (value) => setState(() => _roleFilter = value),
              ),
              _LogFilterSelect(
                label: 'Sync',
                value: _syncFilter,
                options: SyncStatus.values.map((sync) => sync.label).toList(),
                onChanged: (value) => setState(() => _syncFilter = value),
              ),
            ],
            onSearchChanged: () => setState(() {}),
          ),
          const SizedBox(height: 12),
          GatePassLogsTable(
            limit: 200,
            search: _search.text,
            roleFilter: _roleFilter,
            syncFilter: _syncFilter,
          ),
        ],
      ),
    );
  }
}

class _LogFilters extends StatelessWidget {
  const _LogFilters({
    required this.search,
    required this.searchLabel,
    required this.filters,
    required this.onSearchChanged,
  });

  final TextEditingController search;
  final String searchLabel;
  final List<Widget> filters;
  final VoidCallback onSearchChanged;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final filterWidth = filters.length * 172;
        final searchWidth = (constraints.maxWidth - filterWidth - 12)
            .clamp(360.0, 720.0)
            .toDouble();
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            SizedBox(
              width: searchWidth,
              child: TextField(
                controller: search,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.search),
                  labelText: searchLabel,
                ),
                onChanged: (_) => onSearchChanged(),
              ),
            ),
            ...filters,
          ],
        );
      },
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
