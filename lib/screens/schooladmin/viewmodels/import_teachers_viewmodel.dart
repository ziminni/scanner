import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:excel/excel.dart';
import 'package:file_picker/file_picker.dart' as fp;
import 'package:intl/intl.dart';

import '../../../core/services/app_controller.dart';
import 'base_viewmodel.dart';

class ImportTeachersViewModel extends BaseViewModel {
  ImportTeachersViewModel(this._app);

  final AppController _app;
  Uint8List? _bytes;
  String? fileName;
  int importedCount = 0;

  bool get hasFile => _bytes != null;

  Future<void> pickFile() async {
    final result = await fp.FilePicker.pickFiles(
      type: fp.FileType.custom,
      allowedExtensions: ['xlsx'],
      withData: true,
    );
    final file = result?.files.single;
    if (file == null) return;
    if (file.bytes == null) {
      setError('Could not read the selected file.');
      return;
    }
    _bytes = file.bytes;
    fileName = file.name;
    importedCount = 0;
    setError(null);
    notifyListeners();
  }

  Future<bool> importTeachers() async {
    final bytes = _bytes;
    if (bytes == null) {
      setError('Select a spreadsheet first.');
      return false;
    }

    setBusy(true);
    try {
      final schoolYear = await _app.attendance.activeSchoolYear();
      if (schoolYear == null) {
        setError('Create an active school year before importing teachers.');
        return false;
      }

      final records = _parseRecords(bytes, schoolYear.id, schoolYear.name);
      if (records.isEmpty) {
        setError('No valid teacher rows found.');
        return false;
      }

      await _app.repository.addSchoolYearRecords(
        schoolYear: schoolYear,
        collection: 'teachers',
        records: records,
      );
      await _app.audit.record(
        action: 'teachers_imported',
        actorId: _app.currentUser!.id,
        actorName: _app.currentUser!.fullName,
        target: fileName ?? 'Teacher spreadsheet',
        metadata: {'count': records.length, 'schoolYear': schoolYear.name},
      );
      importedCount = records.length;
      setError(null);
      return true;
    } catch (error) {
      setError(error.toString());
      return false;
    } finally {
      setBusy(false);
    }
  }

  List<Map<String, dynamic>> _parseRecords(
    Uint8List bytes,
    String schoolYearId,
    String schoolYearName,
  ) {
    final excel = Excel.decodeBytes(bytes);
    final sheetName = excel.tables.keys.firstOrNull;
    if (sheetName == null) return [];
    final rows = excel.tables[sheetName]?.rows ?? [];
    if (rows.length <= 1) return [];

    final records = <Map<String, dynamic>>[];
    for (var index = 1; index < rows.length; index++) {
      final row = rows[index];
      final teacherId = _text(row, 0);
      final lastName = _text(row, 1);
      final firstName = _text(row, 2);
      if (teacherId.isEmpty || lastName.isEmpty || firstName.isEmpty) continue;

      records.add({
        'teacherId': teacherId,
        'lastName': lastName,
        'firstName': firstName,
        'middleName': _text(row, 3),
        'birthdate': _date(row, 4),
        'address': _text(row, 5),
        'contactNumber': _text(row, 6),
        'assignedTimeIn': _time(row, 7),
        'assignedTimeOut': _time(row, 8),
        'status': 'Active',
        'schoolYearId': schoolYearId,
        'schoolYear': schoolYearName,
        'archived': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
    return records;
  }

  String _text(List<Data?> row, int index) {
    if (index >= row.length) return '';
    final value = row[index]?.value;
    if (value == null) return '';
    return switch (value) {
      TextCellValue(:final value) => (value.text ?? '').trim(),
      DateCellValue() ||
      DateTimeCellValue() ||
      TimeCellValue() => value.toString().trim(),
      _ => value.toString().trim(),
    };
  }

  Timestamp? _date(List<Data?> row, int index) {
    if (index >= row.length) return null;
    final value = row[index]?.value;
    final date = switch (value) {
      DateCellValue() => value.asDateTimeLocal(),
      DateTimeCellValue() => value.asDateTimeLocal(),
      TextCellValue(:final value) => _parseDateText(value.text ?? ''),
      _ => _parseDateText(value?.toString() ?? ''),
    };
    return date == null ? null : Timestamp.fromDate(date);
  }

  DateTime? _parseDateText(String raw) {
    final value = raw.trim();
    if (value.isEmpty) return null;
    final iso = DateTime.tryParse(value);
    if (iso != null) return iso;
    for (final pattern in ['MM/dd/yyyy', 'M/d/yyyy', 'yyyy-MM-dd']) {
      try {
        return DateFormat(pattern).parseStrict(value);
      } catch (_) {}
    }
    return null;
  }

  String _time(List<Data?> row, int index) {
    if (index >= row.length) return '';
    final value = row[index]?.value;
    final parsed = switch (value) {
      TimeCellValue() => _formatTime(value.hour, value.minute),
      DateTimeCellValue() => _formatTime(value.hour, value.minute),
      TextCellValue(:final value) => _parseTimeText(value.text ?? ''),
      _ => _parseTimeText(value?.toString() ?? ''),
    };
    return parsed;
  }

  String _parseTimeText(String raw) {
    final value = raw.trim();
    if (value.isEmpty) return '';
    for (final pattern in ['HH:mm', 'H:mm', 'h:mm a', 'h:mma']) {
      try {
        final date = DateFormat(pattern).parseStrict(value.toUpperCase());
        return _formatTime(date.hour, date.minute);
      } catch (_) {}
    }
    return value;
  }

  String _formatTime(int hour, int minute) {
    return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
  }
}
