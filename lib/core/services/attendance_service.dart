import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../../models/enums.dart';
import '../../models/models.dart';
import 'audit_service.dart';
import 'offline_queue_service.dart';

class AttendanceService {
  AttendanceService(this._firestore, this._queue, this._audit) {
    _queue.syncRequests.listen((_) => syncPendingLogs());
  }

  final FirebaseFirestore _firestore;
  final OfflineQueueService _queue;
  final AuditService _audit;
  final _uuid = const Uuid();
  SchoolYear? _activeSchoolYearCache;

  Stream<QuerySnapshot<Map<String, dynamic>>> logsStream({int limit = 200}) {
    return (() async* {
      final schoolYear = await activeSchoolYear();
      if (schoolYear == null) return;
      yield* _firestore
          .collection('school_years')
          .doc(schoolYear.id)
          .collection('attendance_logs')
          .orderBy('timestamp', descending: true)
          .limit(limit)
          .snapshots();
    })();
  }

  Future<SchoolYear?> activeSchoolYear({bool forceRefresh = false}) async {
    final cached = _activeSchoolYearCache;
    if (!forceRefresh && cached != null && !cached.isFinished(DateTime.now())) {
      return cached;
    }

    final online = await _queue.isOnline;
    if (!online) {
      _activeSchoolYearCache = await _queue.loadCachedActiveSchoolYear();
      return _activeSchoolYearCache;
    }

    final query = await _firestore
        .collection('school_years')
        .where('isActive', isEqualTo: true)
        .where('archived', isEqualTo: false)
        .limit(1)
        .get();
    if (query.docs.isEmpty) {
      _activeSchoolYearCache = null;
      return null;
    }
    final schoolYear = SchoolYear.fromDoc(query.docs.first);
    if (schoolYear.isFinished(DateTime.now())) {
      await archiveSchoolYear(
        schoolYear,
        actorId: 'system',
        actorName: 'System',
        reason: 'final_term_ended',
      );
      _activeSchoolYearCache = null;
      return null;
    }
    _activeSchoolYearCache = schoolYear;
    await _queue.cacheActiveSchoolYear(schoolYear);
    return schoolYear;
  }

  Future<void> archiveSchoolYear(
    SchoolYear schoolYear, {
    required String actorId,
    required String actorName,
    String reason = 'manual_archive',
  }) async {
    await _firestore.collection('school_years').doc(schoolYear.id).set({
      'isActive': false,
      'archived': true,
      'archivedAt': FieldValue.serverTimestamp(),
      'archiveReason': reason,
    }, SetOptions(merge: true));
    await _firestore.collection('archives').add({
      'type': 'school_year',
      'title': schoolYear.name,
      'schoolYear': schoolYear.name,
      'schoolYearId': schoolYear.id,
      'reason': reason,
      'createdAt': FieldValue.serverTimestamp(),
    });
    await _audit.record(
      action: 'school_year_archived',
      actorId: actorId,
      actorName: actorName,
      target: schoolYear.name,
      metadata: {'reason': reason},
    );
    if (_activeSchoolYearCache?.id == schoolYear.id) {
      _activeSchoolYearCache = null;
    }
  }

  void clearActiveSchoolYearCache() {
    _activeSchoolYearCache = null;
  }

  Future<AttendanceLog> scanId({
    required String scannedId,
    required AttendanceType type,
    required AppUser scanner,
    required String deviceId,
  }) async {
    final now = DateTime.now();
    final schoolYear = await activeSchoolYear();
    if (schoolYear == null) {
      throw StateError(
        'Attendance logging is disabled because there is no active school year.',
      );
    }

    final online = await _queue.isOnline;
    final person = await _findPerson(scannedId, schoolYear.id, online: online);
    if (person == null) {
      throw StateError('No active student or teacher found for ID $scannedId.');
    }

    final settings = await loadSettings();
    final status = _attendanceStatus(type, person, now, settings);
    final log = AttendanceLog(
      id: _uuid.v4(),
      personId: scannedId,
      fullName: person.fullName,
      personRole: person.role,
      section: person.section,
      dateKey: DateFormat('yyyy-MM-dd').format(now),
      timeText: DateFormat('hh:mm a').format(now),
      attendanceType: type,
      attendanceStatus: status,
      scannedBy: scanner.fullName,
      scannerUserId: scanner.id,
      deviceId: deviceId,
      offline: !online,
      syncStatus: online ? SyncStatus.synced : SyncStatus.pendingSync,
      timestamp: now,
      schoolYearId: schoolYear.id,
      schoolYear: schoolYear.name,
      activeTerm: schoolYear.activeTermName(now),
    );

    if (!online) {
      await _queue.enqueue(log);
      return log;
    }

    final duplicate = await _isDuplicate(log);
    if (duplicate) {
      return AttendanceLog(
        id: log.id,
        personId: log.personId,
        fullName: log.fullName,
        personRole: log.personRole,
        section: log.section,
        dateKey: log.dateKey,
        timeText: log.timeText,
        attendanceType: log.attendanceType,
        attendanceStatus: AttendanceStatus.duplicate,
        scannedBy: log.scannedBy,
        scannerUserId: log.scannerUserId,
        deviceId: log.deviceId,
        offline: log.offline,
        syncStatus: SyncStatus.synced,
        timestamp: log.timestamp,
        schoolYearId: log.schoolYearId,
        schoolYear: log.schoolYear,
        activeTerm: log.activeTerm,
      );
    }

    await _writeLog(log);
    return log;
  }

