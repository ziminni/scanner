import 'package:cloud_firestore/cloud_firestore.dart';

import 'enums.dart';

DateTime? _toDate(dynamic value) {
  if (value is Timestamp) return value.toDate();
  if (value is DateTime) return value;
  if (value is String) return DateTime.tryParse(value);
  return null;
}

dynamic _fromDate(DateTime? value) =>
    value == null ? null : Timestamp.fromDate(value);

class AppUser {
  const AppUser({
    required this.id,
    required this.email,
    required this.fullName,
    required this.role,
    required this.status,
    this.schoolId = 'default',
    this.createdAt,
    this.lastLoginAt,
  });

  final String id;
  final String email;
  final String fullName;
  final UserRole role;
  final AccountStatus status;
  final String schoolId;
  final DateTime? createdAt;
  final DateTime? lastLoginAt;

  bool get isActive => status == AccountStatus.active;

  factory AppUser.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return AppUser.fromMap(doc.id, data);
  }

  factory AppUser.fromMap(String id, Map<String, dynamic> data) => AppUser(
    id: id,
    email: data['email'] as String? ?? '',
    fullName: data['fullName'] as String? ?? data['name'] as String? ?? '',
    role: UserRole.fromKey(data['role'] as String?),
    status: AccountStatus.fromKey(data['status'] as String?),
    schoolId: data['schoolId'] as String? ?? 'default',
    createdAt: _toDate(data['createdAt']),
    lastLoginAt: _toDate(data['lastLoginAt']),
  );

  Map<String, dynamic> toMap() => {
    'email': email,
    'fullName': fullName,
    'role': role.key,
    'status': status.name,
    'schoolId': schoolId,
    'createdAt': _fromDate(createdAt),
    'lastLoginAt': _fromDate(lastLoginAt),
  };
}

class SchoolYear {
  const SchoolYear({
    required this.id,
    required this.name,
    required this.isActive,
    required this.archived,
    required this.termStarts,
    required this.termEnds,
  });

  final String id;
  final String name;
  final bool isActive;
  final bool archived;
  final List<DateTime?> termStarts;
  final List<DateTime?> termEnds;

  bool get hasCompleteTerms =>
      termStarts.length >= 3 &&
      termEnds.length >= 3 &&
      termStarts.every((date) => date != null) &&
      termEnds.every((date) => date != null);

  DateTime? get finalTermEnd => termEnds.length >= 3 ? termEnds[2] : null;

  bool isFinished(DateTime date) {
    final end = finalTermEnd;
    if (end == null) return false;
    return date.isAfter(DateTime(end.year, end.month, end.day, 23, 59, 59));
  }

  String activeTermName(DateTime date) {
    for (var index = 0; index < 3; index++) {
      final start = termStarts.length > index ? termStarts[index] : null;
      final end = termEnds.length > index ? termEnds[index] : null;
      if (start != null &&
          end != null &&
          !date.isBefore(start) &&
          !date.isAfter(end)) {
        return '${index + 1}${index == 0
            ? 'st'
            : index == 1
            ? 'nd'
            : 'rd'} Term';
      }
    }
    return 'Outside Term';
  }

  factory SchoolYear.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    return SchoolYear.fromMap(doc.id, doc.data() ?? {});
  }

  factory SchoolYear.fromMap(String id, Map<String, dynamic> data) {
    return SchoolYear(
      id: id,
      name: data['name'] as String? ?? '',
      isActive: data['isActive'] as bool? ?? false,
      archived: data['archived'] as bool? ?? false,
      termStarts: [
        _toDate(data['term1Start']),
        _toDate(data['term2Start']),
        _toDate(data['term3Start']),
      ],
      termEnds: [
        _toDate(data['term1End']),
        _toDate(data['term2End']),
        _toDate(data['term3End']),
      ],
    );
  }

  Map<String, dynamic> toMap() => {
    'name': name,
    'isActive': isActive,
    'archived': archived,
    'term1Start': _fromDate(termStarts.elementAtOrNull(0)),
    'term1End': _fromDate(termEnds.elementAtOrNull(0)),
    'term2Start': _fromDate(termStarts.elementAtOrNull(1)),
    'term2End': _fromDate(termEnds.elementAtOrNull(1)),
    'term3Start': _fromDate(termStarts.elementAtOrNull(2)),
    'term3End': _fromDate(termEnds.elementAtOrNull(2)),
  };
}

