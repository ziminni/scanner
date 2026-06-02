part of '../attendance_status_page.dart';

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
                  DataCell(StatusBadge(label: entry.status.label, type: entry.status == AttendanceStatus.late ? 'late' : 'active')),
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
