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
    final gradeLevel = data['gradeLevel'] as String? ?? '';

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
                _CardLine(
                  icon: Icons.school_outlined,
                  value: gradeLevel.isEmpty ? '-' : gradeLevel,
                ),
                const SizedBox(height: 6),
                _CardLine(
                  icon: Icons.person_outline,
                  value: adviser.isEmpty ? 'No adviser' : adviser,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

enum _SectionCardAction { downloadQr, edit, archive }
