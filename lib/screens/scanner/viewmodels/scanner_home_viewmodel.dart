import 'dart:async';

import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/constants/enums.dart';
import '../../../core/services/app_controller.dart';
import '../../../models/models.dart';
import 'base_viewmodel.dart';

class ScannerHomeLeaderboardEntry {
  const ScannerHomeLeaderboardEntry({
    required this.rank,
    required this.name,
    required this.timeIn,
    required this.points,
  });

  final int rank;
  final String name;
  final String timeIn;
  final int points;
}

class ScannerHomeViewModel extends BaseViewModel {
  ScannerHomeViewModel(this._app) {
    _syncSubscription = _app.offlineQueue.syncRequests.listen((_) {
      Future<void>.delayed(const Duration(seconds: 2), () {
        if (_disposed) return;
        unawaited(_refreshLoggedPeopleSyncStatus());
      });
    });
  }

  static const _studentLastSyncPrefix = 'scanner_students_last_sync_';
  static const _teacherLastSyncPrefix = 'scanner_teachers_last_sync_';
  static _ScannerHomeCacheSnapshot? _cache;

  final AppController _app;
  late final StreamSubscription<void> _syncSubscription;
  bool _disposed = false;

  List<ScannerHomeLeaderboardEntry> students = [];
  List<ScannerHomeLeaderboardEntry> teachers = [];
  PeopleSyncStatus studentSync = PeopleSyncStatus.empty(roleLabel: 'Students');
  PeopleSyncStatus teacherSync = PeopleSyncStatus.empty(roleLabel: 'Teachers');
  PeopleSyncStatus loggedScanSync = PeopleSyncStatus.empty(
    roleLabel: 'Logged Scans',
  );
  String? _schoolYearId;

  @override
  void dispose() {
    _disposed = true;
    _syncSubscription.cancel();
    super.dispose();
  }

  Future<void> load() async {
    setError(null);
    final todayKey = DateFormat('yyyy-MM-dd').format(DateTime.now());
    var showingCache = _restoreCache(todayKey: todayKey);
    if (!showingCache) setBusy(true);

    try {
      final schoolYear = await _app.attendance.activeSchoolYear();
      if (schoolYear == null) {
        students = [];
        teachers = [];
        studentSync = PeopleSyncStatus.empty(roleLabel: 'Students');
        teacherSync = PeopleSyncStatus.empty(roleLabel: 'Teachers');
        loggedScanSync = PeopleSyncStatus.empty(roleLabel: 'Logged Scans');
        _schoolYearId = null;
        setError('Create an active school year first.');
        return;
      }
      _schoolYearId = schoolYear.id;
      await _loadPeopleSyncStatus(schoolYear.id);
      await _loadLoggedPeopleSyncStatus(schoolYear.id);

      final schoolYearCache = _cache;
      if (!showingCache &&
          schoolYearCache != null &&
          schoolYearCache.schoolYearId == schoolYear.id &&
          schoolYearCache.dateKey == todayKey) {
        _applyCache(schoolYearCache);
        showingCache = true;
        setBusy(false);
      }

      final snapshot = await _app.repository.attendanceLogsForDate(
        schoolYearId: schoolYear.id,
        dateKey: todayKey,
      );
      final logs = snapshot.docs.map(AttendanceLog.fromDoc).toList();
      students = _buildEntries(logs, PersonRole.student);
      teachers = _buildEntries(logs, PersonRole.teacher);
      _saveCache(schoolYearId: schoolYear.id, dateKey: todayKey);
      notifyListeners();
    } catch (error) {
      if (!showingCache) {
        setError(error.toString());
      }
    } finally {
      setBusy(false);
    }
  }

