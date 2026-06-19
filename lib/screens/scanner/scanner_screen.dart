import 'dart:async';

import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../core/services/app_controller.dart';
import '../../core/constants/enums.dart';
import '../../models/models.dart';
import 'scanner_theme.dart';
import 'viewmodels/scanner_viewmodel.dart';

part 'widgets/last_scan_card.dart';

class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  final _manualId = TextEditingController();
  final _scannerController = MobileScannerController(
    detectionSpeed: DetectionSpeed.normal,
    detectionTimeoutMs: 1000,
    facing: CameraFacing.back,
  );
  late final ScannerViewModel _viewModel;
  bool _viewModelReady = false;
  bool _manualEntryVisible = false;
  bool _scanFlowActive = false;
  _ScanFeedbackData? _feedback;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_viewModelReady) return;
    _viewModel = ScannerViewModel(AppScope.of(context));
    _viewModelReady = true;
    unawaited(_viewModel.loadSettings());
  }

  @override
  void dispose() {
    _manualId.dispose();
    _scannerController.dispose();
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final feedback = _feedback;
    if (feedback != null) {
      return _ScanFeedbackPage(
        data: feedback,
        autoCloseSeconds: _viewModel.settings.successFeedbackSeconds,
        onDone: () {
          _viewModel.clearResult();
          setState(() {
            _feedback = null;
            _scanFlowActive = false;
          });
          _restartCameraAfterFrame();
        },
      );
    }

    return AnimatedBuilder(
      animation: _viewModel,
      builder: (context, _) {
        return ColoredBox(
          color: ScannerTheme.background,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              SizedBox(
                width: double.infinity,
                child: SegmentedButton<ScannerLogMode>(
                  style: SegmentedButton.styleFrom(
                    backgroundColor: ScannerTheme.surface,
                    selectedBackgroundColor: ScannerTheme.primarySoft,
                    selectedForegroundColor: ScannerTheme.primary,
                    foregroundColor: ScannerTheme.text,
                    side: const BorderSide(color: ScannerTheme.border),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  segments: const [
                    ButtonSegment(
                      value: ScannerLogMode.attendance,
                      icon: Icon(Icons.how_to_reg_outlined),
                      label: Text('Attendance'),
                    ),
                    ButtonSegment(
                      value: ScannerLogMode.gatePass,
                      icon: Icon(Icons.meeting_room_outlined),
                      label: Text('Gate Pass'),
                    ),
                  ],
                  selected: {_viewModel.mode},
                  onSelectionChanged: (selection) {
                    _viewModel.selectMode(selection.first);
                  },
                ),
              ),
              const SizedBox(height: 14),
              _ScannerActionDropdown(viewModel: _viewModel),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: ScannerTheme.panelDecoration(),
                child: AspectRatio(
                  aspectRatio: 3 / 4,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        MobileScanner(
                          controller: _scannerController,
                          fit: BoxFit.cover,
                          placeholderBuilder: (_) => const ColoredBox(
                            color: Colors.black,
                            child: Center(child: CircularProgressIndicator()),
                          ),
                          errorBuilder: (context, error) => ColoredBox(
                            color: Colors.black,
                            child: Center(
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Text(
                                  _scannerErrorMessage(error),
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ),
                            ),
                          ),
                          onDetect: (capture) {
                            final code = capture.barcodes
                                .map((barcode) => barcode.rawValue?.trim())
                                .whereType<String>()
                                .where((value) => value.isNotEmpty)
                                .firstOrNull;
                            if (code != null &&
                                _viewModel.shouldAcceptDetectedCode(code)) {
                              _submit(code);
                            }
                          },
                        ),
                        IgnorePointer(
                          child: Center(
                            child: Container(
                              width: 180,
                              height: 300,
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: Colors.white,
                                  width: 2,
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          right: 8,
                          bottom: 8,
                          child: Row(
                            children: [
                              IconButton.filledTonal(
                                tooltip: 'Flashlight',
                                icon: const Icon(Icons.flashlight_on_outlined),
                                onPressed: () =>
                                    _scannerController.toggleTorch(),
                              ),
                              const SizedBox(width: 8),
                              IconButton.filledTonal(
                                tooltip: 'Switch camera',
                                icon: const Icon(Icons.cameraswitch_outlined),
                                onPressed: () =>
                                    _scannerController.switchCamera(),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              if (!_manualEntryVisible)
                Center(
                  child: IconButton(
                    color: ScannerTheme.primary,
                    tooltip: 'Show manual entry',
                    icon: const Icon(Icons.keyboard_arrow_down),
                    onPressed: () {
                      setState(() => _manualEntryVisible = true);
                    },
                  ),
                ),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 180),
                child: _manualEntryVisible
                    ? Padding(
                        key: const ValueKey('manual-entry'),
                        padding: const EdgeInsets.only(top: 8),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: _manualId,
                                    decoration: const InputDecoration(
                                      labelText: 'Manual ID entry',
                                      prefixIcon: Icon(Icons.badge_outlined),
                                    ),
                                    onSubmitted: _submit,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                FilledButton.icon(
                                  style: FilledButton.styleFrom(
                                    backgroundColor: ScannerTheme.primary,
                                    foregroundColor: Colors.white,
                                  ),
                                  icon: const Icon(Icons.check),
                                  label: const Text('Log'),
                                  onPressed: _viewModel.busy
                                      ? null
                                      : () => _submit(_manualId.text),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            IconButton(
                              color: ScannerTheme.primary,
                              tooltip: 'Hide manual entry',
                              icon: const Icon(Icons.keyboard_arrow_up),
                              onPressed: () {
                                setState(() => _manualEntryVisible = false);
                              },
                            ),
                          ],
                        ),
                      )
                    : const SizedBox.shrink(
                        key: ValueKey('manual-entry-hidden'),
                      ),
              ),
              if (_viewModel.lastLog != null) ...[
                const SizedBox(height: 16),
                _LastScanCard(log: _viewModel.lastLog!),
              ],
              if (_viewModel.lastGatePassLog != null) ...[
                const SizedBox(height: 16),
                _LastGatePassCard(log: _viewModel.lastGatePassLog!),
              ],
            ],
          ),
        );
      },
    );
  }

  Future<void> _submit(String raw) async {
    if (_scanFlowActive) return;
    final id = raw.trim();
    if (id.isEmpty) return;
    _scanFlowActive = true;
    var resumeScanner = true;
    String reason = '';
    TeacherBusinessType? gatePassBusinessType;
    bool? gatePassExpectedToReturn;
    try {
      if (_viewModel.mode == ScannerLogMode.gatePass &&
          _viewModel.gatePassAction == GatePassAction.logOut) {
        await _viewModel.validateGatePassLogOut(id);
        final details = await _showGatePassReasonDialog();
        if (details == null) return;
        reason = details.reason;
        gatePassBusinessType = details.teacherBusinessType;
        gatePassExpectedToReturn = details.expectedToReturn;
      }
      await _viewModel.submit(
        id,
        reason: reason,
        gatePassBusinessType: gatePassBusinessType,
        gatePassExpectedToReturn: gatePassExpectedToReturn,
      );
      if (mounted && raw.trim().isNotEmpty) _manualId.clear();
      if (!mounted) return;

      final attendanceLog = _viewModel.lastLog;
      final gatePassLog = _viewModel.lastGatePassLog;
      if (attendanceLog != null &&
          attendanceLog.attendanceStatus == AttendanceStatus.duplicate) {
        await _showScanIssueDialog(
          _viewModel.message ??
              'Duplicate scan ignored for this attendance type today.',
        );
        return;
      }
      if (attendanceLog != null) {
        resumeScanner = false;
        await _showSuccessFeedback(
          await _feedbackDataFromAttendanceLog(attendanceLog),
        );
        return;
      }
      if (gatePassLog != null) {
        resumeScanner = false;
        await _showSuccessFeedback(
          await _feedbackDataFromGatePassLog(gatePassLog),
        );
        return;
      }
      final message = _viewModel.message;
      if (message != null && message.isNotEmpty) {
        await _showScanIssueDialog(message);
      }
    } catch (error) {
      if (mounted) await _showScanIssueDialog(error.toString());
    } finally {
      if (mounted && resumeScanner) {
        _scanFlowActive = false;
      }
    }
  }

  Future<void> _showSuccessFeedback(_ScanFeedbackData data) async {
    if (!mounted) return;
    setState(() => _feedback = data);
  }

  void _restartCameraAfterFrame() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _feedback != null) return;
      unawaited(_scannerController.start());
    });
  }

  Future<_ScanFeedbackData> _feedbackDataFromAttendanceLog(
    AttendanceLog log,
  ) async {
    return _ScanFeedbackData.fromAttendanceLog(
      log,
      sectionText: await _studentSectionText(
        role: log.personRole,
        section: log.section,
      ),
    );
  }

  Future<_ScanFeedbackData> _feedbackDataFromGatePassLog(
    GatePassLog log,
  ) async {
    return _ScanFeedbackData.fromGatePassLog(
      log,
      sectionText: await _studentSectionText(
        role: log.personRole,
        section: log.section,
      ),
    );
  }

  Future<String> _studentSectionText({
    required PersonRole role,
    required String section,
  }) async {
    final sectionName = section.trim();
    if (role != PersonRole.student || sectionName.isEmpty) return sectionName;
    final app = AppScope.of(context);
    final query = await app.repository
        .rootCollection('sections')
        .where('name', isEqualTo: sectionName)
        .limit(1)
        .get();
    if (query.docs.isEmpty) return sectionName;
    final data = query.docs.first.data();
    final gradeLevel = (data['gradeLevel'] as String? ?? '').trim();
    final gradeText = _gradeLabel(gradeLevel);
    return gradeText.isEmpty ? sectionName : '$gradeText - $sectionName';
  }

  String _gradeLabel(String gradeLevel) {
    if (gradeLevel.isEmpty) return '';
    if (gradeLevel.toLowerCase().startsWith('grade')) return gradeLevel;
    return 'Grade $gradeLevel';
  }

  Future<void> _showScanIssueDialog(String message) async {
    final timer = Timer(
      Duration(seconds: _viewModel.settings.scanIssueAutoCloseSeconds),
      () {
        if (!mounted) return;
        final navigator = Navigator.of(context, rootNavigator: true);
        if (navigator.canPop()) navigator.pop();
      },
    );
    try {
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Scan not recorded'),
          content: Text(_cleanErrorMessage(message)),
          actions: [
            FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } finally {
      timer.cancel();
      _viewModel.clearResult();
    }
  }

  String _cleanErrorMessage(String message) {
    return message
        .replaceFirst('Bad state: ', '')
        .replaceFirst('Exception: ', '')
        .trim();
  }

  Future<_GatePassReasonDetails?> _showGatePassReasonDialog() {
    return showDialog<_GatePassReasonDetails>(
      context: context,
      builder: (_) => _GatePassReasonDialog(
        initialBusinessType: _viewModel.teacherBusinessType,
        initialExpectedToReturn: _viewModel.expectedToReturn,
        wordLimit: _viewModel.settings.gatePassReasonWordLimit,
      ),
    );
  }

  String _scannerErrorMessage(MobileScannerException error) {
    return switch (error.errorCode) {
      MobileScannerErrorCode.permissionDenied =>
        'Camera permission is required to scan IDs.',
      MobileScannerErrorCode.unsupported =>
        'Barcode scanning is not supported on this device.',
      _ => 'Unable to start the camera scanner. Use manual ID entry below.',
    };
  }
}

