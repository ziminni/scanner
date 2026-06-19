import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart' as fp;
import 'package:intl/intl.dart';
import 'package:spreadsheet_decoder/spreadsheet_decoder.dart';

import '../../../core/services/app_controller.dart';
import 'base_viewmodel.dart';

class ImportStudentsViewModel extends BaseViewModel {
  ImportStudentsViewModel(this._app);

  static const _expectedHeaders = [
    'lrn',
    'lastname',
    'firstname',
    'middlename',
    'gender',
    'birthdate',
    'address',
    'guardianname',
    'guardiancontact',
  ];

  final AppController _app;
  Uint8List? _bytes;
  String? fileName;
  String? selectedSection;
  int importedCount = 0;

  bool get hasFile => _bytes != null;

  Stream<QuerySnapshot<Map<String, dynamic>>> get sectionsStream =>
      _app.repository.activeSectionsStream();

  void selectSection(String? section) {
    selectedSection = section;
    notifyListeners();
  }

  Future<void> pickFile() async {
    final result = await fp.FilePicker.pickFiles(
      type: fp.FileType.custom,
      allowedExtensions: ['xlsx'],
      withData: true,
    );
    final file = result?.files.single;
    if (file == null) return;
    if (!file.name.toLowerCase().endsWith('.xlsx')) {
      setError('Please upload an Excel file with the .xlsx extension.');
      return;
    }
    if (file.bytes == null) {
      setError(
        'We could not read that file. Please choose another .xlsx file.',
      );
      return;
    }
    _bytes = file.bytes;
    fileName = file.name;
    importedCount = 0;
    setError(null);
    notifyListeners();
  }

  Future<bool> importStudents() async {
    final bytes = _bytes;
    final section = selectedSection;
    if (section == null) {
      setError(
        'Please choose the section where these students should be added.',
      );
      return false;
    }
    if (bytes == null) {
      setError('Please choose a .xlsx spreadsheet first.');
      return false;
    }

    setBusy(true);
    try {
      final schoolYear = await _app.attendance.activeSchoolYear();
      if (schoolYear == null) {
        setError('Create an active school year before importing students.');
        return false;
      }

      final records = _parseRecords(
        bytes,
        schoolYear.id,
        schoolYear.name,
        section,
      );
      if (records.isEmpty) {
        setError(
          'No student rows were found. Check that your file has data below the header row.',
        );
        return false;
      }
      final duplicateLrns = _duplicateLrns(records);
      if (duplicateLrns.isNotEmpty) {
        setError(
          'Some LRNs appear more than once in the spreadsheet: ${duplicateLrns.take(5).join(', ')}.',
        );
        return false;
      }

      final existingLrns = await _app.repository.schoolYearFieldValues(
        schoolYearId: schoolYear.id,
        collection: 'students',
        field: 'lrn',
      );
      final alreadyExisting =
          records
              .map((record) => record['lrn']?.toString().trim() ?? '')
              .where((lrn) => existingLrns.contains(lrn.toLowerCase()))
              .toSet()
              .toList()
            ..sort();
      if (alreadyExisting.isNotEmpty) {
        setError('LRN already exists: ${alreadyExisting.take(5).join(', ')}');
        return false;
      }

      final user = _app.currentUser;
      if (user == null) {
        setError('Your session expired. Please log in again.');
        return false;
      }

      await _app.repository.addSchoolYearRecords(
        schoolYear: schoolYear,
        collection: 'students',
        records: records,
      );
      await _app.audit.record(
        action: 'students_imported',
        actorId: user.id,
        actorName: user.fullName,
        target: fileName ?? 'Student spreadsheet',
        metadata: {
          'count': records.length,
          'schoolYear': schoolYear.name,
          'section': section,
        },
      );
      importedCount = records.length;
      setError(null);
      return true;
    } on FormatException catch (error) {
      setError(error.message);
      return false;
    } catch (error) {
      setError(_friendlyError(error));
      return false;
    } finally {
      setBusy(false);
    }
  }