  Future<void> syncStudents() async {
    final schoolYearId = await _requireSchoolYearId();
    if (schoolYearId == null) return;
    studentSync = studentSync.copyWith(syncing: true, error: null);
    notifyListeners();
    try {
      final snapshot = await _app.repository.activeStudents(schoolYearId);
      final students = snapshot.docs.map(Student.fromDoc).toList();
      await _app.offlineQueue.clearCachedPeople(
        schoolYearId: schoolYearId,
        role: PersonRole.student.name,
      );
      for (final student in students) {
        await _app.offlineQueue.cachePerson(
          schoolYearId: schoolYearId,
          personId: student.lrn,
          fullName: student.fullName,
          role: PersonRole.student.name,
          section: student.section,
          contactNumber: student.guardianContact,
        );
      }
      final syncedAt = DateTime.now();
      await _saveLastSync(_studentLastSyncPrefix, schoolYearId, syncedAt);
      studentSync = PeopleSyncStatus(
        roleLabel: 'Students',
        count: students.length,
        lastSyncedAt: syncedAt,
      );
      _saveCurrentCache();
    } catch (error) {
      studentSync = studentSync.copyWith(
        syncing: false,
        error: error.toString(),
      );
    }
    notifyListeners();
  }

  Future<void> syncTeachers() async {
    final schoolYearId = await _requireSchoolYearId();
    if (schoolYearId == null) return;
    teacherSync = teacherSync.copyWith(syncing: true, error: null);
    notifyListeners();
    try {
      final snapshot = await _app.repository.activeTeachers(schoolYearId);
      final teachers = snapshot.docs.map(Teacher.fromDoc).toList();
      await _app.offlineQueue.clearCachedPeople(
        schoolYearId: schoolYearId,
        role: PersonRole.teacher.name,
      );
      for (final teacher in teachers) {
        await _app.offlineQueue.cachePerson(
          schoolYearId: schoolYearId,
          personId: teacher.teacherId,
          fullName: teacher.fullName,
          role: PersonRole.teacher.name,
          section: '',
          assignedTimeIn: teacher.assignedTimeIn,
          assignedTimeOut: teacher.assignedTimeOut,
          contactNumber: teacher.contactNumber,
        );
      }
      final syncedAt = DateTime.now();
      await _saveLastSync(_teacherLastSyncPrefix, schoolYearId, syncedAt);
      teacherSync = PeopleSyncStatus(
        roleLabel: 'Teachers',
        count: teachers.length,
        lastSyncedAt: syncedAt,
      );
      _saveCurrentCache();
    } catch (error) {
      teacherSync = teacherSync.copyWith(
        syncing: false,
        error: error.toString(),
      );
    }
    notifyListeners();
  }

  Future<void> syncLoggedPeople() async {
    final schoolYearId = await _requireSchoolYearId();
    if (schoolYearId == null) return;
    loggedScanSync = loggedScanSync.copyWith(syncing: true, error: null);
    notifyListeners();
    try {
      await _app.attendance.syncPendingLogs();
      await _app.attendance.syncPendingGatePassLogs();
      await _loadLoggedPeopleSyncStatus(schoolYearId);
    } catch (error) {
      loggedScanSync = loggedScanSync.copyWith(
        syncing: false,
        error: error.toString(),
      );
    }
    _saveCurrentCache();
    notifyListeners();
  }

  Future<void> _refreshLoggedPeopleSyncStatus() async {
    final schoolYearId = _schoolYearId;
    if (schoolYearId == null) return;
    await _loadLoggedPeopleSyncStatus(schoolYearId);
    _saveCurrentCache();
    notifyListeners();
  }

  Future<String?> _requireSchoolYearId() async {
    if (_schoolYearId != null) return _schoolYearId;
    final schoolYear = await _app.attendance.activeSchoolYear();
    _schoolYearId = schoolYear?.id;
    return _schoolYearId;
  }

