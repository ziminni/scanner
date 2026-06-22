part of '../reports_export_page.dart';

class _TeacherQrDownloadCard extends StatefulWidget {
  const _TeacherQrDownloadCard();

  @override
  State<_TeacherQrDownloadCard> createState() => _TeacherQrDownloadCardState();
}

class _TeacherQrDownloadCardState extends State<_TeacherQrDownloadCard> {
  bool _downloading = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      width: 420,
      child: DataSurface(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withAlpha(24),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.qr_code_2_outlined,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Teachers QR IDs',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Download a ZIP file containing QR ID cards for all active teachers in the current school year.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: _downloading ? null : () => _download(context),
              icon: _downloading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.download_outlined),
              label: Text(
                _downloading ? 'Preparing QR ZIP' : 'Download Teachers QR',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _download(BuildContext context) async {
    final app = SchoolAdminViewModelScope.of(context);
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _downloading = true);
    try {
      final schoolYear = await app.attendance.activeSchoolYear();
      if (schoolYear == null) {
        messenger.showSnackBar(
          const SnackBar(content: Text('Create an active school year first.')),
        );
        return;
      }

      final snapshot = await app.repository
          .schoolYearCollection(schoolYear.id, 'teachers')
          .where('archived', isEqualTo: false)
          .get();
      final teachers = snapshot.docs.map(Teacher.fromDoc).toList()
        ..sort((a, b) {
          final lastName = a.lastName.compareTo(b.lastName);
          return lastName == 0 ? a.firstName.compareTo(b.firstName) : lastName;
        });
      if (teachers.isEmpty) {
        messenger.showSnackBar(
          const SnackBar(content: Text('No active teachers to download yet.')),
        );
        return;
      }

      final bytes = await buildTeacherQrZipInWorker(
        teachers: [
          for (final teacher in teachers)
            SectionQrWorkerStudent(
              lrn: teacher.teacherId,
              lastName: teacher.lastName,
              firstName: teacher.firstName,
              middleName: teacher.middleName,
            ),
        ],
      );
      downloadBytes(
        fileName: '${_fileSafeName(schoolYear.name)}-teachers-qr.zip',
        bytes: bytes,
        mimeType: 'application/zip',
      );
      await app.audit.record(
        action: 'teachers_qr_zip_downloaded',
        actorId: app.currentUser!.id,
        actorName: app.currentUser!.fullName,
        target: schoolYear.name,
        metadata: {'teacherCount': teachers.length},
      );
      messenger.showSnackBar(
        const SnackBar(content: Text('Teachers QR ZIP downloaded.')),
      );
    } catch (error) {
      messenger.showSnackBar(
        SnackBar(content: Text('Could not download Teachers QR: $error')),
      );
    } finally {
      if (mounted) setState(() => _downloading = false);
    }
  }

  String _fileSafeName(String value) {
    return value
        .trim()
        .replaceAll(RegExp(r'[^A-Za-z0-9._-]+'), '-')
        .replaceAll(RegExp(r'-+'), '-')
        .replaceAll(RegExp(r'^-|-$'), '');
  }
}
