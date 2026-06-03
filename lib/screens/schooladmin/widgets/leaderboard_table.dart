part of '../early_students_page.dart';

class _LeaderboardTable extends StatefulWidget {
  const _LeaderboardTable({
    required this.entries,
    required this.period,
    required this.selectedRole,
  });

  final List<EarlyLeaderboardEntry> entries;
  final EarlyLeaderboardPeriod period;
  final PersonRole selectedRole;

  @override
  State<_LeaderboardTable> createState() => _LeaderboardTableState();
}

class _LeaderboardTableState extends State<_LeaderboardTable> {
  static const List<int> _itemsPerPageOptions = [10, 25, 50, 100];

  int _currentPage = 0;
  int _itemsPerPage = 10;

  @override
  void didUpdateWidget(covariant _LeaderboardTable oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.entries != widget.entries ||
        oldWidget.period != widget.period ||
        oldWidget.selectedRole != widget.selectedRole) {
      _currentPage = 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDaily = widget.period == EarlyLeaderboardPeriod.daily;
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
              columns: [
                const DataColumn(label: Text('Rank')),
                DataColumn(label: Text('${widget.selectedRole.label} ID')),
                const DataColumn(label: Text('Full Name')),
                const DataColumn(label: Text('Section')),
                if (isDaily) const DataColumn(label: Text('Time In')),
                const DataColumn(label: Text('Points')),
                if (!isDaily) const DataColumn(label: Text('Best Daily Rank')),
                if (!isDaily) const DataColumn(label: Text('Average Time In')),
                if (!isDaily) const DataColumn(label: Text('Valid Days')),
              ],
              rows: [
                for (final entry in paginatedEntries)
                  DataRow(
                    cells: [
                      DataCell(Text('${entry.rank}')),
                      DataCell(Text(entry.personId)),
                      DataCell(Text(entry.fullName)),
                      DataCell(
                        Text(entry.section.isEmpty ? '-' : entry.section),
                      ),
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
          const SizedBox(height: 12),
          AdminTableFooter(
            currentPage: currentPage,
            totalItems: widget.entries.length,
            itemsPerPage: _itemsPerPage,
            itemLabel: 'entries',
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
