part of '../school_year_page.dart';

class _SchoolYearMeta extends StatelessWidget {
  const _SchoolYearMeta({required this.schoolYear});

  final SchoolYear schoolYear;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final app = SchoolAdminViewModelScope.of(context);

    return FutureBuilder<_SYCounts>(
      future: _SYCounts.load(app.app, schoolYear.id),
      builder: (context, snapshot) {
        final counts = snapshot.data;
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _StatusPill(status: schoolYear.displayStatus),
            const SizedBox(width: 10),
            if (counts == null)
              SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                  strokeWidth: 1.5,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              )
            else
              Text(
                '${counts.enrollments} enrollments · ${counts.sections} sections',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
              ),
          ],
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Expanded content: term chips + contextual action
// ─────────────────────────────────────────────────────────────────────────────
