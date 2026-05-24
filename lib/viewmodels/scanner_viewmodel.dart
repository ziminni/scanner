import '../core/services/app_controller.dart';
import '../models/enums.dart';
import '../models/models.dart';
import 'base_viewmodel.dart';

class ScannerViewModel extends BaseViewModel {
  ScannerViewModel(this._app);

  final AppController _app;

  AttendanceType type = AttendanceType.timeIn;
  AttendanceLog? lastLog;
  String? message;
  String? _lastScannedCode;
  DateTime? _lastScannedAt;

  void selectType(AttendanceType nextType) {
    type = nextType;
    _lastScannedCode = null;
    _lastScannedAt = null;
    notifyListeners();
  }

  Future<void> submit(String raw) async {
    final id = raw.trim();
    if (id.isEmpty) return;
    setBusy(true);
    message = null;
    notifyListeners();
    try {
      final log = await _app.attendance.scanId(
        scannedId: id,
        type: type,
        scanner: _app.currentUser!,
        deviceId: 'device-${_app.currentUser!.id}',
      );
      lastLog = log;
      message = log.attendanceStatus == AttendanceStatus.duplicate
          ? 'Duplicate scan ignored for this attendance type today.'
          : '${log.fullName} logged as ${log.attendanceType.label}.';
    } catch (error) {
      message = error.toString();
    } finally {
      setBusy(false);
    }
  }

  bool shouldAcceptDetectedCode(String code) {
    final now = DateTime.now();
    final recentlyScannedSameCode =
        code == _lastScannedCode &&
        _lastScannedAt != null &&
        now.difference(_lastScannedAt!) < const Duration(seconds: 2);
    if (busy || recentlyScannedSameCode) return false;
    _lastScannedCode = code;
    _lastScannedAt = now;
    return true;
  }
}