class Student {
  const Student({
    required this.id,
    required this.lrn,
    required this.lastName,
    required this.firstName,
    this.middleName = '',
    this.birthdate,
    this.address = '',
    this.guardianName = '',
    this.guardianContact = '',
    this.section = '',
    this.status = 'Active',
    this.archived = false,
  });

  final String id;
  final String lrn;
  final String lastName;
  final String firstName;
  final String middleName;
  final DateTime? birthdate;
  final String address;
  final String guardianName;
  final String guardianContact;
  final String section;
  final String status;
  final bool archived;

  String get fullName => [
    lastName,
    firstName,
    middleName,
  ].where((p) => p.trim().isNotEmpty).join(', ');

  factory Student.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return Student(
      id: doc.id,
      lrn: data['lrn'] as String? ?? doc.id,
      lastName: data['lastName'] as String? ?? '',
      firstName: data['firstName'] as String? ?? '',
      middleName: data['middleName'] as String? ?? '',
      birthdate: _toDate(data['birthdate']),
      address: data['address'] as String? ?? '',
      guardianName: data['guardianName'] as String? ?? '',
      guardianContact: data['guardianContact'] as String? ?? '',
      section: data['section'] as String? ?? '',
      status: data['status'] as String? ?? 'Active',
      archived: data['archived'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toMap() => {
    'lrn': lrn,
    'lastName': lastName,
    'firstName': firstName,
    'middleName': middleName,
    'birthdate': _fromDate(birthdate),
    'address': address,
    'guardianName': guardianName,
    'guardianContact': guardianContact,
    'section': section,
    'status': status,
    'archived': archived,
  };
}

class Teacher {
  const Teacher({
    required this.id,
    required this.teacherId,
    required this.lastName,
    required this.firstName,
    this.middleName = '',
    this.birthdate,
    this.address = '',
    this.contactNumber = '',
    this.assignedTimeIn = '07:00',
    this.assignedTimeOut = '17:00',
    this.status = 'Active',
    this.archived = false,
  });

  final String id;
  final String teacherId;
  final String lastName;
  final String firstName;
  final String middleName;
  final DateTime? birthdate;
  final String address;
  final String contactNumber;
  final String assignedTimeIn;
  final String assignedTimeOut;
  final String status;
  final bool archived;

  String get fullName => [
    lastName,
    firstName,
    middleName,
  ].where((p) => p.trim().isNotEmpty).join(', ');

  factory Teacher.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return Teacher(
      id: doc.id,
      teacherId: data['teacherId'] as String? ?? doc.id,
      lastName: data['lastName'] as String? ?? '',
      firstName: data['firstName'] as String? ?? '',
      middleName: data['middleName'] as String? ?? '',
      birthdate: _toDate(data['birthdate']),
      address: data['address'] as String? ?? '',
      contactNumber: data['contactNumber'] as String? ?? '',
      assignedTimeIn: data['assignedTimeIn'] as String? ?? '07:00',
      assignedTimeOut: data['assignedTimeOut'] as String? ?? '17:00',
      status: data['status'] as String? ?? 'Active',
      archived: data['archived'] as bool? ?? false,
    );
  }
}

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
        timestamp: _toDate(data['timestamp']) ?? DateTime.now(),
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

class SystemSettings {
  const SystemSettings({
    this.studentTimeIn = '07:00',
    this.studentTimeOut = '17:00',
    this.earlyBeforeMinutes = 15,
    this.duplicateWindowMinutes = 240,
  });

  final String studentTimeIn;
  final String studentTimeOut;
  final int earlyBeforeMinutes;
  final int duplicateWindowMinutes;

  factory SystemSettings.fromMap(Map<String, dynamic>? data) => SystemSettings(
    studentTimeIn: data?['studentTimeIn'] as String? ?? '07:00',
    studentTimeOut: data?['studentTimeOut'] as String? ?? '17:00',
    earlyBeforeMinutes: data?['earlyBeforeMinutes'] as int? ?? 15,
    duplicateWindowMinutes: data?['duplicateWindowMinutes'] as int? ?? 240,
  );

  Map<String, dynamic> toMap() => {
    'studentTimeIn': studentTimeIn,
    'studentTimeOut': studentTimeOut,
    'earlyBeforeMinutes': earlyBeforeMinutes,
    'duplicateWindowMinutes': duplicateWindowMinutes,
  };
}