class _ScanFeedbackPage extends StatefulWidget {
  const _ScanFeedbackPage({
    required this.data,
    required this.autoCloseSeconds,
    required this.onDone,
  });

  final _ScanFeedbackData data;
  final int autoCloseSeconds;
  final VoidCallback onDone;

  @override
  State<_ScanFeedbackPage> createState() => _ScanFeedbackPageState();
}

class _ScanFeedbackPageState extends State<_ScanFeedbackPage> {
  Timer? _timer;
  late int _remainingSeconds;
  bool _done = false;

  @override
  void initState() {
    super.initState();
    _remainingSeconds = widget.autoCloseSeconds.clamp(1, 30).toInt();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_remainingSeconds <= 1) {
        _finish();
        return;
      }
      setState(() => _remainingSeconds--);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sectionText = widget.data.sectionText;
    return SizedBox.expand(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: MediaQuery.sizeOf(context).height - 160,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.check_circle,
                    size: 96,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Scan Recorded',
                    style: theme.textTheme.headlineMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    widget.data.fullName,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    '${widget.data.idLabel}: ${widget.data.personId}',
                    style: theme.textTheme.titleMedium,
                    textAlign: TextAlign.center,
                  ),
                  if (widget.data.isStudent &&
                      sectionText.trim().isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      sectionText,
                      style: theme.textTheme.titleMedium,
                      textAlign: TextAlign.center,
                    ),
                  ],
                  const SizedBox(height: 20),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    alignment: WrapAlignment.center,
                    children: [
                      Chip(label: Text(widget.data.roleLabel)),
                      Chip(label: Text(widget.data.actionLabel)),
                      Chip(label: Text(widget.data.statusLabel)),
                      Chip(label: Text(widget.data.syncLabel)),
                    ],
                  ),
                  const SizedBox(height: 28),
                  FilledButton.icon(
                    icon: const Icon(Icons.qr_code_scanner),
                    label: Text('Scan Another ($_remainingSeconds)'),
                    onPressed: _finish,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _finish() {
    if (_done) return;
    _done = true;
    _timer?.cancel();
    widget.onDone();
  }
}

