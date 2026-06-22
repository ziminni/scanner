// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use

import 'dart:async';
import 'dart:html' as html;
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

  Map<String, String> toMap() => {
    'lrn': lrn,
    'lastName': lastName,
    'firstName': firstName,
    'middleName': middleName,
  };
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
  return _buildQrZipInWorker(
    sectionName: sectionName,
    gradeSection: gradeSection,
    people: students,
    onProgress: onProgress,
  );
}

Future<Uint8List> buildTeacherQrZipInWorker({
  required List<SectionQrWorkerStudent> teachers,
  void Function(SectionQrWorkerProgress progress)? onProgress,
}) {
  return _buildQrZipInWorker(
    sectionName: 'teachers_qr',
    gradeSection: 'Teachers',
    people: teachers,
    identifierLabel: 'Teacher ID',
    cardTitle: 'TEMPORARY TEACHER ID',
    onProgress: onProgress,
  );
}

Future<Uint8List> _buildQrZipInWorker({
  required String sectionName,
  required String gradeSection,
  required List<SectionQrWorkerStudent> people,
  String identifierLabel = 'LRN',
  String cardTitle = 'TEMPORARY STUDENT ID',
  void Function(SectionQrWorkerProgress progress)? onProgress,
}) {
  final completer = Completer<Uint8List>();
  final worker = html.Worker('section_qr_worker.js');
  late final StreamSubscription<html.MessageEvent> subscription;
  late final StreamSubscription<html.Event> errorSubscription;

  void cleanup() {
    subscription.cancel();
    errorSubscription.cancel();
    worker.terminate();
  }

  subscription = worker.onMessage.listen((event) {
    final data = event.data;
    if (data is! Map) return;
    final type = data['type'] as String? ?? '';
    if (type == 'progress') {
      onProgress?.call(
        SectionQrWorkerProgress(
          current: data['current'] as int? ?? 0,
          total: data['total'] as int? ?? 0,
          studentName: data['studentName'] as String? ?? '',
        ),
      );
      return;
    }
    if (type == 'done') {
      final bytes = data['bytes'];
      cleanup();
      if (bytes is ByteBuffer) {
        completer.complete(Uint8List.view(bytes));
      } else if (bytes is Uint8List) {
        completer.complete(bytes);
      } else {
        completer.completeError(Exception('QR ZIP worker returned no file.'));
      }
      return;
    }
    if (type == 'error') {
      cleanup();
      completer.completeError(
        Exception(data['message'] as String? ?? 'Unable to create QR ZIP.'),
      );
    }
  });

  errorSubscription = worker.onError.listen((event) {
    cleanup();
    if (!completer.isCompleted) {
      completer.completeError(Exception('QR ZIP worker failed to start.'));
    }
  });

  worker.postMessage({
    'sectionName': sectionName,
    'gradeSection': gradeSection,
    'students': people.map((person) => person.toMap()).toList(),
    'identifierLabel': identifierLabel,
    'cardTitle': cardTitle,
  });
  return completer.future;
}
