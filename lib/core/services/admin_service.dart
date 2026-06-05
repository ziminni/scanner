import 'dart:convert';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:excel/excel.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../constants/enums.dart';
import '../../models/models.dart';
import '../../firebase_options.dart';
import 'audit_service.dart';

class AdminService {
  AdminService(this._firestore, this._auth, this._storage, this._audit);

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final FirebaseStorage _storage;
  final AuditService _audit;

  Stream<QuerySnapshot<Map<String, dynamic>>> collectionStream(
    String collection,
  ) {
    return _firestore
        .collection(collection)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  Future<void> createUser({
    required String email,
    required String password,
    required String fullName,
    required UserRole role,
    AccountStatus status = AccountStatus.active,
    required AppUser actor,
  }) async {
    final normalizedEmail = email.trim().toLowerCase();
    if (fullName.trim().isEmpty) {
      throw StateError('Full name is required.');
    }
    if (!normalizedEmail.contains('@')) {
      throw StateError('A valid email address is required.');
    }
    if (password.length < 6) {
      throw StateError('Password must be at least 6 characters.');
    }
    if (role == UserRole.schoolAdministrator) {
      final existing = await _firestore
          .collection('users')
          .where('role', isEqualTo: role.key)
          .where('status', isEqualTo: 'active')
          .get();
      if (existing.docs.isNotEmpty) {
        throw StateError('Only one School Administrator account is allowed.');
      }
    }
    if (role == UserRole.staffScanner) {
      final existing = await _firestore
          .collection('users')
          .where('role', isEqualTo: role.key)
          .where('status', isEqualTo: 'active')
          .get();
      if (existing.docs.length >= 5) {
        throw StateError('Maximum of five Staff Scanner accounts reached.');
      }
    }

    final secondaryAppName =
        'user-create-${DateTime.now().microsecondsSinceEpoch}';
    final secondaryApp = await Firebase.initializeApp(
      name: secondaryAppName,
      options: DefaultFirebaseOptions.currentPlatform,
    );
    try {
      final secondaryAuth = FirebaseAuth.instanceFor(app: secondaryApp);
      final credential = await secondaryAuth.createUserWithEmailAndPassword(
        email: normalizedEmail,
        password: password,
      );
      try {
        await _firestore.collection('users').doc(credential.user!.uid).set({
          'email': normalizedEmail,
          'fullName': fullName.trim(),
          'role': role.key,
          'status': status.name,
          'schoolId': actor.schoolId,
          'createdAt': FieldValue.serverTimestamp(),
        });
      } catch (_) {
        await credential.user?.delete();
        rethrow;
      }
      await secondaryAuth.signOut();
    } finally {
      await secondaryApp.delete();
    }
    await _audit.record(
      action: 'user_created',
      actorId: actor.id,
      actorName: actor.fullName,
      target: normalizedEmail,
      metadata: {'role': role.key, 'status': status.name},
    );
  }

  Future<void> setUserStatus({
    required String userId,
    required AccountStatus status,
    required AppUser actor,
  }) async {
    if (userId == actor.id && status == AccountStatus.disabled) {
      throw StateError('You cannot disable your own account.');
    }
    await _firestore.collection('users').doc(userId).update({
      'status': status.name,
      'updatedAt': FieldValue.serverTimestamp(),
    });
    await _audit.record(
      action: 'user_status_updated',
      actorId: actor.id,
      actorName: actor.fullName,
      target: userId,
      metadata: {'status': status.name},
    );
  }

  Future<void> deleteUserProfile({
    required String userId,
    required AppUser actor,
  }) async {
    if (userId == actor.id) {
      throw StateError('You cannot delete your own user profile.');
    }
    await _firestore.collection('users').doc(userId).delete();
    await _audit.record(
      action: 'user_profile_deleted',
      actorId: actor.id,
      actorName: actor.fullName,
      target: userId,
    );
  }

  Future<void> sendPasswordResetForUser({
    required AppUser user,
    required AppUser actor,
  }) async {
    await _auth.sendPasswordResetEmail(email: user.email);
    await _audit.record(
      action: 'password_reset_requested',
      actorId: actor.id,
      actorName: actor.fullName,
      target: user.email,
      metadata: {'userId': user.id, 'role': user.role.key},
    );
  }

  Future<void> archiveRecord(
    String collection,
    String id,
    AppUser actor,
  ) async {
    await _firestore.collection(collection).doc(id).set({
      'archived': true,
      'archivedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    await _audit.record(
      action: '${collection}_archived',
      actorId: actor.id,
      actorName: actor.fullName,
      target: id,
    );
  }

  Future<Uint8List> exportLogsExcel(List<AttendanceLog> logs) async {
    final excel = Excel.createExcel();
    final sheet = excel['Attendance Logs'];
    sheet.appendRow([
      TextCellValue('Log ID'),
      TextCellValue('ID'),
      TextCellValue('Full Name'),
      TextCellValue('Role'),
      TextCellValue('Section'),
      TextCellValue('Date'),
      TextCellValue('Time'),
      TextCellValue('Type'),
      TextCellValue('Status'),
      TextCellValue('Scanned By'),
      TextCellValue('Device ID'),
      TextCellValue('Sync Status'),
      TextCellValue('School Year'),
      TextCellValue('Active Term'),
    ]);
    for (final log in logs) {
      sheet.appendRow([
        TextCellValue(log.id),
        TextCellValue(log.personId),
        TextCellValue(log.fullName),
        TextCellValue(log.personRole.label),
        TextCellValue(log.section),
        TextCellValue(log.dateKey),
        TextCellValue(log.timeText),
        TextCellValue(log.attendanceType.label),
        TextCellValue(log.attendanceStatus.label),
        TextCellValue(log.scannedBy),
        TextCellValue(log.deviceId),
        TextCellValue(log.syncStatus.label),
        TextCellValue(log.schoolYear),
        TextCellValue(log.activeTerm),
      ]);
    }
    return Uint8List.fromList(excel.encode() ?? const []);
  }

  Future<Uint8List> exportLogsPdf(List<AttendanceLog> logs) async {
    final doc = pw.Document();
    doc.addPage(
      pw.MultiPage(
        build: (_) => [
          pw.Text(
            'Attendance Logs',
            style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 12),
          pw.TableHelper.fromTextArray(
            headers: [
              'ID',
              'Name',
              'Role',
              'Date',
              'Time',
              'Type',
              'Status',
              'Scanner',
            ],
            data: logs
                .map(
                  (log) => [
                    log.personId,
                    log.fullName,
                    log.personRole.label,
                    log.dateKey,
                    log.timeText,
                    log.attendanceType.label,
                    log.attendanceStatus.label,
                    log.scannedBy,
                  ],
                )
                .toList(),
          ),
        ],
      ),
    );
    return doc.save();
  }

  Future<Uint8List> exportGatePassLogsExcel(List<GatePassLog> logs) async {
    final excel = Excel.createExcel();
    final sheet = excel['Gate Pass Logs'];
    excel.setDefaultSheet('Gate Pass Logs');
    sheet.appendRow([
      TextCellValue('Log ID'),
      TextCellValue('ID'),
      TextCellValue('Full Name'),
      TextCellValue('Role'),
      TextCellValue('Section'),
      TextCellValue('Date'),
      TextCellValue('Time Out'),
      TextCellValue('Time Back In'),
      TextCellValue('Status'),
      TextCellValue('Reason'),
      TextCellValue('Business Type'),
      TextCellValue('Expected to Return'),
      TextCellValue('Duration Minutes'),
      TextCellValue('Scanned By'),
      TextCellValue('Scanner User ID'),
      TextCellValue('Device ID'),
      TextCellValue('Sync Status'),
      TextCellValue('School Year'),
      TextCellValue('Active Term'),
    ]);
    final sorted = [...logs]..sort((a, b) => a.exitTime.compareTo(b.exitTime));
    for (final log in sorted) {
      sheet.appendRow([
        TextCellValue(log.id),
        TextCellValue(log.personId),
        TextCellValue(log.fullName),
        TextCellValue(log.personRole.label),
        TextCellValue(log.section),
        TextCellValue(log.dateKey),
        TextCellValue(log.exitTimeText),
        TextCellValue(log.returnTimeText.isEmpty ? '-' : log.returnTimeText),
        TextCellValue(log.status.label),
        TextCellValue(log.reason),
        TextCellValue(log.teacherBusinessType?.label ?? '-'),
        TextCellValue(log.expectedToReturn ? 'Yes' : 'No'),
        IntCellValue(log.durationMinutes),
        TextCellValue(log.scannedBy),
        TextCellValue(log.scannerUserId),
        TextCellValue(log.deviceId),
        TextCellValue(log.syncStatus.label),
        TextCellValue(log.schoolYear),
        TextCellValue(log.activeTerm),
      ]);
    }
    if (excel.tables.length > 1 && excel.tables.containsKey('Sheet1')) {
      excel.delete('Sheet1');
    }
    return Uint8List.fromList(excel.encode() ?? const []);
  }

  Future<Uint8List> exportGatePassLogsPdf(List<GatePassLog> logs) async {
    final doc = pw.Document();
    final sorted = [...logs]..sort((a, b) => a.exitTime.compareTo(b.exitTime));
    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        build: (_) => [
          pw.Text(
            'Gate Pass Logs',
            style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 12),
          if (sorted.isEmpty)
            pw.Text('No gate pass records found.')
          else
            pw.TableHelper.fromTextArray(
              headers: const [
                'ID',
                'Name',
                'Role',
                'Section',
                'Date',
                'Out',
                'Back In',
                'Status',
                'Reason',
                'Business',
                'Duration',
                'Scanner',
              ],
              data: sorted
                  .map(
                    (log) => [
                      log.personId,
                      log.fullName,
                      log.personRole.label,
                      log.section,
                      log.dateKey,
                      log.exitTimeText,
                      log.returnTimeText.isEmpty ? '-' : log.returnTimeText,
                      log.status.label,
                      log.reason,
                      log.teacherBusinessType?.label ?? '-',
                      '${log.durationMinutes} min',
                      log.scannedBy,
                    ],
                  )
                  .toList(),
              cellStyle: const pw.TextStyle(fontSize: 6),
              headerStyle: pw.TextStyle(
                fontSize: 6,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
        ],
      ),
    );
    return doc.save();
  }

  Future<Uint8List> exportStudentsExcel(List<Student> students) async {
    final excel = Excel.createExcel();
    final grouped = _studentsBySection(students);
    var sheetIndex = 0;

    for (final entry in grouped.entries) {
      final sheetName = _uniqueSheetName(
        entry.key.isEmpty ? 'Unassigned' : entry.key,
        excel.tables.keys,
      );
      final sheet = excel[sheetName];
      if (sheetIndex == 0) {
        excel.setDefaultSheet(sheetName);
      }
      sheetIndex++;
      sheet.appendRow(_studentHeaders);
      for (final student in entry.value) {
        sheet.appendRow(_studentRow(student));
      }
    }

    if (grouped.isEmpty) {
      final sheet = excel['Students'];
      excel.setDefaultSheet('Students');
      sheet.appendRow(_studentHeaders);
    }
    if (excel.tables.length > 1 && excel.tables.containsKey('Sheet1')) {
      excel.delete('Sheet1');
    }
    return Uint8List.fromList(excel.encode() ?? const []);
  }

  Future<Uint8List> exportStudentsPdf(List<Student> students) async {
    final doc = pw.Document();
    final grouped = _studentsBySection(students);
    doc.addPage(
      pw.MultiPage(
        build: (_) => [
          pw.Text(
            'Students',
            style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 12),
          if (grouped.isEmpty)
            pw.Text('No student records found.')
          else
            for (final entry in grouped.entries) ...[
              pw.Text(
                entry.key.isEmpty ? 'Unassigned Section' : entry.key,
                style: pw.TextStyle(
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 6),
              pw.TableHelper.fromTextArray(
                headers: const [
                  'LRN',
                  'Last Name',
                  'First Name',
                  'Middle Name',
                  'Birthdate',
                  'Address',
                  'Guardian',
                  'Contact',
                ],
                data: entry.value
                    .map(
                      (student) => [
                        student.lrn,
                        student.lastName,
                        student.firstName,
                        student.middleName,
                        _formatDate(student.birthdate),
                        student.address,
                        student.guardianName,
                        student.guardianContact,
                      ],
                    )
                    .toList(),
                cellStyle: const pw.TextStyle(fontSize: 7),
                headerStyle: pw.TextStyle(
                  fontSize: 7,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 16),
            ],
        ],
      ),
    );
    return doc.save();
  }

  Future<Uint8List> exportTeachersExcel(List<Teacher> teachers) async {
    final excel = Excel.createExcel();
    final sheet = excel['Teachers'];
    excel.setDefaultSheet('Teachers');
    sheet.appendRow(_teacherHeaders);
    final sorted = [...teachers]..sort(_compareTeachers);
    for (final teacher in sorted) {
      sheet.appendRow(_teacherRow(teacher));
    }
    if (excel.tables.length > 1 && excel.tables.containsKey('Sheet1')) {
      excel.delete('Sheet1');
    }
    return Uint8List.fromList(excel.encode() ?? const []);
  }

  Future<Uint8List> exportTeachersPdf(List<Teacher> teachers) async {
    final doc = pw.Document();
    final sorted = [...teachers]..sort(_compareTeachers);
    doc.addPage(
      pw.MultiPage(
        build: (_) => [
          pw.Text(
            'Teachers',
            style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 12),
          if (sorted.isEmpty)
            pw.Text('No teacher records found.')
          else
            pw.TableHelper.fromTextArray(
              headers: const [
                'Teacher ID',
                'Last Name',
                'First Name',
                'Middle Name',
                'Birthdate',
                'Address',
                'Contact',
                'Time In',
                'Time Out',
              ],
              data: sorted
                  .map(
                    (teacher) => [
                      teacher.teacherId,
                      teacher.lastName,
                      teacher.firstName,
                      teacher.middleName,
                      _formatDate(teacher.birthdate),
                      teacher.address,
                      teacher.contactNumber,
                      teacher.assignedTimeIn,
                      teacher.assignedTimeOut,
                    ],
                  )
                  .toList(),
              cellStyle: const pw.TextStyle(fontSize: 7),
              headerStyle: pw.TextStyle(
                fontSize: 7,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
        ],
      ),
    );
    return doc.save();
  }

  static final List<CellValue> _studentHeaders = [
    TextCellValue('LRN'),
    TextCellValue('Last Name'),
    TextCellValue('First Name'),
    TextCellValue('Middle Name'),
    TextCellValue('Birthdate'),
    TextCellValue('Address'),
    TextCellValue('Guardian Name'),
    TextCellValue('Guardian Contact'),
  ];

  static final List<CellValue> _teacherHeaders = [
    TextCellValue('Teacher ID'),
    TextCellValue('Last Name'),
    TextCellValue('First Name'),
    TextCellValue('Middle Name'),
    TextCellValue('Birthdate'),
    TextCellValue('Address'),
    TextCellValue('Contact Number'),
    TextCellValue('Time In'),
    TextCellValue('Time Out'),
  ];

  static List<CellValue> _studentRow(Student student) => [
    TextCellValue(student.lrn),
    TextCellValue(student.lastName),
    TextCellValue(student.firstName),
    TextCellValue(student.middleName),
    TextCellValue(_formatDate(student.birthdate)),
    TextCellValue(student.address),
    TextCellValue(student.guardianName),
    TextCellValue(student.guardianContact),
  ];

  static List<CellValue> _teacherRow(Teacher teacher) => [
    TextCellValue(teacher.teacherId),
    TextCellValue(teacher.lastName),
    TextCellValue(teacher.firstName),
    TextCellValue(teacher.middleName),
    TextCellValue(_formatDate(teacher.birthdate)),
    TextCellValue(teacher.address),
    TextCellValue(teacher.contactNumber),
    TextCellValue(teacher.assignedTimeIn),
    TextCellValue(teacher.assignedTimeOut),
  ];

  static Map<String, List<Student>> _studentsBySection(List<Student> students) {
    final grouped = <String, List<Student>>{};
    for (final student in students) {
      final section = student.section.trim();
      grouped.putIfAbsent(section, () => []).add(student);
    }
    for (final students in grouped.values) {
      students.sort(_compareStudents);
    }
    return Map.fromEntries(
      grouped.entries.toList()..sort((a, b) {
        if (a.key.isEmpty) return 1;
        if (b.key.isEmpty) return -1;
        return a.key.toLowerCase().compareTo(b.key.toLowerCase());
      }),
    );
  }

  static int _compareStudents(Student a, Student b) {
    final lastName = a.lastName.toLowerCase().compareTo(
      b.lastName.toLowerCase(),
    );
    if (lastName != 0) return lastName;
    return a.firstName.toLowerCase().compareTo(b.firstName.toLowerCase());
  }

  static int _compareTeachers(Teacher a, Teacher b) {
    final lastName = a.lastName.toLowerCase().compareTo(
      b.lastName.toLowerCase(),
    );
    if (lastName != 0) return lastName;
    return a.firstName.toLowerCase().compareTo(b.firstName.toLowerCase());
  }

  static String _formatDate(DateTime? date) =>
      date == null ? '' : DateFormat('MM/dd/yyyy').format(date);

  static String _uniqueSheetName(String value, Iterable<String> existing) {
    final cleaned = value.replaceAll(RegExp(r'[:\\/?*\[\]]'), '-').trim();
    final base = (cleaned.isEmpty ? 'Section' : cleaned);
    final shortened = base.length > 31 ? base.substring(0, 31) : base;
    var candidate = shortened;
    var suffix = 2;
    while (existing.contains(candidate)) {
      final marker = '-$suffix';
      final limit = 31 - marker.length;
      final end = shortened.length > limit ? limit : shortened.length;
      candidate = '${shortened.substring(0, end)}$marker';
      suffix++;
    }
    return candidate;
  }

  Future<void> backupDatabase(AppUser actor) async {
    final collections = [
      'users',
      'school_years',
      'terms',
      'students',
      'teachers',
      'sections',
      'attendance_logs',
      'archives',
      'audit_logs',
      'scanner_devices',
      'exports',
    ];
    final backupRef = _firestore.collection('backups').doc();
    final counts = <String, int>{};
    for (final collection in collections) {
      final snapshot = await _firestore.collection(collection).count().get();
      counts[collection] = snapshot.count ?? 0;
    }
    await backupRef.set({
      'createdAt': FieldValue.serverTimestamp(),
      'createdBy': actor.id,
      'createdByName': actor.fullName,
      'counts': counts,
      'status': 'catalogued',
    });
    await _audit.record(
      action: 'database_backup_created',
      actorId: actor.id,
      actorName: actor.fullName,
      target: backupRef.id,
    );
  }

  Future<int> storageUsageBytes() async {
    final snapshots = await Future.wait([
      for (final collection in _rootCollectionsForSize)
        _firestore.collection(collection).get(),
      for (final collection in _schoolYearSubcollectionsForSize)
        _firestore.collectionGroup(collection).get(),
    ]);

    var total = 0;
    for (final snapshot in snapshots) {
      for (final doc in snapshot.docs) {
        total += _estimateDocumentBytes(doc);
      }
    }
    return total;
  }

  Future<int> schoolYearStorageUsageBytes(String schoolYearId) async {
    final schoolYearDoc = await _firestore
        .collection('school_years')
        .doc(schoolYearId)
        .get();
    final snapshots = await Future.wait([
      for (final collection in _schoolYearSubcollectionsForSize)
        _firestore
            .collection('school_years')
            .doc(schoolYearId)
            .collection(collection)
            .get(),
    ]);

    var total = schoolYearDoc.exists
        ? _estimateDocumentBytes(schoolYearDoc)
        : 0;
    for (final snapshot in snapshots) {
      for (final doc in snapshot.docs) {
        total += _estimateDocumentBytes(doc);
      }
    }
    return total;
  }

  Reference storageRef(String path) => _storage.ref(path);

  static const _rootCollectionsForSize = [
    'users',
    'school_years',
    'sections',
    'archives',
    'audit_logs',
    'backups',
    'scanner_devices',
    'exports',
  ];

  static const _schoolYearSubcollectionsForSize = [
    'students',
    'teachers',
    'attendance_logs',
    'gate_pass_logs',
    'terms',
    'reports',
  ];

  int _estimateDocumentBytes(DocumentSnapshot<Map<String, dynamic>> doc) {
    final normalized = _normalizeFirestoreValue(doc.data() ?? const {});
    final encodedData = utf8.encode(jsonEncode(normalized)).length;
    final encodedPath = utf8.encode(doc.reference.path).length;
    return encodedPath + encodedData;
  }

  Object? _normalizeFirestoreValue(Object? value) {
    if (value == null || value is String || value is num || value is bool) {
      return value;
    }
    if (value is Timestamp) return value.toDate().toIso8601String();
    if (value is GeoPoint) {
      return {'latitude': value.latitude, 'longitude': value.longitude};
    }
    if (value is DocumentReference) return value.path;
    if (value is Blob) return base64Encode(value.bytes);
    if (value is Iterable) {
      return value.map(_normalizeFirestoreValue).toList();
    }
    if (value is Map) {
      return {
        for (final entry in value.entries)
          entry.key.toString(): _normalizeFirestoreValue(entry.value),
      };
    }
    return value.toString();
  }
}
