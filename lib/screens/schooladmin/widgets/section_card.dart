part of '../sections_page.dart';

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.data,
    required this.onOpen,
    required this.onEdit,
    required this.onArchive,
  });

  final Map<String, dynamic> data;
  final VoidCallback onOpen;
  final VoidCallback onEdit;
  final VoidCallback onArchive;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final name = data['name'] as String? ?? 'Untitled section';
    final adviser = data['adviser'] as String? ?? '';
    final adviserText = _formatAdviserName(adviser);
    final gradeLevel = data['gradeLevel'] as String? ?? '';
    final gradeText = gradeLevel.trim().isEmpty
        ? '-'
        : gradeLevel.trim().toLowerCase().startsWith('grade')
        ? gradeLevel
        : 'Grade $gradeLevel';
    final app = AppScope.of(context);

    return SizedBox(
      width: 260,
      child: Material(
        color: theme.colorScheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: theme.colorScheme.outlineVariant),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: onOpen,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        name,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    PopupMenuButton<_SectionCardAction>(
                      tooltip: 'Section actions',
                      icon: const Icon(Icons.more_vert),
                      onSelected: (action) {
                        switch (action) {
                          case _SectionCardAction.edit:
                            onEdit();
                          case _SectionCardAction.archive:
                            onArchive();
                          case _SectionCardAction.downloadQr:
                            break;
                        }
                      },
                      itemBuilder: (context) => const [
                        PopupMenuItem(
                          value: _SectionCardAction.downloadQr,
                          enabled: false,
                          child: ListTile(
                            dense: true,
                            leading: Icon(Icons.qr_code_2_outlined),
                            title: Text('Download Students QR'),
                          ),
                        ),
                        PopupMenuItem(
                          value: _SectionCardAction.edit,
                          child: ListTile(
                            dense: true,
                            leading: Icon(Icons.edit_outlined),
                            title: Text('Edit details'),
                          ),
                        ),
                        PopupMenuItem(
                          value: _SectionCardAction.archive,
                          child: ListTile(
                            dense: true,
                            leading: Icon(Icons.archive_outlined),
                            title: Text('Archive section'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                _CardLine(icon: Icons.school_outlined, value: gradeText),
                const SizedBox(height: 6),
                _CardLine(
                  icon: Icons.person_outline,
                  value: adviserText.isEmpty ? 'No adviser' : adviserText,
                ),
                const SizedBox(height: 6),
                FutureBuilder(
                  future: app.attendance.activeSchoolYear(),
                  builder: (context, schoolYearSnapshot) {
                    final schoolYear = schoolYearSnapshot.data;
                    if (schoolYear == null || name.trim().isEmpty) {
                      return const _CardLine(
                        icon: Icons.groups_outlined,
                        value: '0 students',
                      );
                    }

                    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                      stream: app.repository.studentsBySectionStream(
                        schoolYearId: schoolYear.id,
                        sectionName: name,
                      ),
                      builder: (context, snapshot) {
                        final count = snapshot.data?.docs.length ?? 0;
                        return _CardLine(
                          icon: Icons.groups_outlined,
                          value:
                              '$count ${count == 1 ? 'student' : 'students'}',
                        );
                      },
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatAdviserName(String value) {
    final raw = value.trim();
    if (raw.isEmpty) return '';
    final commaParts = raw
        .split(',')
        .map((part) => part.trim())
        .where((part) => part.isNotEmpty)
        .toList();
    if (commaParts.length >= 2) {
      final lastName = commaParts[0];
      final firstName = commaParts[1];
      final middleName = commaParts.length >= 3 ? commaParts[2] : '';
      final middleInitial = middleName.isEmpty ? '' : ' ${middleName[0]}.';
      return '$lastName, $firstName$middleInitial';
    }

    final parts = raw.split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      final lastName = parts.last;
      final firstName = parts.first;
      final middleInitial = parts.length >= 3 ? ' ${parts[1][0]}.' : '';
      return '$lastName, $firstName$middleInitial';
    }
    return raw;
  }
}

enum _SectionCardAction { downloadQr, edit, archive }
