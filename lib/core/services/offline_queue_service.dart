import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:hive/hive.dart';

import '../constants/enums.dart';
import '../../models/models.dart';

class OfflineQueueService {
  static const _attendanceBoxName = 'offline_pending_attendance_logs';
  static const _gatePassBoxName = 'offline_pending_gate_pass_logs';
  static const _schoolCacheBoxName = 'offline_school_cache';
  static const _peopleBoxName = 'offline_people_cache';
  static const _activeSchoolYearKey = 'active_school_year';

  OfflineQueueService(this._connectivity);

  final Connectivity _connectivity;
  final _syncRequests = StreamController<void>.broadcast();
  Box<Map>? _attendanceBox;
  Box<Map>? _gatePassBox;
  Box<Map>? _schoolCacheBox;
  Box<Map>? _peopleBox;

  Stream<void> get syncRequests => _syncRequests.stream;

  Future<void> initialize() async {
    _attendanceBox ??= await Hive.openBox<Map>(_attendanceBoxName);
    _gatePassBox ??= await Hive.openBox<Map>(_gatePassBoxName);
    _schoolCacheBox ??= await Hive.openBox<Map>(_schoolCacheBoxName);
    _peopleBox ??= await Hive.openBox<Map>(_peopleBoxName);
  }

  Future<void> startNetworkWatcher() async {
    _connectivity.onConnectivityChanged.listen((result) {
      if (result.any((status) => status != ConnectivityResult.none)) {
        _syncRequests.add(null);
      }
    });
  }

  Future<bool> get isOnline async {
    final result = await _connectivity.checkConnectivity();
    return result.any((status) => status != ConnectivityResult.none);
  }

  Future<List<AttendanceLog>> loadPendingLogs() async {
    final box = await _pendingAttendanceBox();
    return box.values.map((item) {
      final data = Map<String, dynamic>.from(item['data'] as Map);
      return AttendanceLog.fromMap(item['id'] as String, data);
    }).toList()..sort((a, b) => a.timestamp.compareTo(b.timestamp));
  }

  Future<void> enqueue(
    AttendanceLog log, {
    required int duplicateWindowMinutes,
  }) async {
    final pending = await loadPendingLogs();
    if (_hasDuplicateWithinWindow(
      pending,
      log,
      duplicateWindowMinutes: duplicateWindowMinutes,
    )) {
      return;
    }
    await (await _pendingAttendanceBox()).put(log.id, {
      'id': log.id,
      'data': _offlineMap(log),
    });
  }

  Future<bool> hasPendingDuplicate(
    AttendanceLog log, {
    required int duplicateWindowMinutes,
  }) async {
    return _hasDuplicateWithinWindow(
      await loadPendingLogs(),
      log,
      duplicateWindowMinutes: duplicateWindowMinutes,
    );
  }

  Future<List<GatePassLog>> loadPendingGatePassLogs() async {
    final box = await _pendingGatePassBox();
    return box.values.map((item) {
      final data = Map<String, dynamic>.from(item['data'] as Map);
      return GatePassLog.fromMap(item['id'] as String, data);
    }).toList()..sort((a, b) => a.timestamp.compareTo(b.timestamp));
  }

  Future<void> enqueueGatePass(GatePassLog log) async {
    final box = await _pendingGatePassBox();
    if (box.containsKey(log.id)) return;
    await box.put(log.id, {'id': log.id, 'data': _offlineGatePassMap(log)});
  }

  Future<GatePassLog?> findPendingOpenGatePass({
    required String schoolYearId,
    required String personId,
  }) async {
    final pending = await loadPendingGatePassLogs();
    for (final log in pending.reversed) {
      if (log.schoolYearId == schoolYearId &&
          log.personId == personId &&
          log.status == GatePassStatus.outside) {
        return log;
      }
    }
    return null;
  }

  Future<GatePassLog?> findPendingUnclosedGatePass({
    required String schoolYearId,
    required String personId,
  }) async {
    final pending = await loadPendingGatePassLogs();
    for (final log in pending.reversed) {
      if (log.schoolYearId == schoolYearId &&
          log.personId == personId &&
          log.status != GatePassStatus.returned) {
        return log;
      }
    }
    return null;
  }

  Future<void> updatePendingGatePass(GatePassLog updatedLog) async {
    final pending = await loadPendingGatePassLogs();
    final index = pending.indexWhere((log) => log.id == updatedLog.id);
    if (index == -1) return;
    await (await _pendingGatePassBox()).put(updatedLog.id, {
      'id': updatedLog.id,
      'data': _offlineGatePassMap(updatedLog),
    });
  }