  Future<void> _loadPeopleSyncStatus(String schoolYearId) async {
    final prefs = await SharedPreferences.getInstance();
    final studentCount = await _app.offlineQueue.cachedPeopleCount(
      schoolYearId: schoolYearId,
      role: PersonRole.student.name,
    );
    final teacherCount = await _app.offlineQueue.cachedPeopleCount(
      schoolYearId: schoolYearId,
      role: PersonRole.teacher.name,
    );
    studentSync = PeopleSyncStatus(
      roleLabel: 'Students',
      count: studentCount,
      lastSyncedAt: _readLastSync(prefs, _studentLastSyncPrefix, schoolYearId),
    );
    teacherSync = PeopleSyncStatus(
      roleLabel: 'Teachers',
      count: teacherCount,
      lastSyncedAt: _readLastSync(prefs, _teacherLastSyncPrefix, schoolYearId),
    );
    _saveCurrentCache();
  }

  Future<void> _loadLoggedPeopleSyncStatus(String schoolYearId) async {
    final studentPending = await _app.offlineQueue.pendingLoggedPeopleCount(
      schoolYearId: schoolYearId,
      role: PersonRole.student,
    );
    final teacherPending = await _app.offlineQueue.pendingLoggedPeopleCount(
      schoolYearId: schoolYearId,
      role: PersonRole.teacher,
    );
    final studentLastSync = await _app.offlineQueue.loadLoggedPeopleLastSync(
      schoolYearId: schoolYearId,
      role: PersonRole.student,
    );
    final teacherLastSync = await _app.offlineQueue.loadLoggedPeopleLastSync(
      schoolYearId: schoolYearId,
      role: PersonRole.teacher,
    );
    loggedScanSync = PeopleSyncStatus(
      roleLabel: 'Logged Scans',
      count: studentPending + teacherPending,
      lastSyncedAt: _latestDate(studentLastSync, teacherLastSync),
      countSuffix: 'pending',
      syncedStatusLabel: 'All synced',
      emptyStatusLabel: 'No synced logs yet',
      showPendingInStatus: true,
    );
    _saveCurrentCache();
  }

  DateTime? _readLastSync(
    SharedPreferences prefs,
    String prefix,
    String schoolYearId,
  ) {
    final raw = prefs.getString('$prefix$schoolYearId');
    if (raw == null) return null;
    return DateTime.tryParse(raw);
  }

  Future<void> _saveLastSync(
    String prefix,
    String schoolYearId,
    DateTime syncedAt,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('$prefix$schoolYearId', syncedAt.toIso8601String());
  }

  bool _restoreCache({required String todayKey}) {
    final snapshot = _cache;
    if (snapshot == null || snapshot.dateKey != todayKey) return false;
    _schoolYearId = snapshot.schoolYearId;
    _applyCache(snapshot);
    notifyListeners();
    return true;
  }

  void _applyCache(_ScannerHomeCacheSnapshot snapshot) {
    students = [...snapshot.students];
    teachers = [...snapshot.teachers];
    studentSync = snapshot.studentSync;
    teacherSync = snapshot.teacherSync;
    loggedScanSync = snapshot.loggedScanSync;
  }

  void _saveCache({required String schoolYearId, required String dateKey}) {
    _cache = _ScannerHomeCacheSnapshot(
      schoolYearId: schoolYearId,
      dateKey: dateKey,
      students: [...students],
      teachers: [...teachers],
      studentSync: studentSync,
      teacherSync: teacherSync,
      loggedScanSync: loggedScanSync,
    );
  }

  DateTime? _latestDate(DateTime? first, DateTime? second) {
    if (first == null) return second;
    if (second == null) return first;
    return first.isAfter(second) ? first : second;
  }

  void _saveCurrentCache() {
    final schoolYearId = _schoolYearId;
    if (schoolYearId == null) return;
    _saveCache(
      schoolYearId: schoolYearId,
      dateKey: DateFormat('yyyy-MM-dd').format(DateTime.now()),
    );
  }

