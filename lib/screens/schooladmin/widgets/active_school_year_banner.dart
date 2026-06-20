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

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF026B2F), Color(0xFF03913F)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF026B2F).withAlpha(40),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ACTIVE SCHOOL YEAR',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: Colors.white.withAlpha(190),
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  loading ? 'Loading...' : title,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.white.withAlpha(210),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              schoolYear == null ? 'Inactive' : 'Active',
              style: TextStyle(
                color: schoolYear == null
                    ? Colors.grey.shade800
                    : const Color(0xFF026B2F),
                fontWeight: FontWeight.w800,
                fontSize: 12,
              ),
            ),
          ),
        ],
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
