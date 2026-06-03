import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

import '../core/constants/enums.dart';
import 'model_serializers.dart';

class GatePassLog {
  const GatePassLog({
    required this.id,
    required this.personId,
    required this.fullName,
    required this.personRole,
    required this.section,
    required this.dateKey,
    required this.exitTime,
    required this.exitTimeText,
    required this.returnTime,
    required this.returnTimeText,
    required this.reason,
    required this.teacherBusinessType,
    required this.expectedToReturn,
    required this.status,
    required this.durationMinutes,
    required this.scannedBy,
    required this.scannerUserId,
    required this.deviceId,
    required this.offline,
    required this.syncStatus,
    required this.schoolYearId,
    required this.schoolYear,
    required this.activeTerm,
    required this.timestamp,
    required this.updatedAt,
  });

  final String id;
  final String personId;
  final String fullName;
  final PersonRole personRole;
  final String section;
  final String dateKey;
  final DateTime exitTime;
  final String exitTimeText;
  final DateTime? returnTime;
  final String returnTimeText;
  final String reason;
  final TeacherBusinessType? teacherBusinessType;
  final bool expectedToReturn;
  final GatePassStatus status;
  final int durationMinutes;
  final String scannedBy;
  final String scannerUserId;
  final String deviceId;
  final bool offline;
  final SyncStatus syncStatus;
  final String schoolYearId;
  final String schoolYear;
  final String activeTerm;
  final DateTime timestamp;
  final DateTime updatedAt;

  bool get countsTowardTeacherPersonalAllowance =>
      personRole == PersonRole.teacher &&
      teacherBusinessType == TeacherBusinessType.personal &&
      durationMinutes > 0;

  GatePassLog copyWith({
    DateTime? returnTime,
    String? returnTimeText,
    GatePassStatus? status,
    int? durationMinutes,
    bool? offline,
    SyncStatus? syncStatus,
    DateTime? updatedAt,
  }) {
    return GatePassLog(
      id: id,
      personId: personId,
      fullName: fullName,
      personRole: personRole,
      section: section,
      dateKey: dateKey,
      exitTime: exitTime,
      exitTimeText: exitTimeText,
      returnTime: returnTime ?? this.returnTime,
      returnTimeText: returnTimeText ?? this.returnTimeText,
      reason: reason,
      teacherBusinessType: teacherBusinessType,
      expectedToReturn: expectedToReturn,
      status: status ?? this.status,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      scannedBy: scannedBy,
      scannerUserId: scannerUserId,
      deviceId: deviceId,
      offline: offline ?? this.offline,
      syncStatus: syncStatus ?? this.syncStatus,
      schoolYearId: schoolYearId,
      schoolYear: schoolYear,
      activeTerm: activeTerm,
      timestamp: timestamp,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory GatePassLog.fromMap(String id, Map<String, dynamic> data) {
    final exitTime = toDate(data['exitTime']) ?? DateTime.now();
    final returnTime = toDate(data['returnTime']);
    return GatePassLog(
      id: id,
      personId: data['personId'] as String? ?? '',
      fullName: data['fullName'] as String? ?? '',
      personRole: (data['personRole'] as String? ?? 'student') == 'teacher'
          ? PersonRole.teacher
          : PersonRole.student,
      section: data['section'] as String? ?? '',
      dateKey:
          data['dateKey'] as String? ??
          DateFormat('yyyy-MM-dd').format(exitTime),
      exitTime: exitTime,
      exitTimeText:
          data['exitTimeText'] as String? ??
          DateFormat('hh:mm a').format(exitTime),
      returnTime: returnTime,
      returnTimeText: data['returnTimeText'] as String? ?? '',
      reason: data['reason'] as String? ?? '',
      teacherBusinessType: TeacherBusinessType.fromKey(
        data['teacherBusinessType'] as String?,
      ),
      expectedToReturn: data['expectedToReturn'] as bool? ?? true,
      status: GatePassStatus.fromKey(data['status'] as String?),
      durationMinutes: data['durationMinutes'] as int? ?? 0,
      scannedBy: data['scannedBy'] as String? ?? '',
      scannerUserId: data['scannerUserId'] as String? ?? '',
      deviceId: data['deviceId'] as String? ?? '',
      offline: data['offline'] as bool? ?? false,
      syncStatus: SyncStatus.fromKey(data['syncStatus'] as String?),
      schoolYearId: data['schoolYearId'] as String? ?? '',
      schoolYear: data['schoolYear'] as String? ?? '',
      activeTerm: data['activeTerm'] as String? ?? '',
      timestamp: toDate(data['timestamp']) ?? exitTime,
      updatedAt: toDate(data['updatedAt']) ?? exitTime,
    );
  }

  factory GatePassLog.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) =>
      GatePassLog.fromMap(doc.id, doc.data() ?? {});

  Map<String, dynamic> toMap() => {
    'personId': personId,
    'fullName': fullName,
    'personRole': personRole.name,
    'section': section,
    'dateKey': dateKey,
    'exitTime': Timestamp.fromDate(exitTime),
    'exitTimeText': exitTimeText,
    'returnTime': fromDate(returnTime),
    'returnTimeText': returnTimeText,
    'reason': reason,
    'teacherBusinessType': teacherBusinessType?.name,
    'expectedToReturn': expectedToReturn,
    'status': status.name,
    'durationMinutes': durationMinutes,
    'scannedBy': scannedBy,
    'scannerUserId': scannerUserId,
    'deviceId': deviceId,
    'offline': offline,
    'syncStatus': syncStatus.name,
    'schoolYearId': schoolYearId,
    'schoolYear': schoolYear,
    'activeTerm': activeTerm,
    'timestamp': Timestamp.fromDate(timestamp),
    'updatedAt': Timestamp.fromDate(updatedAt),
  };
}
