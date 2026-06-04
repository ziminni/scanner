import 'package:flutter/foundation.dart';
import 'package:another_telephony/telephony.dart';

import '../../models/models.dart';

class SmsNotificationService {
  SmsNotificationService({Telephony? telephony})
    : _telephony = telephony ?? Telephony.instance;

  final Telephony _telephony;
  bool _permissionsRequested = false;
  bool _permissionsGranted = false;

  Future<void> notifyAttendance({
    required AttendanceLog log,
    required String recipient,
  }) async {
    if (!_canSendTo(recipient)) return;
    await _send(
      to: recipient,
      message:
          'Leon Garcia NHS Attendance: ${log.fullName} recorded ${log.attendanceType.label} at ${log.timeText}. Status: ${log.attendanceStatus.label}. Scanned by ${log.scannedBy}.',
    );
  }

  Future<void> notifyGatePassExit({
    required GatePassLog log,
    required String recipient,
  }) async {
    if (!_canSendTo(recipient)) return;
    await _send(
      to: recipient,
      message:
          'Leon Garcia NHS Gate Pass: ${log.fullName} logged out at ${log.exitTimeText}. Reason: ${log.reason}. Expected to return: ${log.expectedToReturn ? 'Yes' : 'No'}. Scanned by ${log.scannedBy}.',
    );
  }

  Future<void> notifyGatePassReturn({
    required GatePassLog log,
    required String recipient,
  }) async {
    if (!_canSendTo(recipient)) return;
    await _send(
      to: recipient,
      message:
          'Leon Garcia NHS Gate Pass: ${log.fullName} logged back in at ${log.returnTimeText}. Duration: ${log.durationMinutes} minutes. Scanned by ${log.scannedBy}.',
    );
  }

  Future<void> _send({required String to, required String message}) async {
    if (kIsWeb) return;
    if (!await _ensureSmsPermission()) return;
    await _telephony.sendSms(to: to, message: message, isMultipart: true);
  }

  Future<bool> _ensureSmsPermission() async {
    if (_permissionsGranted) return true;
    if (_permissionsRequested) return _permissionsGranted;
    _permissionsRequested = true;
    _permissionsGranted = await _telephony.requestSmsPermissions ?? false;
    return _permissionsGranted;
  }

  bool _canSendTo(String recipient) {
    return !kIsWeb && recipient.trim().isNotEmpty;
  }
}
