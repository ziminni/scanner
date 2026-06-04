import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../constants/enums.dart';
import '../../models/models.dart';
import 'audit_service.dart';
import 'offline_queue_service.dart';
import 'sms_notification_service.dart';

class AttendanceService {
  AttendanceService(this._firestore, this._queue, this._audit, this._sms) {
    _queue.syncRequests.listen((_) {
      unawaited(syncPendingLogs());
      unawaited(syncPendingGatePassLogs());
    });
  }

  final FirebaseFirestore _firestore;
  final OfflineQueueService _queue;
  final AuditService _audit;
  final SmsNotificationService _sms;
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

  Stream<QuerySnapshot<Map<String, dynamic>>> gatePassLogsStream({
    int limit = 200,
  }) {
    return (() async* {
      final schoolYear = await activeSchoolYear();
      if (schoolYear == null) return;
      yield* _firestore
          .collection('school_years')
          .doc(schoolYear.id)
          .collection('gate_pass_logs')
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
    final personId = _normalizeScannedId(scannedId);
    final now = DateTime.now();
    final schoolYear = await activeSchoolYear();
    if (schoolYear == null) {
      throw StateError(
        'Attendance logging is disabled because there is no active school year.',
      );
    }

    final online = await _queue.isOnline;
    final person = await _findPerson(personId, schoolYear.id, online: online);
    if (person == null) {
      throw StateError('No active student or teacher found for ID $personId.');
    }

    final settings = await loadSettings();
    final status = _attendanceStatus(type, person, now, settings);
    final log = AttendanceLog(
      id: _uuid.v4(),
      personId: person.id,
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
      if (await _queue.hasPendingDuplicate(
        log,
        duplicateWindowMinutes: settings.duplicateWindowMinutes,
      )) {
        return _duplicateLog(log, syncStatus: SyncStatus.pendingSync);
      }
      await _queue.enqueue(
        log,
        duplicateWindowMinutes: settings.duplicateWindowMinutes,
      );
      unawaited(
        _sms.notifyAttendance(log: log, recipient: person.contactNumber),
      );
      return log;
    }

    final duplicate = await _isDuplicate(
      log,
      duplicateWindowMinutes: settings.duplicateWindowMinutes,
    );
    if (duplicate) {
      return _duplicateLog(log, syncStatus: SyncStatus.synced);
    }

    await _writeLog(log);
    unawaited(_sms.notifyAttendance(log: log, recipient: person.contactNumber));
    return log;
  }

  Future<GatePassLog> logGatePassExit({
    required String scannedId,
    required String reason,
    required TeacherBusinessType teacherBusinessType,
    required bool expectedToReturn,
    required AppUser scanner,
    required String deviceId,
  }) async {
    final personId = _normalizeScannedId(scannedId);
    final trimmedReason = reason.trim();
    if (trimmedReason.isEmpty) {
      throw StateError('Please enter the reason for going outside.');
    }
    final settings = await loadSettings();
    if (_wordCount(trimmedReason) > settings.gatePassReasonWordLimit) {
      throw StateError(
        'Reason is too long. Please keep it within ${settings.gatePassReasonWordLimit} words.',
      );
    }

    await validateGatePassExitAllowed(personId);

    final now = DateTime.now();
    final schoolYear = await activeSchoolYear();
    if (schoolYear == null) {
      throw StateError(
        'Gate pass logging is disabled because there is no active school year.',
      );
    }

    final online = await _queue.isOnline;
    final person = await _findPerson(personId, schoolYear.id, online: online);
    if (person == null) {
      throw StateError('No active student or teacher found for ID $personId.');
    }
    final log = GatePassLog(
      id: _uuid.v4(),
      personId: person.id,
      fullName: person.fullName,
      personRole: person.role,
      section: person.section,
      dateKey: DateFormat('yyyy-MM-dd').format(now),
      exitTime: now,
      exitTimeText: DateFormat('hh:mm a').format(now),
      returnTime: null,
      returnTimeText: '',
      reason: trimmedReason,
      teacherBusinessType: person.role == PersonRole.teacher
          ? teacherBusinessType
          : null,
      expectedToReturn: expectedToReturn,
      status: expectedToReturn
          ? GatePassStatus.outside
          : GatePassStatus.noReturn,
      durationMinutes: 0,
      scannedBy: scanner.fullName,
      scannerUserId: scanner.id,
      deviceId: deviceId,
      offline: !online,
      syncStatus: online ? SyncStatus.synced : SyncStatus.pendingSync,
      timestamp: now,
      updatedAt: now,
      schoolYearId: schoolYear.id,
      schoolYear: schoolYear.name,
      activeTerm: schoolYear.activeTermName(now),
    );

    if (!online) {
      await _queue.enqueueGatePass(log);
      unawaited(
        _sms.notifyGatePassExit(log: log, recipient: person.contactNumber),
      );
      return log;
    }

    await _writeGatePassLog(log);
    unawaited(
      _sms.notifyGatePassExit(log: log, recipient: person.contactNumber),
    );
    return log;
  }

  Future<void> validateGatePassExitAllowed(String scannedId) async {
    final personId = _normalizeScannedId(scannedId);
    final schoolYear = await activeSchoolYear();
    if (schoolYear == null) {
      throw StateError(
        'Gate pass logging is disabled because there is no active school year.',
      );
    }

    final online = await _queue.isOnline;
    final person = await _findPerson(personId, schoolYear.id, online: online);
    if (person == null) {
      throw StateError('No active student or teacher found for ID $personId.');
    }
    final existingGatePass = await _findUnclosedGatePass(
      schoolYearId: schoolYear.id,
      personId: person.id,
      online: online,
    );
    if (existingGatePass != null) {
      throw StateError(
        '${person.fullName} already has an active gate pass log out. Log back in first before creating another gate pass log out.',
      );
    }
  }

  Future<GatePassLog> logGatePassReturn({
    required String scannedId,
    required AppUser scanner,
    required String deviceId,
  }) async {
    final personId = _normalizeScannedId(scannedId);
    final now = DateTime.now();
    final schoolYear = await activeSchoolYear();
    if (schoolYear == null) {
      throw StateError(
        'Gate pass logging is disabled because there is no active school year.',
      );
    }

    final online = await _queue.isOnline;
    final person = await _findPerson(personId, schoolYear.id, online: online);
    if (person == null) {
      throw StateError('No active student or teacher found for ID $personId.');
    }

    if (!online) {
      final pending = await _queue.findPendingOpenGatePass(
        schoolYearId: schoolYear.id,
        personId: person.id,
      );
      if (pending == null) {
        throw StateError(
          'No pending gate pass exit was found on this device. Reconnect to log a return from an online record.',
        );
      }
      final updated = _returnedGatePassLog(pending, now, offline: true);
      await _queue.updatePendingGatePass(updated);
      unawaited(
        _sms.notifyGatePassReturn(
          log: updated,
          recipient: person.contactNumber,
        ),
      );
      return updated;
    }

    final openQuery = await _firestore
        .collection('school_years')
        .doc(schoolYear.id)
        .collection('gate_pass_logs')
        .where('personId', isEqualTo: person.id)
        .where('status', isEqualTo: GatePassStatus.outside.name)
        .get();

    if (openQuery.docs.isEmpty) {
      throw StateError('No open gate pass exit found for ${person.fullName}.');
    }

    final openLogs = openQuery.docs.map(GatePassLog.fromDoc).toList()
      ..sort((a, b) => b.exitTime.compareTo(a.exitTime));
    final log = openLogs.first;
    final updated = _returnedGatePassLog(log, now, offline: false);
    await _firestore
        .collection('school_years')
        .doc(schoolYear.id)
        .collection('gate_pass_logs')
        .doc(log.id)
        .set(updated.toMap(), SetOptions(merge: true));
    unawaited(
      _sms.notifyGatePassReturn(log: updated, recipient: person.contactNumber),
    );
    await _audit.record(
      action: 'gate_pass_return_logged',
      actorId: scanner.id,
      actorName: scanner.fullName,
      target: updated.fullName,
      metadata: {'durationMinutes': updated.durationMinutes},
    );
    return updated;
  }

  Future<void> syncPendingLogs() async {
    if (!await _queue.isOnline) return;
    final settings = await loadSettings();
    final pending = await _queue.loadPendingLogs();
    for (final log in pending) {
      try {
        if (!await _isDuplicate(
          log,
          duplicateWindowMinutes: settings.duplicateWindowMinutes,
        )) {
          await _writeLog(log);
        }
        await _queue.remove(log.id);
      } catch (_) {
        await _queue.markFailed(log.id);
      }
    }
  }

  Future<void> syncPendingGatePassLogs() async {
    if (!await _queue.isOnline) return;
    final pending = await _queue.loadPendingGatePassLogs();
    for (final log in pending) {
      try {
        await _writeGatePassLog(log);
        await _queue.removeGatePass(log.id);
      } catch (_) {
        // Keep the pending gate pass for the next reconnect attempt.
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

  Future<bool> _isDuplicate(
    AttendanceLog log, {
    required int duplicateWindowMinutes,
  }) async {
    final query = await _firestore
        .collection('school_years')
        .doc(log.schoolYearId)
        .collection('attendance_logs')
        .where('duplicateKey', isEqualTo: log.duplicateKey)
        .get();
    final window = Duration(minutes: duplicateWindowMinutes);
    return query.docs.map(AttendanceLog.fromDoc).any((existing) {
      final difference = existing.timestamp.difference(log.timestamp).abs();
      return difference <= window;
    });
  }

  AttendanceLog _duplicateLog(
    AttendanceLog log, {
    required SyncStatus syncStatus,
  }) {
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
      syncStatus: syncStatus,
      timestamp: log.timestamp,
      schoolYearId: log.schoolYearId,
      schoolYear: log.schoolYear,
      activeTerm: log.activeTerm,
    );
  }

  Future<GatePassLog?> _findUnclosedGatePass({
    required String schoolYearId,
    required String personId,
    required bool online,
  }) async {
    if (!online) {
      return _queue.findPendingUnclosedGatePass(
        schoolYearId: schoolYearId,
        personId: personId,
      );
    }

    final query = await _firestore
        .collection('school_years')
        .doc(schoolYearId)
        .collection('gate_pass_logs')
        .where('personId', isEqualTo: personId)
        .get();
    final unclosedLogs =
        query.docs
            .map(GatePassLog.fromDoc)
            .where((log) => log.status != GatePassStatus.returned)
            .toList()
          ..sort((a, b) => b.exitTime.compareTo(a.exitTime));
    return unclosedLogs.firstOrNull;
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

  Future<void> _writeGatePassLog(GatePassLog log) async {
    await _firestore
        .collection('school_years')
        .doc(log.schoolYearId)
        .collection('gate_pass_logs')
        .doc(log.id)
        .set({
          ...log.toMap(),
          'syncStatus': SyncStatus.synced.name,
          'offline': log.offline,
        });
    await _audit.record(
      action: 'gate_pass_exit_logged',
      actorId: log.scannerUserId,
      actorName: log.scannedBy,
      target: log.fullName,
      metadata: {
        'reason': log.reason,
        'status': log.status.label,
        'teacherBusinessType': log.teacherBusinessType?.label ?? '',
      },
    );
  }

  GatePassLog _returnedGatePassLog(
    GatePassLog log,
    DateTime now, {
    required bool offline,
  }) {
    return log.copyWith(
      returnTime: now,
      returnTimeText: DateFormat('hh:mm a').format(now),
      status: GatePassStatus.returned,
      durationMinutes: now.difference(log.exitTime).inMinutes.clamp(0, 1000000),
      offline: log.offline || offline,
      syncStatus: offline ? SyncStatus.pendingSync : SyncStatus.synced,
      updatedAt: now,
    );
  }

  int _wordCount(String value) {
    return value.split(RegExp(r'\s+')).where((word) => word.isNotEmpty).length;
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
    final candidates = _idCandidates(id);
    if (!online) {
      Map<String, dynamic>? cached;
      String matchedId = id;
      for (final candidate in candidates) {
        cached = await _queue.findCachedPerson(
          schoolYearId: schoolYearId,
          personId: candidate,
        );
        if (cached != null) {
          matchedId = candidate;
          break;
        }
      }
      if (cached == null) return null;
      return _PersonMatch(
        id: cached['personId'] as String? ?? matchedId,
        fullName: cached['fullName'] as String? ?? '',
        role: (cached['role'] as String? ?? 'student') == 'teacher'
            ? PersonRole.teacher
            : PersonRole.student,
        section: cached['section'] as String? ?? '',
        assignedTimeIn: cached['assignedTimeIn'] as String? ?? '07:00',
        assignedTimeOut: cached['assignedTimeOut'] as String? ?? '17:00',
        contactNumber: cached['contactNumber'] as String? ?? '',
      );
    }

    for (final candidate in candidates) {
      final studentQuery = await _firestore
          .collection('school_years')
          .doc(schoolYearId)
          .collection('students')
          .where('lrn', isEqualTo: candidate)
          .limit(1)
          .get();
      final studentDoc = studentQuery.docs
          .where((doc) => doc.data()['archived'] != true)
          .firstOrNull;
      if (studentDoc != null) {
        final student = Student.fromDoc(studentDoc);
        await _queue.cachePerson(
          schoolYearId: schoolYearId,
          personId: student.lrn,
          fullName: student.fullName,
          role: PersonRole.student.name,
          section: student.section,
          contactNumber: student.guardianContact,
        );
        return _PersonMatch(
          id: student.lrn,
          fullName: student.fullName,
          role: PersonRole.student,
          section: student.section,
          contactNumber: student.guardianContact,
        );
      }
    }

    for (final candidate in candidates) {
      final teacherQuery = await _firestore
          .collection('school_years')
          .doc(schoolYearId)
          .collection('teachers')
          .where('teacherId', isEqualTo: candidate)
          .limit(1)
          .get();
      final teacherDoc = teacherQuery.docs
          .where((doc) => doc.data()['archived'] != true)
          .firstOrNull;
      if (teacherDoc != null) {
        final teacher = Teacher.fromDoc(teacherDoc);
        await _queue.cachePerson(
          schoolYearId: schoolYearId,
          personId: teacher.teacherId,
          fullName: teacher.fullName,
          role: PersonRole.teacher.name,
          section: '',
          assignedTimeIn: teacher.assignedTimeIn,
          assignedTimeOut: teacher.assignedTimeOut,
          contactNumber: teacher.contactNumber,
        );
        return _PersonMatch(
          id: teacher.teacherId,
          fullName: teacher.fullName,
          role: PersonRole.teacher,
          section: '',
          assignedTimeIn: teacher.assignedTimeIn,
          assignedTimeOut: teacher.assignedTimeOut,
          contactNumber: teacher.contactNumber,
        );
      }
    }
    return null;
  }

  String _normalizeScannedId(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return '';
    final labeledMatch = RegExp(
      r'(?:LRN|Teacher\s*ID|ID)\s*[:#-]?\s*([A-Za-z0-9._-]+)',
      caseSensitive: false,
    ).firstMatch(trimmed);
    if (labeledMatch != null) return labeledMatch.group(1)!.trim();
    if (!trimmed.contains(RegExp(r'\s'))) return trimmed;
    final compactMatch = RegExp(r'[A-Za-z0-9._-]{4,}').firstMatch(trimmed);
    return compactMatch?.group(0)?.trim() ?? trimmed;
  }

  List<String> _idCandidates(String id) {
    final trimmed = id.trim();
    final candidates = <String>{};
    if (trimmed.isNotEmpty) candidates.add(trimmed);
    final withoutTrailingDecimal = trimmed.replaceFirst(RegExp(r'\.0$'), '');
    if (withoutTrailingDecimal.isNotEmpty) {
      candidates.add(withoutTrailingDecimal);
    }
    if (RegExp(r'^\d+$').hasMatch(withoutTrailingDecimal)) {
      candidates.add('$withoutTrailingDecimal.0');
    }
    return candidates.toList();
  }
}

class _PersonMatch {
  const _PersonMatch({
    required this.id,
    required this.fullName,
    required this.role,
    required this.section,
    this.assignedTimeIn = '07:00',
    this.assignedTimeOut = '17:00',
    this.contactNumber = '',
  });

  final String id;
  final String fullName;
  final PersonRole role;
  final String section;
  final String assignedTimeIn;
  final String assignedTimeOut;
  final String contactNumber;
}
