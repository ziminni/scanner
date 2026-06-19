part of '../attendance_status_page.dart';

class _AttendanceStatusTable extends StatefulWidget {
  const _AttendanceStatusTable({required this.entries});

  final List<AttendanceStatusEntry> entries;

  @override
  State<_AttendanceStatusTable> createState() => _AttendanceStatusTableState();
}

class _AttendanceStatusTableState extends State<_AttendanceStatusTable> {
  static const List<int> _itemsPerPageOptions = [10, 25, 50, 100];

  int _currentPage = 0;
  int _itemsPerPage = 10;

  @override
  void didUpdateWidget(covariant _AttendanceStatusTable oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.entries != widget.entries) {
      _currentPage = 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalPages = (widget.entries.length / _itemsPerPage).ceil();
    final currentPage = totalPages == 0
        ? 0
        : _currentPage.clamp(0, totalPages - 1).toInt();
    final start = currentPage * _itemsPerPage;
    final end = (start + _itemsPerPage).clamp(0, widget.entries.length).toInt();
    final paginatedEntries = widget.entries.sublist(start, end);

    return DataSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FullWidthHorizontalTable(
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
                for (final entry in paginatedEntries)
                  DataRow(
                    cells: [
                      DataCell(Text(entry.personId)),
                      DataCell(Text(entry.fullName)),
                      DataCell(Text(entry.role.label)),
                      DataCell(
                        Text(entry.section.isEmpty ? '-' : entry.section),
                      ),
                      DataCell(
                        StatusBadge(
                          label: entry.status.label,
                          type: entry.status == AttendanceStatus.late
                              ? 'late'
                              : 'active',
                        ),
                      ),
                      DataCell(Text(entry.timeIn)),
                      DataCell(Text(entry.timeOut)),
                      DataCell(Text(entry.detail)),
                    ],
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          AdminTableFooter(
            currentPage: currentPage,
            totalItems: widget.entries.length,
            itemsPerPage: _itemsPerPage,
            itemLabel: 'records',
            itemsPerPageOptions: _itemsPerPageOptions,
            onItemsPerPageChanged: (value) {
              setState(() {
                _itemsPerPage = value;
                _currentPage = 0;
              });
            },
          ),
          if (totalPages > 1) ...[
            const SizedBox(height: 8),
            AdminPaginationControls(
              currentPage: currentPage,
              totalPages: totalPages,
              onPageChanged: (page) {
                setState(() {
                  _currentPage = page;
                });
              },
            ),
          ],
        ],
      ),
    );
  }
}
