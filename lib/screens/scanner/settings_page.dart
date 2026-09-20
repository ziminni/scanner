import 'package:flutter/material.dart';

import '../../core/services/app_controller.dart';
import '../../models/models.dart';
import 'scanner_theme.dart';

class ScannerSettingsPage extends StatefulWidget {
  const ScannerSettingsPage({super.key});

  @override
  State<ScannerSettingsPage> createState() => _ScannerSettingsPageState();
}

class _ScannerSettingsPageState extends State<ScannerSettingsPage> {
  final _teacherSmsRecipient = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  SystemSettings _settings = const SystemSettings();
  bool _loading = true;
  bool _saving = false;
  bool _loadStarted = false;
  String? _error;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_loadStarted) return;
    _loadStarted = true;
    _loadSettings();
  }

  @override
  void dispose() {
    _teacherSmsRecipient.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ColoredBox(
      color: ScannerTheme.background,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            padding: const EdgeInsets.all(22),
            decoration: ScannerTheme.panelDecoration(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: ScannerTheme.primarySoft,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(
                        Icons.settings_outlined,
                        color: ScannerTheme.primary,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Scanner Settings',
                            style: theme.textTheme.headlineSmall?.copyWith(
                              color: ScannerTheme.text,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Manage scanner notifications and behavior.',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: ScannerTheme.mutedText,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 22),
                if (_loading)
                  const Center(child: CircularProgressIndicator())
                else
                  Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Teacher Scan SMS Receiver',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: ScannerTheme.text,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'When a teacher is scanned, SMS notifications will be sent to this number.',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: ScannerTheme.mutedText,
                          ),
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _teacherSmsRecipient,
                          keyboardType: TextInputType.phone,
                          decoration: const InputDecoration(
                            labelText: 'Receiver phone number',
                            hintText: '09XXXXXXXXX',
                            prefixIcon: Icon(Icons.sms_outlined),
                          ),
                          validator: _validatePhoneNumber,
                        ),
                        if (_error != null) ...[
                          const SizedBox(height: 10),
                          Text(
                            _error!,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.error,
                            ),
                          ),
                        ],
                        const SizedBox(height: 18),
                        Align(
                          alignment: Alignment.centerRight,
                          child: FilledButton.icon(
                            style: FilledButton.styleFrom(
                              backgroundColor: ScannerTheme.primary,
                              foregroundColor: Colors.white,
                            ),
                            onPressed: _saving ? null : _save,
                            icon: _saving
                                ? const SizedBox.square(
                                    dimension: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Icon(Icons.save_outlined),
                            label: Text(_saving ? 'Saving...' : 'Save'),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _loadSettings() async {
    try {
      final settings = await AppScope.of(context).attendance.loadSettings();
      if (!mounted) return;
      setState(() {
        _settings = settings;
        _teacherSmsRecipient.text = settings.teacherScanSmsRecipient;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.toString();
        _loading = false;
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final app = AppScope.of(context);
      final nextSettings = _settings.copyWith(
        teacherScanSmsRecipient: _teacherSmsRecipient.text.trim(),
      );
      await app.attendance.updateSettings(nextSettings, app.currentUser!);
      if (!mounted) return;
      setState(() {
        _settings = nextSettings;
        _saving = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Scanner settings saved.')));
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.toString();
        _saving = false;
      });
    }
  }

  String? _validatePhoneNumber(String? value) {
    final number = value?.trim() ?? '';
    if (number.isEmpty) return null;
    if (!RegExp(r'^09\d{9}$').hasMatch(number)) {
      return 'Phone number must start with 09 and be 11 digits.';
    }
    return null;
  }
}
