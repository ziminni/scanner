part of '../students_page.dart';

class _UnassignedStudentsNotice extends StatelessWidget {
  const _UnassignedStudentsNotice({required this.onView});

  final VoidCallback onView;

  @override
  Widget build(BuildContext context) {
    final app = SchoolAdminViewModelScope.of(context);
    final theme = Theme.of(context);
    return FutureBuilder(
      future: app.attendance.activeSchoolYear(),
      builder: (context, schoolYearSnapshot) {
        final schoolYear = schoolYearSnapshot.data;
        if (schoolYear == null) return const SizedBox.shrink();

        return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: app.repository
              .schoolYearCollection(schoolYear.id, 'students')
              .where('archived', isEqualTo: false)
              .snapshots(),
          builder: (context, snapshot) {
            final unassignedCount = (snapshot.data?.docs ?? []).where((doc) {
              final section = (doc.data()['section'] as String? ?? '').trim();
              return section.isEmpty;
            }).length;
            if (unassignedCount == 0) return const SizedBox.shrink();

            return Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: theme.colorScheme.errorContainer.withAlpha(95),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: theme.colorScheme.error.withAlpha(70),
                ),
              ),
              child: Wrap(
                spacing: 12,
                runSpacing: 10,
                crossAxisAlignment: WrapCrossAlignment.center,
                alignment: WrapAlignment.spaceBetween,
                children: [
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 720),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.warning_amber_outlined,
                          color: theme.colorScheme.error,
                        ),
                        const SizedBox(width: 10),
                        Flexible(
                          child: Text(
                            '$unassignedCount active ${unassignedCount == 1 ? 'student has' : 'students have'} no assigned section. Please assign ${unassignedCount == 1 ? 'this student' : 'them'} to a section.',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onErrorContainer,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  TextButton.icon(
                    onPressed: onView,
                    icon: const Icon(Icons.visibility_outlined),
                    label: const Text('View unassigned'),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
