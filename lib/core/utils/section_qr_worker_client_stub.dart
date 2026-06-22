import 'dart:typed_data';

class SectionQrWorkerStudent {
  const SectionQrWorkerStudent({
    required this.lrn,
    required this.lastName,
    required this.firstName,
    required this.middleName,
  });

  final String lrn;
  final String lastName;
  final String firstName;
  final String middleName;
}

class SectionQrWorkerProgress {
  const SectionQrWorkerProgress({
    required this.current,
    required this.total,
    this.studentName = '',
  });

  final int current;
  final int total;
  final String studentName;
}

Future<Uint8List> buildSectionQrZipInWorker({
  required String sectionName,
  required String gradeSection,
  required List<SectionQrWorkerStudent> students,
  void Function(SectionQrWorkerProgress progress)? onProgress,
}) {
  throw UnsupportedError('Student QR ZIP worker is only available on web.');
}

Future<Uint8List> buildTeacherQrZipInWorker({
  required List<SectionQrWorkerStudent> teachers,
  void Function(SectionQrWorkerProgress progress)? onProgress,
}) {
  throw UnsupportedError('Teacher QR ZIP worker is only available on web.');
}
