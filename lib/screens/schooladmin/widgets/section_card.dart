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
    final gradeLevel = data['gradeLevel'] as String? ?? '';
    final gradeText = gradeLevel.trim().isEmpty
        ? '-'
        : gradeLevel.trim().toLowerCase().startsWith('grade')
        ? gradeLevel
        : 'Grade $gradeLevel';
    final app = SchoolAdminViewModelScope.of(context);

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
                            _downloadStudentQrZip(context, data);
                        }
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: _SectionCardAction.downloadQr,
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
                _SectionAdviserLine(section: data),
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

  Future<void> _downloadStudentQrZip(
    BuildContext context,
    Map<String, dynamic> section,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    final app = SchoolAdminViewModelScope.of(context);
    final overlay = Overlay.of(context, rootOverlay: true);
    final progress = ValueNotifier(
      const SectionQrExportProgress(current: 0, total: 0),
    );
    final overlayEntry = OverlayEntry(
      builder: (_) => _SectionQrExportPanel(progress: progress),
    );
    overlay.insert(overlayEntry);
    try {
      await Future<void>.delayed(const Duration(milliseconds: 120));
      await SectionQrExporter(app.app).downloadSectionZip(
        section,
        onProgress: (value) => progress.value = value,
      );
      progress.value = progress.value.asDone();
      await Future<void>.delayed(const Duration(milliseconds: 900));
      messenger.showSnackBar(
        const SnackBar(content: Text('Student QR ZIP downloaded.')),
      );
    } catch (error) {
      progress.value = progress.value.asError(_friendlyDownloadError(error));
      await Future<void>.delayed(const Duration(seconds: 2));
      messenger.showSnackBar(
        SnackBar(content: Text(_friendlyDownloadError(error))),
      );
    } finally {
      overlayEntry.remove();
      progress.dispose();
    }
  }

  String _friendlyDownloadError(Object error) {
    final message = error.toString().replaceFirst('Exception: ', '').trim();
    return message.isEmpty ? 'Unable to download student QR ZIP.' : message;
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

class _SectionQrExportPanel extends StatelessWidget {
  const _SectionQrExportPanel({required this.progress});

  final ValueNotifier<SectionQrExportProgress> progress;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      right: 24,
      bottom: 24,
      child: Material(
        elevation: 14,
        borderRadius: BorderRadius.circular(8),
        color: Theme.of(context).colorScheme.surface,
        child: Container(
          width: 360,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: Theme.of(context).colorScheme.outlineVariant,
            ),
          ),
          child: ValueListenableBuilder<SectionQrExportProgress>(
            valueListenable: progress,
            builder: (context, value, _) {
              final hasError = value.errorMessage.isNotEmpty;
              final title = hasError
                  ? 'Download failed'
                  : value.done
                  ? 'Download ready'
                  : 'Preparing student QR ZIP';
              final status = hasError
                  ? value.errorMessage
                  : value.done
                  ? 'Starting ZIP download...'
                  : value.total == 0
                  ? 'Loading students...'
                  : 'Generated ${value.current} of ${value.total} QR IDs';

              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        hasError
                            ? Icons.error_outline
                            : value.done
                            ? Icons.check_circle_outline
                            : Icons.archive_outlined,
                        color: hasError
                            ? Theme.of(context).colorScheme.error
                            : Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          title,
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  LinearProgressIndicator(
                    value: hasError || value.done ? 1 : value.value,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    status,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  if (value.studentName.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      value.studentName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

enum _SectionCardAction { downloadQr, edit, archive }