  List<Map<String, dynamic>> _parseRecords(
    Uint8List bytes,
    String schoolYearId,
    String schoolYearName,
    String section,
  ) {
    final spreadsheet = SpreadsheetDecoder.decodeBytes(bytes, update: false);
    final sheetName = spreadsheet.tables.keys.firstOrNull;
    if (sheetName == null) {
      throw const FormatException('No worksheet was found in the spreadsheet.');
    }
    final rows = spreadsheet.tables[sheetName]?.rows ?? [];
    if (rows.length <= 1) {
      throw const FormatException(
        'The spreadsheet needs a header row and at least one student row.',
      );
    }
    _validateHeaders(rows.first);

    final records = <Map<String, dynamic>>[];
    for (var index = 1; index < rows.length; index++) {
      final row = rows[index];
      final lrn = _text(row, 0);
      final lastName = _text(row, 1);
      final firstName = _text(row, 2);
      final rowNumber = index + 1;
      if (_isBlankRow(row)) continue;
      if (lrn.isEmpty || lastName.isEmpty || firstName.isEmpty) {
        throw FormatException(
          'Row $rowNumber must include LRN, last name, and first name.',
        );
      }

      records.add({
        'lrn': lrn,
        'lastName': lastName,
        'firstName': firstName,
        'middleName': _text(row, 3),
        'gender': _gender(row, 4, rowNumber),
        'birthdate': _date(row, 5),
        'address': _text(row, 6),
        'guardianName': _text(row, 7),
        'guardianContact': _text(row, 8),
        'section': section,
        'status': 'Active',
        'schoolYearId': schoolYearId,
        'schoolYear': schoolYearName,
        'archived': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
    return records;
  }

  void _validateHeaders(List<dynamic> headerRow) {
    final actual = [
      for (var index = 0; index < _expectedHeaders.length; index++)
        _normalizeHeader(_text(headerRow, index)),
    ];
    for (var index = 0; index < _expectedHeaders.length; index++) {
      if (actual[index] != _expectedHeaders[index]) {
        throw FormatException(
          'Column ${index + 1} should be ${_displayHeader(_expectedHeaders[index])}. Please check the header row.',
        );
      }
    }
  }

  List<String> _duplicateLrns(List<Map<String, dynamic>> records) {
    final seen = <String>{};
    final duplicates = <String>{};
    for (final record in records) {
      final lrn = record['lrn']?.toString().trim() ?? '';
      final key = lrn.toLowerCase();
      if (key.isEmpty) continue;
      if (!seen.add(key)) duplicates.add(lrn);
    }
    return duplicates.toList()..sort();
  }

  bool _isBlankRow(List<dynamic> row) {
    return row.every((cell) {
      if (cell == null) return true;
      return cell.toString().trim().isEmpty;
    });
  }

  String _normalizeHeader(String value) {
    return value.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
  }

  String _displayHeader(String normalized) {
    return switch (normalized) {
      'lrn' => 'LRN',
      'lastname' => 'Last name',
      'firstname' => 'First name',
      'middlename' => 'Middle name',
      'gender' => 'Gender',
      'birthdate' => 'Birthdate',
      'address' => 'Address',
      'guardianname' => 'Guardian name',
      'guardiancontact' => 'Guardian contact',
      _ => normalized,
    };
  }

  String _text(List<dynamic> row, int index) {
    if (index >= row.length) return '';
    final value = row[index];
    if (value == null) return '';
    return value.toString().trim();
  }

  String _gender(List<dynamic> row, int index, int rowNumber) {
    final value = _text(row, index).toLowerCase();
    return switch (value) {
      'male' || 'm' => 'Male',
      'female' || 'f' => 'Female',
      _ => throw FormatException(
        'Row $rowNumber has an invalid gender. Use Male or Female.',
      ),
    };
  }

  Timestamp? _date(List<dynamic> row, int index) {
    if (index >= row.length) return null;
    final value = row[index];
    final date = value is DateTime
        ? value
        : _parseDateText(value?.toString() ?? '');
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

  String _friendlyError(Object error) {
    final message = error.toString();
    if (message.contains('Unexpected null value')) {
      return 'We could not read the spreadsheet format. Please make sure it is a valid .xlsx file and try again.';
    }
    if (message.contains('Zip')) {
      return 'The selected file does not look like a valid .xlsx spreadsheet.';
    }
    if (message.contains('permission-denied')) {
      return 'You do not have permission to import students.';
    }
    return 'Import failed. Please check the spreadsheet and try again.';
  }
}