  Future<void> cacheActiveSchoolYear(SchoolYear schoolYear) async {
    await (await _schoolCacheBoxInstance()).put(_activeSchoolYearKey, {
      'id': schoolYear.id,
      'data': _schoolYearMap(schoolYear),
    });
  }

  Future<SchoolYear?> loadCachedActiveSchoolYear() async {
    final decoded = (await _schoolCacheBoxInstance()).get(_activeSchoolYearKey);
    if (decoded == null) return null;
    return SchoolYear.fromMap(
      decoded['id'] as String,
      Map<String, dynamic>.from(decoded['data'] as Map),
    );
  }

  Future<void> cachePerson({
    required String schoolYearId,
    required String personId,
    required String fullName,
    required String role,
    required String section,
    String assignedTimeIn = '07:00',
    String assignedTimeOut = '17:00',
    String contactNumber = '',
  }) async {
    final key = '$schoolYearId-$personId';
    await (await _peopleBoxInstance()).put(key, {
      'key': key,
      'schoolYearId': schoolYearId,
      'personId': personId,
      'fullName': fullName,
      'role': role,
      'section': section,
      'assignedTimeIn': assignedTimeIn,
      'assignedTimeOut': assignedTimeOut,
      'contactNumber': contactNumber,
    });
  }

  Future<Map<String, dynamic>?> findCachedPerson({
    required String schoolYearId,
    required String personId,
  }) async {
    final key = '$schoolYearId-$personId';
    final person = (await _peopleBoxInstance()).get(key);
    return person == null ? null : Map<String, dynamic>.from(person);
  }

  Future<void> remove(String id) async {
    await (await _pendingAttendanceBox()).delete(id);
  }

  Future<void> removeGatePass(String id) async {
    await (await _pendingGatePassBox()).delete(id);
  }

  Future<void> markFailed(String id) async {
    final box = await _pendingAttendanceBox();
    final item = box.get(id);
    if (item == null) return;
    final data = Map<String, dynamic>.from(item['data'] as Map);
    data['syncStatus'] = SyncStatus.failedSync.name;
    await box.put(id, {'id': id, 'data': data});
  }

  Map<String, dynamic> _offlineMap(AttendanceLog log) => {
    ...log.toMap(),
    'timestamp': log.timestamp.toIso8601String(),
    'syncStatus': 'pendingSync',
  };

  Map<String, dynamic> _offlineGatePassMap(GatePassLog log) => {
    ...log.toMap(),
    'exitTime': log.exitTime.toIso8601String(),
    'returnTime': log.returnTime?.toIso8601String(),
    'timestamp': log.timestamp.toIso8601String(),
    'updatedAt': log.updatedAt.toIso8601String(),
    'syncStatus': 'pendingSync',
  };

  Map<String, dynamic> _schoolYearMap(SchoolYear schoolYear) => {
    ...schoolYear.toMap(),
    'term1Start': schoolYear.termStarts.elementAtOrNull(0)?.toIso8601String(),
    'term1End': schoolYear.termEnds.elementAtOrNull(0)?.toIso8601String(),
    'term2Start': schoolYear.termStarts.elementAtOrNull(1)?.toIso8601String(),
    'term2End': schoolYear.termEnds.elementAtOrNull(1)?.toIso8601String(),
    'term3Start': schoolYear.termStarts.elementAtOrNull(2)?.toIso8601String(),
    'term3End': schoolYear.termEnds.elementAtOrNull(2)?.toIso8601String(),
  };

  bool _hasDuplicateWithinWindow(
    List<AttendanceLog> logs,
    AttendanceLog log, {
    required int duplicateWindowMinutes,
  }) {
    final window = Duration(minutes: duplicateWindowMinutes);
    return logs.any((item) {
      if (item.duplicateKey != log.duplicateKey) return false;
      final difference = item.timestamp.difference(log.timestamp).abs();
      return difference <= window;
    });
  }

  Future<Box<Map>> _pendingAttendanceBox() async {
    return _attendanceBox ??= await Hive.openBox<Map>(_attendanceBoxName);
  }

  Future<Box<Map>> _pendingGatePassBox() async {
    return _gatePassBox ??= await Hive.openBox<Map>(_gatePassBoxName);
  }

  Future<Box<Map>> _schoolCacheBoxInstance() async {
    return _schoolCacheBox ??= await Hive.openBox<Map>(_schoolCacheBoxName);
  }

  Future<Box<Map>> _peopleBoxInstance() async {
    return _peopleBox ??= await Hive.openBox<Map>(_peopleBoxName);
  }
}
