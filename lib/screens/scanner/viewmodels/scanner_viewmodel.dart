import '../../../core/services/app_controller.dart';
import '../../../core/constants/enums.dart';
import '../../../models/models.dart';
import 'base_viewmodel.dart';

class ScannerViewModel extends BaseViewModel {
  ScannerViewModel(this._app);

  final AppController _app;

  ScannerLogMode mode = ScannerLogMode.attendance;
  AttendanceType type = AttendanceType.timeIn;
  GatePassAction gatePassAction = GatePassAction.logOut;
  TeacherBusinessType teacherBusinessType = TeacherBusinessType.personal;
  bool expectedToReturn = true;
  AttendanceLog? lastLog;
  GatePassLog? lastGatePassLog;
  String? message;
  String? _lastScannedCode;
  DateTime? _lastScannedAt;
  SystemSettings _settings = const SystemSettings();

  SystemSettings get settings => _settings;

  Future<void> loadSettings() async {
    _settings = await _app.attendance.loadSettings();
    notifyListeners();
  }

  void selectMode(ScannerLogMode nextMode) {
    mode = nextMode;
    lastLog = null;
    lastGatePassLog = null;
    _resetDetectionBuffer();
    notifyListeners();
  }

  void selectType(AttendanceType nextType) {
    type = nextType;
    _resetDetectionBuffer();
    notifyListeners();
  }

  void selectGatePassAction(GatePassAction action) {
    gatePassAction = action;
    _resetDetectionBuffer();
    notifyListeners();
  }

  void selectTeacherBusinessType(TeacherBusinessType type) {
    teacherBusinessType = type;
    notifyListeners();
  }

  void setExpectedToReturn(bool value) {
    expectedToReturn = value;
    notifyListeners();
  }

  Future<void> validateGatePassLogOut(String scannedId) {
    return _app.attendance.validateGatePassExitAllowed(scannedId);
  }

  void clearResult() {
    lastLog = null;
    lastGatePassLog = null;
    message = null;
    notifyListeners();
  }

  Future<void> submit(
    String raw, {
    String reason = '',
    TeacherBusinessType? gatePassBusinessType,
    bool? gatePassExpectedToReturn,
  }) async {
    final id = raw.trim();
    if (id.isEmpty) return;
    setBusy(true);
    message = null;
    lastLog = null;
    lastGatePassLog = null;
    notifyListeners();
    try {
      if (mode == ScannerLogMode.attendance) {
        final log = await _app.attendance.scanId(
          scannedId: id,
          type: type,
          scanner: _app.currentUser!,
          deviceId: 'device-${_app.currentUser!.id}',
        );
        lastLog = log;
        lastGatePassLog = null;
        message = log.attendanceStatus == AttendanceStatus.duplicate
            ? 'Duplicate scan ignored for this attendance type today.'
            : '${log.fullName} logged as ${log.attendanceType.label}.';
      } else {
        if (gatePassBusinessType != null) {
          teacherBusinessType = gatePassBusinessType;
        }
        if (gatePassExpectedToReturn != null) {
          expectedToReturn = gatePassExpectedToReturn;
        }
        final log = gatePassAction == GatePassAction.logOut
            ? await _app.attendance.logGatePassExit(
                scannedId: id,
                reason: reason,
                teacherBusinessType:
                    gatePassBusinessType ?? teacherBusinessType,
                expectedToReturn: gatePassExpectedToReturn ?? expectedToReturn,
                scanner: _app.currentUser!,
                deviceId: 'device-${_app.currentUser!.id}',
              )
            : await _app.attendance.logGatePassReturn(
                scannedId: id,
                scanner: _app.currentUser!,
                deviceId: 'device-${_app.currentUser!.id}',
              );
        lastGatePassLog = log;
        lastLog = null;
        message = gatePassAction == GatePassAction.logOut
            ? '${log.fullName} logged out for gate pass.'
            : '${log.fullName} logged back in after ${log.durationMinutes} minutes.';
      }
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
        now.difference(_lastScannedAt!) <
            Duration(seconds: _settings.scannerDetectionCooldownSeconds);
    if (busy || recentlyScannedSameCode) return false;
    _lastScannedCode = code;
    _lastScannedAt = now;
    return true;
  }

  int wordCount(String value) {
    return value
        .trim()
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty)
        .length;
  }

  void _resetDetectionBuffer() {
    _lastScannedCode = null;
    _lastScannedAt = null;
  }
}
