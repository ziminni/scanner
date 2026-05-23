import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../core/services/app_controller.dart';
import '../../../models/enums.dart';
import '../../../models/models.dart';

class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  final _manualId = TextEditingController();
  AttendanceType _type = AttendanceType.morningTimeIn;
  AttendanceLog? _lastLog;
  String? _message;
  bool _busy = false;

  @override
  void dispose() {
    _manualId.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final type in AttendanceType.values)
              ChoiceChip(
                label: Text(type.label),
                selected: _type == type,
                onSelected: (_) => setState(() => _type = type),
              ),
          ],
        ),
        const SizedBox(height: 16),
        AspectRatio(
          aspectRatio: 4 / 3,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: ColoredBox(
              color: Colors.black,
              child: MobileScanner(
                onDetect: (capture) {
                  final code = capture.barcodes.firstOrNull?.rawValue;
                  if (code != null && !_busy) _submit(code);
                },
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
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
              icon: const Icon(Icons.check),
              label: const Text('Log'),
              onPressed: _busy ? null : () => _submit(_manualId.text),
            ),
          ],
        ),
        if (_message != null) ...[
          const SizedBox(height: 12),
          Text(_message!, style: TextStyle(color: theme.colorScheme.error)),
        ],
        if (_lastLog != null) ...[
          const SizedBox(height: 16),
          _LastScanCard(log: _lastLog!),
        ],
      ],
    );
  }

  Future<void> _submit(String raw) async {
    final id = raw.trim();
    if (id.isEmpty) return;
    final app = AppScope.of(context);
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      final log = await app.attendance.scanId(
        scannedId: id,
        type: _type,
        scanner: app.currentUser!,
        deviceId: 'device-${app.currentUser!.id}',
      );
      setState(() {
        _lastLog = log;
        _manualId.clear();
      });
    } catch (error) {
      setState(() => _message = error.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }
}

class _LastScanCard extends StatelessWidget {
  const _LastScanCard({required this.log});

  final AttendanceLog log;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: theme.colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(log.fullName, style: theme.textTheme.titleLarge),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              Chip(label: Text(log.personRole.label)),
              Chip(label: Text(log.attendanceType.label)),
              Chip(label: Text(log.attendanceStatus.label)),
              Chip(label: Text(log.syncStatus.label)),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Scanned by ${log.scannedBy} on ${log.deviceId} at ${log.timeText}',
          ),
        ],
      ),
    );
  }
}
