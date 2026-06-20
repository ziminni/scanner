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
                DataColumn(label: Text('#')),
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
                for (var index = 0; index < paginatedEntries.length; index++)
                  DataRow(
                    cells: [
                      DataCell(Text('${start + index + 1}')),
                      DataCell(Text(paginatedEntries[index].personId)),
                      DataCell(Text(paginatedEntries[index].fullName)),
                      DataCell(Text(paginatedEntries[index].role.label)),
                      DataCell(
                        Text(
                          paginatedEntries[index].section.isEmpty
                              ? '-'
                              : paginatedEntries[index].section,
                        ),
                      ),
                      DataCell(
                        StatusBadge(
                          label: paginatedEntries[index].status.label,
                          type:
                              paginatedEntries[index].status ==
                                  AttendanceStatus.late
                              ? 'late'
                              : 'active',
                        ),
                      ),
                      DataCell(Text(paginatedEntries[index].timeIn)),
                      DataCell(Text(paginatedEntries[index].timeOut)),
                      DataCell(Text(paginatedEntries[index].detail)),
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
