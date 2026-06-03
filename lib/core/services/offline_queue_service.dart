import 'dart:async';
import 'dart:convert';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/enums.dart';
import '../../models/models.dart';

class OfflineQueueService {
  static const _queueKey = 'pending_attendance_logs';
  static const _gatePassQueueKey = 'pending_gate_pass_logs';
  static const _activeSchoolYearKey = 'cached_active_school_year';
  static const _personCacheKey = 'cached_people';

  OfflineQueueService(this._connectivity);

  final Connectivity _connectivity;
  final _syncRequests = StreamController<void>.broadcast();

  Stream<void> get syncRequests => _syncRequests.stream;

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
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_queueKey) ?? const [];
    return raw.map((item) {
      final decoded = jsonDecode(item) as Map<String, dynamic>;
      return AttendanceLog.fromMap(
        decoded['id'] as String,
        Map<String, dynamic>.from(decoded['data'] as Map),
      );
    }).toList();
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
    pending.add(log);
    await _save(pending);
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
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_gatePassQueueKey) ?? const [];
    return raw.map((item) {
      final decoded = jsonDecode(item) as Map<String, dynamic>;
      return GatePassLog.fromMap(
        decoded['id'] as String,
        Map<String, dynamic>.from(decoded['data'] as Map),
      );
    }).toList();
  }

  Future<void> enqueueGatePass(GatePassLog log) async {
    final pending = await loadPendingGatePassLogs();
    if (pending.any((item) => item.id == log.id)) return;
    pending.add(log);
    await _saveGatePassLogs(pending);
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
    pending[index] = updatedLog;
    await _saveGatePassLogs(pending);
  }

  Future<void> cacheActiveSchoolYear(SchoolYear schoolYear) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _activeSchoolYearKey,
      jsonEncode({'id': schoolYear.id, 'data': _schoolYearMap(schoolYear)}),
    );
  }

  Future<SchoolYear?> loadCachedActiveSchoolYear() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_activeSchoolYearKey);
    if (raw == null) return null;
    final decoded = jsonDecode(raw) as Map<String, dynamic>;
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
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final people = prefs.getStringList(_personCacheKey) ?? const [];
    final key = '$schoolYearId-$personId';
    final next =
        people
            .map((item) => jsonDecode(item) as Map<String, dynamic>)
            .where((item) => item['key'] != key)
            .toList()
          ..add({
            'key': key,
            'schoolYearId': schoolYearId,
            'personId': personId,
            'fullName': fullName,
            'role': role,
            'section': section,
            'assignedTimeIn': assignedTimeIn,
            'assignedTimeOut': assignedTimeOut,
          });
    await prefs.setStringList(_personCacheKey, next.map(jsonEncode).toList());
  }

  Future<Map<String, dynamic>?> findCachedPerson({
    required String schoolYearId,
    required String personId,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final key = '$schoolYearId-$personId';
    final people = prefs.getStringList(_personCacheKey) ?? const [];
    for (final item in people) {
      final decoded = jsonDecode(item) as Map<String, dynamic>;
      if (decoded['key'] == key) return decoded;
    }
    return null;
  }

  Future<void> remove(String id) async {
    final pending = await loadPendingLogs();
    pending.removeWhere((log) => log.id == id);
    await _save(pending);
  }

  Future<void> removeGatePass(String id) async {
    final pending = await loadPendingGatePassLogs();
    pending.removeWhere((log) => log.id == id);
    await _saveGatePassLogs(pending);
  }

  Future<void> markFailed(String id) async {
    final pending = await loadPendingLogs();
    await _save(pending);
  }

  Future<void> _save(List<AttendanceLog> logs) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _queueKey,
      logs
          .map((log) => jsonEncode({'id': log.id, 'data': _offlineMap(log)}))
          .toList(),
    );
  }

  Future<void> _saveGatePassLogs(List<GatePassLog> logs) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _gatePassQueueKey,
      logs
          .map(
            (log) =>
                jsonEncode({'id': log.id, 'data': _offlineGatePassMap(log)}),
          )
          .toList(),
    );
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
}
