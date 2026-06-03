import 'package:flutter/material.dart';

import '../scanner_theme.dart';
import '../viewmodels/scanner_home_viewmodel.dart';

class HomeLeaderboard extends StatelessWidget {
  const HomeLeaderboard({super.key, required this.viewModel});

  final ScannerHomeViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: ScannerTheme.panelDecoration(),
      clipBehavior: Clip.antiAlias,
      child: DefaultTabController(
        length: 2,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text(
                'Top 10 Earliest Today',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: ScannerTheme.text,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const TabBar(
              labelColor: ScannerTheme.primary,
              unselectedLabelColor: ScannerTheme.text,
              indicatorColor: ScannerTheme.primary,
              tabs: [
                Tab(text: 'Students'),
                Tab(text: 'Teachers'),
              ],
            ),
            SizedBox(
              height: 360,
              child: TabBarView(
                children: [
                  _LeaderboardTable(entries: viewModel.students),
                  _LeaderboardTable(entries: viewModel.teachers),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LeaderboardTable extends StatelessWidget {
  const _LeaderboardTable({required this.entries});

  final List<ScannerHomeLeaderboardEntry> entries;

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) {
      return const Center(
        child: Text(
          'No valid Time In logs yet.',
          style: TextStyle(color: ScannerTheme.text),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      scrollDirection: Axis.horizontal,
      child: DataTable(
        headingRowColor: WidgetStateProperty.all(ScannerTheme.surfaceSoft),
        columns: const [
          DataColumn(label: Text('#')),
          DataColumn(label: Text('Name')),
          DataColumn(label: Text('Time In')),
          DataColumn(label: Text('Points')),
        ],
        rows: [
          for (final entry in entries)
            DataRow(
              cells: [
                DataCell(Text('${entry.rank}')),
                DataCell(
                  ConstrainedBox(
                    constraints: const BoxConstraints(minWidth: 150),
                    child: Text(entry.name),
                  ),
                ),
                DataCell(Text(entry.timeIn)),
                DataCell(Text('${entry.points}')),
              ],
            ),
        ],
      ),
    );
  }
}