  List<ScannerHomeLeaderboardEntry> _buildEntries(
    List<AttendanceLog> logs,
    PersonRole role,
  ) {
    final earliestByPerson = <String, AttendanceLog>{};

    for (final log in logs) {
      if (log.personRole != role) continue;
      if (!log.attendanceType.isTimeIn) continue;
      if (log.attendanceStatus == AttendanceStatus.duplicate) continue;

      final existing = earliestByPerson[log.personId];
      if (existing == null || log.timestamp.isBefore(existing.timestamp)) {
        earliestByPerson[log.personId] = log;
      }
    }

    final ranked = earliestByPerson.values.toList()
      ..sort((a, b) {
        final timeCompare = a.timestamp.compareTo(b.timestamp);
        if (timeCompare != 0) return timeCompare;
        return a.fullName.compareTo(b.fullName);
      });

    return [
      for (var index = 0; index < ranked.length && index < 10; index++)
        ScannerHomeLeaderboardEntry(
          rank: index + 1,
          name: ranked[index].fullName,
          timeIn: DateFormat('hh:mm a').format(ranked[index].timestamp),
          points: _pointsForRank(index + 1),
        ),
    ];
  }

  int _pointsForRank(int rank) {
    if (rank <= 5) return 11 - rank;
    if (rank <= 10) return 5;
    return 0;
  }
}

class _ScannerHomeCacheSnapshot {
  const _ScannerHomeCacheSnapshot({
    required this.schoolYearId,
    required this.dateKey,
    required this.students,
    required this.teachers,
    required this.studentSync,
    required this.teacherSync,
    required this.loggedScanSync,
  });

  final String schoolYearId;
  final String dateKey;
  final List<ScannerHomeLeaderboardEntry> students;
  final List<ScannerHomeLeaderboardEntry> teachers;
  final PeopleSyncStatus studentSync;
  final PeopleSyncStatus teacherSync;
  final PeopleSyncStatus loggedScanSync;
}

class PeopleSyncStatus {
  const PeopleSyncStatus({
    required this.roleLabel,
    required this.count,
    required this.lastSyncedAt,
    this.countSuffix = 'cached',
    this.syncedStatusLabel = 'Ready offline',
    this.emptyStatusLabel = 'Not synced yet',
    this.showPendingInStatus = false,
    this.syncing = false,
    this.error,
  });

  factory PeopleSyncStatus.empty({required String roleLabel}) {
    return PeopleSyncStatus(roleLabel: roleLabel, count: 0, lastSyncedAt: null);
  }

  final String roleLabel;
  final int count;
  final DateTime? lastSyncedAt;
  final String countSuffix;
  final String syncedStatusLabel;
  final String emptyStatusLabel;
  final bool showPendingInStatus;
  final bool syncing;
  final String? error;

  bool get hasSynced => lastSyncedAt != null;

  String get statusLabel {
    if (syncing) return 'Syncing...';
    if (error != null) return 'Sync failed';
    if (!hasSynced) return emptyStatusLabel;
    return showPendingInStatus && count > 0
        ? '$count pending'
        : syncedStatusLabel;
  }

  String get countLabel => '$count $countSuffix';

  String get lastSyncLabel {
    final syncedAt = lastSyncedAt;
    if (syncedAt == null) return 'Last sync: Never';
    return 'Last sync: ${DateFormat('MMM d, yyyy h:mm a').format(syncedAt)}';
  }

  PeopleSyncStatus copyWith({
    int? count,
    DateTime? lastSyncedAt,
    bool? syncing,
    String? error,
  }) {
    return PeopleSyncStatus(
      roleLabel: roleLabel,
      count: count ?? this.count,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
      countSuffix: countSuffix,
      syncedStatusLabel: syncedStatusLabel,
      emptyStatusLabel: emptyStatusLabel,
      showPendingInStatus: showPendingInStatus,
      syncing: syncing ?? this.syncing,
      error: error,
    );
  }
}
