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

    return DataSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Top 10 Early',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              TabBar(
                controller: _tabController,
                isScrollable: true,
                labelColor: theme.colorScheme.primary,
                unselectedLabelColor: theme.colorScheme.onSurfaceVariant,
                indicatorColor: theme.colorScheme.primary,
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
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 380,
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

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SingleChildScrollView(
        child: DataTable(
          horizontalMargin: 8,
          columnSpacing: 16,
          dataRowMinHeight: 32,
          dataRowMaxHeight: 32,
          headingRowHeight: 32,
          columns: [
            const DataColumn(
              label: Text(
                'Rank',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            const DataColumn(
              label: Text('ID', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            const DataColumn(
              label: Text(
                'Name',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            if (isStudent)
              const DataColumn(
                label: Text(
                  'Section',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            const DataColumn(
              label: Text(
                'Points',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
          rows: [
            for (var i = 0; i < list.length; i++) ...[
              _buildDataRow(i + 1, list[i], isStudent, theme),
            ],
          ],
        ),
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
    Widget rankWidget;

    if (rank == 1) {
      rankColor = const Color(0xFFD4AF37); // Gold
      rankWeight = FontWeight.w900;
      rankWidget = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.emoji_events, color: rankColor, size: 15),
          const SizedBox(width: 4),
          Text(
            '$rank',
            style: TextStyle(color: rankColor, fontWeight: rankWeight),
          ),
        ],
      );
    } else if (rank == 2) {
      rankColor = const Color(0xFFC0C0C0); // Silver
      rankWeight = FontWeight.w800;
      rankWidget = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.emoji_events, color: rankColor, size: 15),
          const SizedBox(width: 4),
          Text(
            '$rank',
            style: TextStyle(color: rankColor, fontWeight: rankWeight),
          ),
        ],
      );
    } else if (rank == 3) {
      rankColor = const Color(0xFFCD7F32); // Bronze
      rankWeight = FontWeight.w800;
      rankWidget = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.emoji_events, color: rankColor, size: 15),
          const SizedBox(width: 4),
          Text(
            '$rank',
            style: TextStyle(color: rankColor, fontWeight: rankWeight),
          ),
        ],
      );
    } else {
      rankWidget = Text('$rank', style: const TextStyle(color: Colors.grey));
    }

    return DataRow(
      cells: [
        DataCell(rankWidget),
        DataCell(Text(performer.id)),
        DataCell(
          Text(
            performer.name,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
        if (isStudent) DataCell(Text(performer.section)),
        DataCell(
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withAlpha(20),
              borderRadius: BorderRadius.circular(10),
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