class _ScanFeedbackData {
  const _ScanFeedbackData({
    required this.fullName,
    required this.personId,
    required this.role,
    required this.sectionText,
    required this.actionLabel,
    required this.statusLabel,
    required this.syncLabel,
  });

  final String fullName;
  final String personId;
  final PersonRole role;
  final String sectionText;
  final String actionLabel;
  final String statusLabel;
  final String syncLabel;

  bool get isStudent => role == PersonRole.student;

  String get roleLabel => role.label;

  String get idLabel => role == PersonRole.student ? 'LRN' : 'Teacher ID';

  factory _ScanFeedbackData.fromAttendanceLog(
    AttendanceLog log, {
    required String sectionText,
  }) {
    return _ScanFeedbackData(
      fullName: log.fullName,
      personId: log.personId,
      role: log.personRole,
      sectionText: sectionText,
      actionLabel: log.attendanceType.label,
      statusLabel: log.attendanceStatus.label,
      syncLabel: log.syncStatus.label,
    );
  }

  factory _ScanFeedbackData.fromGatePassLog(
    GatePassLog log, {
    required String sectionText,
  }) {
    return _ScanFeedbackData(
      fullName: log.fullName,
      personId: log.personId,
      role: log.personRole,
      sectionText: sectionText,
      actionLabel: log.returnTime == null
          ? 'Gate Pass Log Out'
          : 'Gate Pass Return',
      statusLabel: log.status.label,
      syncLabel: log.syncStatus.label,
    );
  }
}