  Future<void> syncPendingLogs() async {
    if (!await _queue.isOnline) return;
    final pending = await _queue.loadPendingLogs();
    for (final log in pending) {
      try {
        if (!await _isDuplicate(log)) {
          await _writeLog(log);
        }
        await _queue.remove(log.id);
      } catch (_) {
        await _queue.markFailed(log.id);
      }
    }
  }

  Future<SystemSettings> loadSettings() async {
    final doc = await _firestore
        .collection('system_settings')
        .doc('attendance')
        .get();
    return SystemSettings.fromMap(doc.data());
  }

  Future<void> updateSettings(SystemSettings settings, AppUser actor) async {
    await _firestore
        .collection('system_settings')
        .doc('attendance')
        .set(settings.toMap(), SetOptions(merge: true));
    await _audit.record(
      action: 'settings_updated',
      actorId: actor.id,
      actorName: actor.fullName,
    );
  }

  Future<bool> _isDuplicate(AttendanceLog log) async {
    final query = await _firestore
        .collection('school_years')
        .doc(log.schoolYearId)
        .collection('attendance_logs')
        .where('duplicateKey', isEqualTo: log.duplicateKey)
        .limit(1)
        .get();
    return query.docs.isNotEmpty;
  }

  Future<void> _writeLog(AttendanceLog log) async {
    if (log.schoolYearId.isNotEmpty) {
      await _firestore
          .collection('school_years')
          .doc(log.schoolYearId)
          .collection('attendance_logs')
          .doc(log.id)
          .set({
            ...log.toMap(),
            'syncStatus': SyncStatus.synced.name,
            'offline': log.offline,
          });
    }
    await _audit.record(
      action: 'attendance_logged',
      actorId: log.scannerUserId,
      actorName: log.scannedBy,
      target: log.fullName,
      metadata: {
        'type': log.attendanceType.label,
        'status': log.attendanceStatus.label,
      },
    );
  }

  AttendanceStatus _attendanceStatus(
    AttendanceType type,
    _PersonMatch person,
    DateTime now,
    SystemSettings settings,
  ) {
    final threshold = _thresholdFor(type, person, settings, now);
    if (type.isTimeIn) {
      if (now.isBefore(
        threshold.subtract(Duration(minutes: settings.earlyBeforeMinutes)),
      )) {
        return AttendanceStatus.early;
      }
      if (now.isAfter(threshold)) return AttendanceStatus.late;
    }
    return AttendanceStatus.onTime;
  }

  DateTime _thresholdFor(
    AttendanceType type,
    _PersonMatch person,
    SystemSettings settings,
    DateTime now,
  ) {
    final raw = person.role == PersonRole.teacher
        ? (type.isTimeOut ? person.assignedTimeOut : person.assignedTimeIn)
        : (type.isTimeOut ? settings.studentTimeOut : settings.studentTimeIn);
    final parts = raw.split(':');
    final hour = int.tryParse(parts.first) ?? 7;
    final minute = parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0;
    return DateTime(now.year, now.month, now.day, hour, minute);
  }

  Future<_PersonMatch?> _findPerson(
    String id,
    String schoolYearId, {
    required bool online,
  }) async {
    if (!online) {
      final cached = await _queue.findCachedPerson(
        schoolYearId: schoolYearId,
        personId: id,
      );
      if (cached == null) return null;
      return _PersonMatch(
        fullName: cached['fullName'] as String? ?? '',
        role: (cached['role'] as String? ?? 'student') == 'teacher'
            ? PersonRole.teacher
            : PersonRole.student,
        section: cached['section'] as String? ?? '',
        assignedTimeIn: cached['assignedTimeIn'] as String? ?? '07:00',
        assignedTimeOut: cached['assignedTimeOut'] as String? ?? '17:00',
      );
    }

    final studentQuery = await _firestore
        .collection('school_years')
        .doc(schoolYearId)
        .collection('students')
        .where('lrn', isEqualTo: id)
        .where('archived', isEqualTo: false)
        .limit(1)
        .get();
    if (studentQuery.docs.isNotEmpty) {
      final student = Student.fromDoc(studentQuery.docs.first);
      await _queue.cachePerson(
        schoolYearId: schoolYearId,
        personId: id,
        fullName: student.fullName,
        role: PersonRole.student.name,
        section: student.section,
      );
      return _PersonMatch(
        fullName: student.fullName,
        role: PersonRole.student,
        section: student.section,
      );
    }

    final teacherQuery = await _firestore
        .collection('school_years')
        .doc(schoolYearId)
        .collection('teachers')
        .where('teacherId', isEqualTo: id)
        .where('archived', isEqualTo: false)
        .limit(1)
        .get();
    if (teacherQuery.docs.isNotEmpty) {
      final teacher = Teacher.fromDoc(teacherQuery.docs.first);
      await _queue.cachePerson(
        schoolYearId: schoolYearId,
        personId: id,
        fullName: teacher.fullName,
        role: PersonRole.teacher.name,
        section: '',
        assignedTimeIn: teacher.assignedTimeIn,
        assignedTimeOut: teacher.assignedTimeOut,
      );
      return _PersonMatch(
        fullName: teacher.fullName,
        role: PersonRole.teacher,
        section: '',
        assignedTimeIn: teacher.assignedTimeIn,
        assignedTimeOut: teacher.assignedTimeOut,
      );
    }
    return null;
  }
}

class _PersonMatch {
  const _PersonMatch({
    required this.fullName,
    required this.role,
    required this.section,
    this.assignedTimeIn = '07:00',
    this.assignedTimeOut = '17:00',
  });

  final String fullName;
  final PersonRole role;
  final String section;
  final String assignedTimeIn;
  final String assignedTimeOut;
}
