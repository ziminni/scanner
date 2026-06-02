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
