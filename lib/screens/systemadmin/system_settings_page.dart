import 'package:flutter/material.dart';

import '../../core/services/app_controller.dart';
import '../../models/models.dart';
import '../../shared/widgets/admin_widgets.dart';

class SystemSettingsPage extends StatefulWidget {
  const SystemSettingsPage({super.key});

  @override
  State<SystemSettingsPage> createState() => _SystemSettingsPageState();
}

class _SystemSettingsPageState extends State<SystemSettingsPage> {
  final _timeIn = TextEditingController();
  final _timeOut = TextEditingController();
  final _early = TextEditingController();
  final _duplicate = TextEditingController();
  final _scannerCooldown = TextEditingController();
  final _issueAutoClose = TextEditingController();
  final _successFeedback = TextEditingController();
  final _reasonLimit = TextEditingController();

  Future<SystemSettings>? _settingsFuture;
  bool _loaded = false;
  bool _saving = false;
  String? _message;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _settingsFuture ??= AppScope.of(context).attendance.loadSettings();
  }

  @override
  void dispose() {
    _timeIn.dispose();
    _timeOut.dispose();
    _early.dispose();
    _duplicate.dispose();
    _scannerCooldown.dispose();
    _issueAutoClose.dispose();
    _successFeedback.dispose();
    _reasonLimit.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AdminPage(
      title: 'System Settings',
      actions: [
        FilledButton.icon(
          icon: _saving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.save_outlined),
          label: const Text('Save settings'),
          onPressed: _saving ? null : _save,
        ),
      ],
      child: FutureBuilder<SystemSettings>(
        future: _settingsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting && !_loaded) {
            return const Center(child: CircularProgressIndicator());
          }
          final settings = snapshot.data ?? const SystemSettings();
          if (!_loaded) {
            _applySettings(settings);
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_message != null) ...[
                Text(_message!),
                const SizedBox(height: 12),
              ],
              _SettingsSection(
                icon: Icons.schedule_outlined,
                title: 'Attendance Rules',
                subtitle:
                    'Controls the default student time in/out, early status, and duplicate attendance window.',
                children: [
                  _TimeSettingField(
                    controller: _timeIn,
                    label: 'Student time in',
                    onTap: () => _pickTime(_timeIn),
                  ),
                  _TimeSettingField(
                    controller: _timeOut,
                    label: 'Student time out',
                    onTap: () => _pickTime(_timeOut),
                  ),
                  _NumberSettingField(
                    controller: _early,
                    label: 'Early threshold minutes',
                    helper:
                        'Students arriving this many minutes before time in count as early.',
                  ),
                  _NumberSettingField(
                    controller: _duplicate,
                    label: 'Duplicate window minutes',
                    helper:
                        'Prevents repeated attendance scans in the same session from being counted again.',
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _SettingsSection(
                icon: Icons.qr_code_scanner_outlined,
                title: 'Scanner Automation',
                subtitle:
                    'Controls scanner timing, automatic feedback closing, and gate pass reason limits.',
                children: [
                  _NumberSettingField(
                    controller: _scannerCooldown,
                    label: 'Detection cooldown seconds',
                    helper:
                        'How long the scanner ignores the same ID after it was detected.',
                  ),
                  _NumberSettingField(
                    controller: _issueAutoClose,
                    label: 'Error modal auto-close seconds',
                    helper:
                        'How long duplicate/error dialogs stay open before closing automatically.',
                  ),
                  _NumberSettingField(
                    controller: _successFeedback,
                    label: 'Success feedback seconds',
                    helper:
                        'How long the full-screen success scan feedback stays open.',
                  ),
                  _NumberSettingField(
                    controller: _reasonLimit,
                    label: 'Gate pass reason word limit',
                    helper:
                        'Maximum words allowed for the scanner gate pass reason field.',
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  void _applySettings(SystemSettings settings) {
    _timeIn.text = settings.studentTimeIn;
    _timeOut.text = settings.studentTimeOut;
    _early.text = '${settings.earlyBeforeMinutes}';
    _duplicate.text = '${settings.duplicateWindowMinutes}';
    _scannerCooldown.text = '${settings.scannerDetectionCooldownSeconds}';
    _issueAutoClose.text = '${settings.scanIssueAutoCloseSeconds}';
    _successFeedback.text = '${settings.successFeedbackSeconds}';
    _reasonLimit.text = '${settings.gatePassReasonWordLimit}';
    _loaded = true;
  }

  Future<void> _pickTime(TextEditingController controller) async {
    final initial = _parseTime(controller.text);
    final picked = await showTimePicker(context: context, initialTime: initial);
    if (picked == null) return;
    controller.text =
        '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
  }

  TimeOfDay _parseTime(String value) {
    final parts = value.split(':');
    if (parts.length != 2) return const TimeOfDay(hour: 7, minute: 0);
    return TimeOfDay(
      hour: int.tryParse(parts[0])?.clamp(0, 23).toInt() ?? 7,
      minute: int.tryParse(parts[1])?.clamp(0, 59).toInt() ?? 0,
    );
  }

  Future<void> _save() async {
    final app = AppScope.of(context);
    setState(() {
      _saving = true;
      _message = null;
    });
    try {
      final settings = SystemSettings(
        studentTimeIn: _timeIn.text,
        studentTimeOut: _timeOut.text,
        earlyBeforeMinutes: _positiveInt(_early.text, fallback: 15, max: 180),
        duplicateWindowMinutes: _positiveInt(
          _duplicate.text,
          fallback: 240,
          max: 1440,
        ),
        scannerDetectionCooldownSeconds: _positiveInt(
          _scannerCooldown.text,
          fallback: 2,
          min: 1,
          max: 30,
        ),
        scanIssueAutoCloseSeconds: _positiveInt(
          _issueAutoClose.text,
          fallback: 8,
          min: 1,
          max: 60,
        ),
        successFeedbackSeconds: _positiveInt(
          _successFeedback.text,
          fallback: 3,
          min: 1,
          max: 30,
        ),
        gatePassReasonWordLimit: _positiveInt(
          _reasonLimit.text,
          fallback: 52,
          min: 10,
          max: 200,
        ),
      );
      await app.attendance.updateSettings(settings, app.currentUser!);
      if (!mounted) return;
      setState(() {
        _message = 'System settings saved.';
        _settingsFuture = Future.value(settings);
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _message = 'Unable to save settings: $error');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  int _positiveInt(
    String value, {
    required int fallback,
    int min = 0,
    required int max,
  }) {
    final parsed = int.tryParse(value.trim()) ?? fallback;
    return parsed.clamp(min, max).toInt();
  }
}

class _SettingsSection extends StatelessWidget {
  const _SettingsSection({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.children,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DataSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: theme.colorScheme.primary),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withAlpha(166),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(spacing: 12, runSpacing: 12, children: children),
        ],
      ),
    );
  }
}

class _TimeSettingField extends StatelessWidget {
  const _TimeSettingField({
    required this.controller,
    required this.label,
    required this.onTap,
  });

  final TextEditingController controller;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 220,
      child: TextField(
        controller: controller,
        readOnly: true,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: const Icon(Icons.access_time),
        ),
        onTap: onTap,
      ),
    );
  }
}

class _NumberSettingField extends StatelessWidget {
  const _NumberSettingField({
    required this.controller,
    required this.label,
    required this.helper,
  });

  final TextEditingController controller;
  final String label;
  final String helper;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 260,
      child: TextField(
        controller: controller,
        keyboardType: TextInputType.number,
        decoration: InputDecoration(labelText: label, helperText: helper),
      ),
    );
  }
}
