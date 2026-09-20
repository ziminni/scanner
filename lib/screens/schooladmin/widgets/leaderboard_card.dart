part of '../school_admin_dashboard_page.dart';

class _LeaderboardCard extends StatefulWidget {
  const _LeaderboardCard({required this.performers});

  final Map<String, List<_Performer>> performers;

  @override
  State<_LeaderboardCard> createState() => _LeaderboardCardState();
}

class _LeaderboardCardState extends State<_LeaderboardCard>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final students = widget.performers['students'] ?? [];
    final teachers = widget.performers['teachers'] ?? [];

    return RepaintBoundary(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: _dashboardCardDecoration(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _DashboardCardHeader(
              title: 'Top 10 Early',
              subtitle: 'People with the strongest early/on-time streaks.',
              icon: Icons.emoji_events_outlined,
            ),
            const SizedBox(height: 14),
            Container(
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withAlpha(95),
                borderRadius: BorderRadius.circular(16),
              ),
              child: TabBar(
                controller: _tabController,
                indicatorSize: TabBarIndicatorSize.tab,
                labelColor: theme.colorScheme.primary,
                unselectedLabelColor: theme.colorScheme.onSurfaceVariant,
                indicator: BoxDecoration(
                  color: theme.colorScheme.primary.withAlpha(22),
                  borderRadius: BorderRadius.circular(14),
                ),
                dividerColor: Colors.transparent,
                tabs: const [
                  Tab(
                    icon: Icon(Icons.school_outlined, size: 18),
                    text: 'Students',
                  ),
                  Tab(
                    icon: Icon(Icons.badge_outlined, size: 18),
                    text: 'Teachers',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 360,
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildLeaderboardTable(students, isStudent: true),
                  _buildLeaderboardTable(teachers, isStudent: false),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLeaderboardTable(
    List<_Performer> list, {
    required bool isStudent,
  }) {
    if (list.isEmpty) {
      return const Center(child: Text('No check-in rankings available yet.'));
    }

    final theme = Theme.of(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: ConstrainedBox(
              constraints: BoxConstraints(minWidth: constraints.maxWidth),
              child: DataTable(
                headingRowHeight: 40,
                dataRowMinHeight: 42,
                dataRowMaxHeight: 48,
                horizontalMargin: 14,
                columnSpacing: 18,
                headingTextStyle: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w800,
                ),
                dataTextStyle: theme.textTheme.bodySmall,
                decoration: BoxDecoration(
                  border: Border.all(color: theme.dividerColor.withAlpha(80)),
                  borderRadius: BorderRadius.circular(16),
                ),
                columns: [
                  const DataColumn(label: Text('Rank')),
                  const DataColumn(label: Text('ID')),
                  const DataColumn(label: Text('Name')),
                  if (isStudent) const DataColumn(label: Text('Section')),
                  const DataColumn(label: Text('Points')),
                ],
                rows: [
                  for (var i = 0; i < list.length; i++)
                    _buildDataRow(i + 1, list[i], isStudent, theme),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _rankChip(int rank, Color color, FontWeight rankWeight) {
    final isTopThree = rank <= 3;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: isTopThree ? color.withAlpha(25) : Colors.black.withAlpha(5),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isTopThree) ...[
            Icon(Icons.emoji_events, color: color, size: 14),
            const SizedBox(width: 4),
          ],
          Text(
            '$rank',
            style: TextStyle(
              color: isTopThree ? color : Colors.grey.shade700,
              fontWeight: rankWeight,
            ),
          ),
        ],
      ),
    );
  }

  DataRow _buildDataRow(
    int rank,
    _Performer performer,
    bool isStudent,
    ThemeData theme,
  ) {
    Color rankColor;
    FontWeight rankWeight = FontWeight.normal;

    if (rank == 1) {
      rankColor = const Color(0xFFD4AF37);
      rankWeight = FontWeight.w900;
    } else if (rank == 2) {
      rankColor = const Color(0xFFC0C0C0);
      rankWeight = FontWeight.w800;
    } else if (rank == 3) {
      rankColor = const Color(0xFFCD7F32);
      rankWeight = FontWeight.w800;
    } else {
      rankColor = Colors.grey.shade700;
    }

    return DataRow(
      color: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.hovered)) {
          return theme.colorScheme.primary.withAlpha(12);
        }
        return rank.isEven ? Colors.black.withAlpha(3) : Colors.transparent;
      }),
      cells: [
        DataCell(_rankChip(rank, rankColor, rankWeight)),
        DataCell(Text(performer.id)),
        DataCell(
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 220),
            child: Text(
              performer.name,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ),
        if (isStudent)
          DataCell(
            Text(
              performer.section.trim().isEmpty ? '-' : performer.section,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        DataCell(
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withAlpha(20),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              '${performer.points} pts',
              style: TextStyle(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
