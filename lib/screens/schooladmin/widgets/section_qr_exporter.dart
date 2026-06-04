part of '../sections_page.dart';

class SectionQrExporter {
  SectionQrExporter(this._app);

  final AppController _app;

  Future<void> downloadSectionZip(
    Map<String, dynamic> section, {
    ValueChanged<SectionQrExportProgress>? onProgress,
  }) async {
    final sectionName = (section['name'] as String? ?? '').trim();
    final gradeLevel = (section['gradeLevel'] as String? ?? '').trim();
    if (sectionName.isEmpty) {
      throw Exception('Section name is missing.');
    }

    final schoolYear = await _app.attendance.activeSchoolYear();
    if (schoolYear == null) {
      throw Exception(
        'Create an active school year before downloading QR IDs.',
      );
    }

    final snapshot = await _app.repository
        .schoolYearCollection(schoolYear.id, 'students')
        .where('section', isEqualTo: sectionName)
        .where('archived', isEqualTo: false)
        .get();
    final students = snapshot.docs.map(Student.fromDoc).toList()
      ..sort((a, b) {
        final lastCompare = a.lastName.compareTo(b.lastName);
        if (lastCompare != 0) return lastCompare;
        return a.firstName.compareTo(b.firstName);
      });

    if (students.isEmpty) {
      throw Exception('No active students found in $sectionName.');
    }

    final zipBytes = await buildSectionQrZipInWorker(
      sectionName: sectionName,
      gradeSection: '${_gradeLabel(gradeLevel)} - $sectionName',
      students: [
        for (final student in students)
          SectionQrWorkerStudent(
            lrn: student.lrn,
            lastName: student.lastName,
            firstName: student.firstName,
            middleName: student.middleName,
          ),
      ],
      onProgress: (progress) {
        onProgress?.call(
          SectionQrExportProgress(
            current: progress.current,
            total: progress.total,
            studentName: progress.studentName,
          ),
        );
      },
    );

    downloadBytes(
      fileName: '${_safeFileName(sectionName)}.zip',
      bytes: zipBytes,
      mimeType: 'application/zip',
    );
  }

  String _gradeLabel(String gradeLevel) {
    if (gradeLevel.isEmpty) return 'Grade';
    if (gradeLevel.toLowerCase().startsWith('grade')) return gradeLevel;
    return 'Grade $gradeLevel';
  }

  String _safeFileName(String value) {
    final sanitized = value
        .replaceAll(RegExp(r'[\\/:*?"<>|]'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    return sanitized.isEmpty ? 'students_qr' : sanitized;
  }
}

class SectionQrExportProgress {
  const SectionQrExportProgress({
    required this.current,
    required this.total,
    this.studentName = '',
    this.done = false,
    this.errorMessage = '',
  });

  final int current;
  final int total;
  final String studentName;
  final bool done;
  final String errorMessage;

  double? get value => total == 0 ? null : current / total;

  SectionQrExportProgress asDone() {
    return SectionQrExportProgress(current: total, total: total, done: true);
  }

  SectionQrExportProgress asError(String message) {
    return SectionQrExportProgress(
      current: current,
      total: total,
      studentName: studentName,
      errorMessage: message,
    );
  }
}
