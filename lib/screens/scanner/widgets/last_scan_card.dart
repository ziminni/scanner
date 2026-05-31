part of '../scanner_screen.dart';

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