class _ScannerActionDropdown extends StatelessWidget {
  const _ScannerActionDropdown({required this.viewModel});

  final ScannerViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    if (viewModel.mode == ScannerLogMode.attendance) {
      return DropdownButtonFormField<AttendanceType>(
        initialValue: viewModel.type,
        decoration: const InputDecoration(
          labelText: 'Attendance action',
          prefixIcon: Icon(Icons.schedule_outlined),
        ),
        items: [
          for (final type in AttendanceType.scannerTypes)
            DropdownMenuItem(value: type, child: Text(type.label)),
        ],
        onChanged: (value) {
          if (value == null) return;
          viewModel.selectType(value);
        },
      );
    }

    return DropdownButtonFormField<GatePassAction>(
      initialValue: viewModel.gatePassAction,
      decoration: const InputDecoration(
        labelText: 'Gate pass action',
        prefixIcon: Icon(Icons.meeting_room_outlined),
      ),
      items: [
        for (final action in GatePassAction.values)
          DropdownMenuItem(value: action, child: Text(action.label)),
      ],
      onChanged: (value) {
        if (value == null) return;
        viewModel.selectGatePassAction(value);
      },
    );
  }
}

class _GatePassReasonDialog extends StatefulWidget {
  const _GatePassReasonDialog({
    required this.initialBusinessType,
    required this.initialExpectedToReturn,
    required this.wordLimit,
  });

