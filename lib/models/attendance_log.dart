import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/constants/enums.dart';
import 'model_serializers.dart';

class AttendanceLog {
  const AttendanceLog({
    required this.id,
    required this.personId,
    required this.fullName,
    required this.personRole,
    required this.section,
    required this.dateKey,
    required this.timeText,
    required this.attendanceType,
    required this.attendanceStatus,
    required this.scannedBy,
    required this.scannerUserId,
    required this.deviceId,
    required this.offline,
    required this.syncStatus,
    required this.timestamp,
    required this.schoolYearId,
    required this.schoolYear,
    required this.activeTerm,
  });

  final String id;
  final String personId;
  final String fullName;
  final PersonRole personRole;
  final String section;
  final String dateKey;
  final String timeText;
  final AttendanceType attendanceType;
  final AttendanceStatus attendanceStatus;
  final String scannedBy;
  final String scannerUserId;
  final String deviceId;
  final bool offline;
  final SyncStatus syncStatus;
  final DateTime timestamp;
  final String schoolYearId;
  final String schoolYear;
  final String activeTerm;

  String get duplicateKey =>
      '$schoolYearId-$personId-$dateKey-${attendanceType.key}';

  factory AttendanceLog.fromMap(String id, Map<String, dynamic> data) =>
      AttendanceLog(
        id: id,
        personId: data['personId'] as String? ?? '',
        fullName: data['fullName'] as String? ?? '',
        personRole: (data['personRole'] as String? ?? 'student') == 'teacher'
            ? PersonRole.teacher
            : PersonRole.student,
        section: data['section'] as String? ?? '',
        dateKey: data['dateKey'] as String? ?? '',
        timeText: data['timeText'] as String? ?? '',
        attendanceType: AttendanceType.fromKey(
          data['attendanceType'] as String?,
        ),
        attendanceStatus: AttendanceStatus.values.firstWhere(
          (status) => status.name == data['attendanceStatus'],
          orElse: () => AttendanceStatus.onTime,
        ),
        scannedBy: data['scannedBy'] as String? ?? '',
        scannerUserId: data['scannerUserId'] as String? ?? '',
        deviceId: data['deviceId'] as String? ?? '',
        offline: data['offline'] as bool? ?? false,
        syncStatus: SyncStatus.fromKey(data['syncStatus'] as String?),
        timestamp: toDate(data['timestamp']) ?? DateTime.now(),
        schoolYearId: data['schoolYearId'] as String? ?? '',
        schoolYear: data['schoolYear'] as String? ?? '',
        activeTerm: data['activeTerm'] as String? ?? '',
      );

  factory AttendanceLog.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) =>
      AttendanceLog.fromMap(doc.id, doc.data() ?? {});

  Map<String, dynamic> toMap() => {
    'personId': personId,
    'fullName': fullName,
    'personRole': personRole.name,
    'section': section,
    'dateKey': dateKey,
    'timeText': timeText,
    'attendanceType': attendanceType.key,
    'attendanceStatus': attendanceStatus.name,
    'scannedBy': scannedBy,
    'scannerUserId': scannerUserId,
    'deviceId': deviceId,
    'offline': offline,
    'syncStatus': syncStatus.name,
    'timestamp': Timestamp.fromDate(timestamp),
    'schoolYearId': schoolYearId,
    'schoolYear': schoolYear,
    'activeTerm': activeTerm,
    'duplicateKey': duplicateKey,
  };
}
