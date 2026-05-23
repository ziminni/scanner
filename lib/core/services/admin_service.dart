import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:excel/excel.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../models/enums.dart';
import '../../models/models.dart';
import 'audit_service.dart';
import 'firebase_options.dart';

class AdminService {
  AdminService(this._firestore, FirebaseAuth _, this._storage, this._audit);

  final FirebaseFirestore _firestore;
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
      await secondaryAuth.signOut();
      await _firestore.collection('users').doc(credential.user!.uid).set({
        'email': normalizedEmail,
        'fullName': fullName.trim(),
        'role': role.key,
        'status': status.name,
        'schoolId': actor.schoolId,
        'createdAt': FieldValue.serverTimestamp(),
      });
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
    final backups = await _firestore.collection('backups').get();
    return backups.docs.fold<int>(
      0,
      (total, doc) => total + ((doc.data()['sizeBytes'] as int?) ?? 0),
    );
  }

  Reference storageRef(String path) => _storage.ref(path);
}