  final TeacherBusinessType initialBusinessType;
  final bool initialExpectedToReturn;
  final int wordLimit;

  @override
  State<_GatePassReasonDialog> createState() => _GatePassReasonDialogState();
}

class _GatePassReasonDialogState extends State<_GatePassReasonDialog> {
  final _reason = TextEditingController();
  late TeacherBusinessType _businessType;
  late bool _expectedToReturn;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _businessType = widget.initialBusinessType;
    _expectedToReturn = widget.initialExpectedToReturn;
  }

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final words = _wordCount(_reason.text);
    return AlertDialog(
      title: const Text('Gate Pass Reason'),
      content: SizedBox(
        width: 460,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _reason,
              minLines: 3,
              maxLines: 5,
              decoration: InputDecoration(
                labelText: 'Reason for going outside',
                alignLabelWithHint: true,
                errorText: _errorText,
              ),
              onChanged: (_) => setState(() => _errorText = null),
            ),
            const SizedBox(height: 6),
            Text('$words / ${widget.wordLimit} words'),
            const SizedBox(height: 16),
            DropdownButtonFormField<TeacherBusinessType>(
              initialValue: _businessType,
              decoration: const InputDecoration(
                labelText: 'Teacher business type',
              ),
              items: [
                for (final type in TeacherBusinessType.values)
                  DropdownMenuItem(value: type, child: Text(type.label)),
              ],
              onChanged: (value) {
                if (value == null) return;
                setState(() => _businessType = value);
              },
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Expected to return'),
              value: _expectedToReturn,
              onChanged: (value) {
                setState(() => _expectedToReturn = value);
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(onPressed: _submit, child: const Text('Continue')),
      ],
    );
  }

  void _submit() {
    final trimmed = _reason.text.trim();
    final wordCount = _wordCount(trimmed);
    if (trimmed.isEmpty) {
      setState(() {
        _errorText = 'Please enter the reason for going outside.';
      });
      return;
    }
    if (wordCount > widget.wordLimit) {
      setState(() {
        _errorText =
            'Reason is too long. Please keep it within ${widget.wordLimit} words.';
      });
      return;
    }
    Navigator.of(context).pop(
      _GatePassReasonDetails(
        reason: trimmed,
        teacherBusinessType: _businessType,
        expectedToReturn: _expectedToReturn,
      ),
    );
  }

  int _wordCount(String value) {
    return value
        .trim()
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty)
        .length;
  }
}

class _GatePassReasonDetails {
  const _GatePassReasonDetails({
    required this.reason,
    required this.teacherBusinessType,
    required this.expectedToReturn,
  });

  final String reason;
  final TeacherBusinessType teacherBusinessType;
  final bool expectedToReturn;
}
