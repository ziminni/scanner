part of '../school_admin_dashboard_page.dart';

class _ActiveSchoolYearBanner extends StatelessWidget {
  const _ActiveSchoolYearBanner({this.schoolYear, required this.loading});

  final SchoolYear? schoolYear;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final title = schoolYear?.name ?? 'No active school year';
    final subtitle = schoolYear == null
        ? 'Create a school year to begin collecting attendance data'
        : _schoolYearRange(schoolYear!);

    return RepaintBoundary(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 520;
          final details = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'ACTIVE SCHOOL YEAR',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: Colors.white.withAlpha(190),
                  fontWeight: FontWeight.w900,
                  letterSpacing: .7,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                loading ? 'Loading...' : title,
                maxLines: compact ? 2 : 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                subtitle,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.white.withAlpha(220),
                ),
              ),
            ],
          );
          final pill = Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(236),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              schoolYear == null ? 'Inactive' : 'Active',
              style: TextStyle(
                color: schoolYear == null
                    ? Colors.grey.shade800
                    : const Color(0xFF026B2F),
                fontWeight: FontWeight.w900,
                fontSize: 12,
              ),
            ),
          );

          return Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF064E3B), Color(0xFF059669)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF026B2F).withAlpha(20),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: compact
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Align(alignment: Alignment.centerLeft, child: pill),
                      const SizedBox(height: 14),
                      details,
                    ],
                  )
                : Row(
                    children: [
                      Expanded(child: details),
                      const SizedBox(width: 16),
                      pill,
                    ],
                  ),
          );
        },
      ),
    );
  }

  static String _schoolYearRange(SchoolYear schoolYear) {
    final start = schoolYear.termStarts.whereType<DateTime>().firstOrNull;
    final end = schoolYear.termEnds.whereType<DateTime>().lastOrNull;
    if (start == null && end == null) return 'Date range not set';
    final formatter = DateFormat('MMM d, yyyy');
    return '${start == null ? 'Not set' : formatter.format(start)} - ${end == null ? 'Not set' : formatter.format(end)}';
  }
}
