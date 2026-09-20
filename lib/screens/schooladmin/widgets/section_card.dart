part of '../sections_page.dart';

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.data,
    required this.studentCount,
    required this.selected,
    required this.onSelected,
    required this.onOpen,
  });

  final Map<String, dynamic> data;
  final int studentCount;
  final bool selected;
  final ValueChanged<bool> onSelected;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final name = data['name'] as String? ?? 'Untitled section';

    return InkWell(
      onTap: onOpen,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 13),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 680;
            final identity = Row(
              children: [
                Checkbox(
                  value: selected,
                  onChanged: (value) => onSelected(value == true),
                ),
                const SizedBox(width: 4),
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withAlpha(18),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.meeting_room_outlined,
                    size: 21,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            );
            final adviser = _SectionAdviserLine(section: data);
            final enrollment = Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.groups_outlined,
                  size: 18,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 7),
                Text(
                  '$studentCount ${studentCount == 1 ? 'student' : 'students'}',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            );
            if (compact) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  identity,
                  const SizedBox(height: 12),
                  adviser,
                  const SizedBox(height: 9),
                  enrollment,
                ],
              );
            }
            return Row(
              children: [
                Expanded(flex: 3, child: identity),
                const SizedBox(width: 18),
                Expanded(flex: 3, child: adviser),
                const SizedBox(width: 18),
                SizedBox(width: 120, child: enrollment),
                const SizedBox(width: 48),
                Icon(
                  Icons.chevron_right,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 16),
              ],
            );
          },
        ),
      ),
    );
  }

  static String formatAdviserName(String value) {
    final raw = value.trim();
    if (raw.isEmpty) return '';
    final commaParts = raw
        .split(',')
        .map((part) => part.trim())
        .where((part) => part.isNotEmpty)
        .toList();
    if (commaParts.length >= 2) {
      final middleInitial = commaParts.length >= 3 && commaParts[2].isNotEmpty
          ? ' ${commaParts[2][0]}.'
          : '';
      return '${commaParts[0]}, ${commaParts[1]}$middleInitial';
    }
    final parts = raw.split(RegExp(r'\s+'));
    if (parts.length < 2) return raw;
    final middleInitial = parts.length >= 3 ? ' ${parts[1][0]}.' : '';
    return '${parts.last}, ${parts.first}$middleInitial';
  }
}

class _SectionAdviserLine extends StatelessWidget {
  const _SectionAdviserLine({required this.section});

  final Map<String, dynamic> section;

  @override
  Widget build(BuildContext context) {
    final app = SchoolAdminViewModelScope.of(context);
    final adviserDocId = (section['adviserDocId'] as String? ?? '').trim();
    if (adviserDocId.isEmpty) {
      return const _CardLine(icon: Icons.person_outline, value: 'No adviser');
    }
    return FutureBuilder(
      future: app.attendance.activeSchoolYear(),
      builder: (context, schoolYearSnapshot) {
        final schoolYear = schoolYearSnapshot.data;
        if (schoolYear == null) {
          return const _CardLine(
            icon: Icons.person_outline,
            value: 'No adviser',
          );
        }
        return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: app.repository
              .schoolYearCollection(schoolYear.id, 'teachers')
              .doc(adviserDocId)
              .snapshots(),
          builder: (context, snapshot) {
            final data = snapshot.data?.data();
            if (data == null || data['archived'] == true) {
              return const _CardLine(
                icon: Icons.person_outline,
                value: 'No adviser',
              );
            }
            final name = [
              data['lastName'] as String? ?? '',
              data['firstName'] as String? ?? '',
              data['middleName'] as String? ?? '',
            ].where((part) => part.trim().isNotEmpty).join(', ');
            final adviserText = _SectionCard.formatAdviserName(name);
            return _CardLine(
              icon: Icons.person_outline,
              value: adviserText.isEmpty ? 'No adviser' : adviserText,
            );
          },
        );
      },
    );
  }
}
