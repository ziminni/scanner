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

enum AttendanceType {
  morningTimeIn,
  morningTimeOut,
  afternoonTimeIn,
  afternoonTimeOut;

  String get label => switch (this) {
    AttendanceType.morningTimeIn => 'Morning Time In',
    AttendanceType.morningTimeOut => 'Morning Time Out',
    AttendanceType.afternoonTimeIn => 'Afternoon Time In',
    AttendanceType.afternoonTimeOut => 'Afternoon Time Out',
  };

  String get key => name;

  static AttendanceType fromKey(String? value) =>
      AttendanceType.values.firstWhere(
        (type) => type.key == value,
        orElse: () => AttendanceType.morningTimeIn,
      );
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
