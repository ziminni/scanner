class SystemSettings {
  const SystemSettings({
    this.studentTimeIn = '07:00',
    this.studentTimeOut = '17:00',
    this.earlyBeforeMinutes = 15,
    this.duplicateWindowMinutes = 240,
    this.scannerDetectionCooldownSeconds = 2,
    this.scanIssueAutoCloseSeconds = 8,
    this.successFeedbackSeconds = 3,
    this.gatePassReasonWordLimit = 52,
  });

  final String studentTimeIn;
  final String studentTimeOut;
  final int earlyBeforeMinutes;
  final int duplicateWindowMinutes;
  final int scannerDetectionCooldownSeconds;
  final int scanIssueAutoCloseSeconds;
  final int successFeedbackSeconds;
  final int gatePassReasonWordLimit;

  factory SystemSettings.fromMap(Map<String, dynamic>? data) => SystemSettings(
    studentTimeIn: data?['studentTimeIn'] as String? ?? '07:00',
    studentTimeOut: data?['studentTimeOut'] as String? ?? '17:00',
    earlyBeforeMinutes: data?['earlyBeforeMinutes'] as int? ?? 15,
    duplicateWindowMinutes: data?['duplicateWindowMinutes'] as int? ?? 240,
    scannerDetectionCooldownSeconds:
        data?['scannerDetectionCooldownSeconds'] as int? ?? 2,
    scanIssueAutoCloseSeconds: data?['scanIssueAutoCloseSeconds'] as int? ?? 8,
    successFeedbackSeconds: data?['successFeedbackSeconds'] as int? ?? 3,
    gatePassReasonWordLimit: data?['gatePassReasonWordLimit'] as int? ?? 52,
  );

  Map<String, dynamic> toMap() => {
    'studentTimeIn': studentTimeIn,
    'studentTimeOut': studentTimeOut,
    'earlyBeforeMinutes': earlyBeforeMinutes,
    'duplicateWindowMinutes': duplicateWindowMinutes,
    'scannerDetectionCooldownSeconds': scannerDetectionCooldownSeconds,
    'scanIssueAutoCloseSeconds': scanIssueAutoCloseSeconds,
    'successFeedbackSeconds': successFeedbackSeconds,
    'gatePassReasonWordLimit': gatePassReasonWordLimit,
  };
}
