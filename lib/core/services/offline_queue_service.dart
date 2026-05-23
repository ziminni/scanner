import 'dart:async';
import 'dart:convert';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../models/models.dart';

class OfflineQueueService {
  static const _queueKey = 'pending_attendance_logs';

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

  Future<void> enqueue(AttendanceLog log) async {
    final pending = await loadPendingLogs();
    if (pending.any((item) => item.duplicateKey == log.duplicateKey)) return;
    pending.add(log);
    await _save(pending);
  }

  Future<void> remove(String id) async {
    final pending = await loadPendingLogs();
    pending.removeWhere((log) => log.id == id);
    await _save(pending);
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

  Map<String, dynamic> _offlineMap(AttendanceLog log) => {
    ...log.toMap(),
    'timestamp': log.timestamp.toIso8601String(),
    'syncStatus': 'pendingSync',
  };
}
