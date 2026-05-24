import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../core/services/app_controller.dart';
import '../../models/enums.dart';
import '../../models/models.dart';
import '../../viewmodels/scanner_viewmodel.dart';

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

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_viewModelReady) return;
    _viewModel = ScannerViewModel(AppScope.of(context));
    _viewModelReady = true;
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
    return AnimatedBuilder(
      animation: _viewModel,
      builder: (context, _) {
        final theme = Theme.of(context);
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final type in AttendanceType.scannerTypes)
                  ChoiceChip(
                    label: Text(type.label),
                    selected: _viewModel.type == type,
                    onSelected: (_) => _viewModel.selectType(type),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            AspectRatio(
              aspectRatio: 4 / 3,
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
                          width: 260,
                          height: 160,
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.white, width: 2),
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
                            onPressed: () => _scannerController.toggleTorch(),
                          ),
                          const SizedBox(width: 8),
                          IconButton.filledTonal(
                            tooltip: 'Switch camera',
                            icon: const Icon(Icons.cameraswitch_outlined),
                            onPressed: () => _scannerController.switchCamera(),
                          ),
                        ],
                      ),
                    ),
                  ],
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
                  onPressed: _viewModel.busy
                      ? null
                      : () => _submit(_manualId.text),
                ),
              ],
            ),
            if (_viewModel.message != null) ...[
              const SizedBox(height: 12),
              Text(
                _viewModel.message!,
                style: TextStyle(color: theme.colorScheme.error),
              ),
            ],
            if (_viewModel.lastLog != null) ...[
              const SizedBox(height: 16),
              _LastScanCard(log: _viewModel.lastLog!),
            ],
          ],
        );
      },
    );
  }

  Future<void> _submit(String raw) async {
    await _viewModel.submit(raw);
    if (mounted && raw.trim().isNotEmpty) _manualId.clear();
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
