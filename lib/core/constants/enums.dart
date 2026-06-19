enum UserRole {
  systemAdministrator,
  schoolAdministrator,
  staffScanner;

  String get label => switch (this) {
    UserRole.systemAdministrator => 'System Administrator',
    UserRole.schoolAdministrator => 'School Administrator',
    UserRole.staffScanner => 'Staff Scanner',
  };

  String get key => switch (this) {
    UserRole.systemAdministrator => 'system_administrator',
    UserRole.schoolAdministrator => 'school_administrator',
    UserRole.staffScanner => 'staff_scanner',
  };

  int get userLimit => switch (this) {
    UserRole.systemAdministrator => 1,
    UserRole.schoolAdministrator => 3,
    UserRole.staffScanner => 3,
  };

  static UserRole fromKey(String? value) => UserRole.values.firstWhere(
    (role) => role.key == value,
    orElse: () => UserRole.staffScanner,
  );
}

enum AccountStatus {
  active,
  disabled;

  String get label => this == AccountStatus.active ? 'Active' : 'Disabled';

  static AccountStatus fromKey(String? value) =>
      value == 'disabled' ? AccountStatus.disabled : AccountStatus.active;
}

enum PersonRole {
  student,
  teacher;

  String get label => this == PersonRole.student ? 'Student' : 'Teacher';
}

enum PersonGender {
  male,
  female;

  String get label => this == PersonGender.male ? 'Male' : 'Female';

  static PersonGender? fromValue(String? value) {
    final normalized = value?.trim().toLowerCase();
    return switch (normalized) {
      'male' || 'm' => PersonGender.male,
      'female' || 'f' => PersonGender.female,
      _ => null,
    };
  }
}

enum AttendanceType {
  timeIn,
  timeOut;

  String get label => switch (this) {
    AttendanceType.timeIn => 'Time In',
    AttendanceType.timeOut => 'Time Out',
  };

  String get key => name;

  bool get isTimeIn => this == AttendanceType.timeIn;

  bool get isTimeOut => this == AttendanceType.timeOut;

  static const scannerTypes = [AttendanceType.timeIn, AttendanceType.timeOut];

  static AttendanceType fromKey(String? value) {
    return switch (value) {
      'timeOut' ||
      'morningTimeOut' ||
      'afternoonTimeOut' => AttendanceType.timeOut,
      _ => AttendanceType.timeIn,
    };
  }
}

enum ScannerLogMode {
  attendance,
  gatePass;

  String get label => switch (this) {
    ScannerLogMode.attendance => 'Attendance',
    ScannerLogMode.gatePass => 'Gate Pass',
  };
}

enum GatePassAction {
  logOut,
  logBackIn;

  String get label => switch (this) {
    GatePassAction.logOut => 'Log Out',
    GatePassAction.logBackIn => 'Log Back In',
  };
}

enum TeacherBusinessType {
  personal,
  school;

  String get label => switch (this) {
    TeacherBusinessType.personal => 'Personal Business',
    TeacherBusinessType.school => 'School Business',
  };

  static TeacherBusinessType? fromKey(String? value) {
    return switch (value) {
      'personal' => TeacherBusinessType.personal,
      'school' => TeacherBusinessType.school,
      _ => null,
    };
  }
}

enum GatePassStatus {
  outside,
  returned,
  noReturn;

  String get label => switch (this) {
    GatePassStatus.outside => 'Outside',
    GatePassStatus.returned => 'Returned',
    GatePassStatus.noReturn => 'No Return',
  };

  static GatePassStatus fromKey(String? value) {
    return GatePassStatus.values.firstWhere(
      (status) => status.name == value,
      orElse: () => GatePassStatus.outside,
    );
  }
}

enum AttendanceStatus {
  early,
  onTime,
  late,
  absent,
  incomplete,
  duplicate;

  String get label => switch (this) {
    AttendanceStatus.early => 'Early',
    AttendanceStatus.onTime => 'On Time',
    AttendanceStatus.late => 'Late',
    AttendanceStatus.absent => 'Absent',
    AttendanceStatus.incomplete => 'Incomplete',
    AttendanceStatus.duplicate => 'Duplicate',
  };
}

enum SyncStatus {
  synced,
  pendingSync,
  failedSync;

  String get label => switch (this) {
    SyncStatus.synced => 'Synced',
    SyncStatus.pendingSync => 'Pending Sync',
    SyncStatus.failedSync => 'Failed Sync',
  };

  static SyncStatus fromKey(String? value) => SyncStatus.values.firstWhere(
    (status) => status.name == value,
    orElse: () => SyncStatus.pendingSync,
  );
}
