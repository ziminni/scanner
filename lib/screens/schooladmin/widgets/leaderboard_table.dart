part of '../early_students_page.dart';

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
