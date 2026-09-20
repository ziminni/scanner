part of '../scanner_screen.dart';

class _LastScanCard extends StatelessWidget {
  const _LastScanCard({required this.log});

  final AttendanceLog log;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: ScannerTheme.panelDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.history, color: ScannerTheme.primary),
              const SizedBox(width: 8),
              Text(
                'Last attendance scan',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: ScannerTheme.mutedText,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            log.fullName,
            style: theme.textTheme.titleLarge?.copyWith(
              color: ScannerTheme.text,
              fontWeight: FontWeight.w800,
            ),
          ),
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
            style: theme.textTheme.bodyMedium?.copyWith(
              color: ScannerTheme.mutedText,
            ),
          ),
        ],
      ),
    );
  }
}

class _LastGatePassCard extends StatelessWidget {
  const _LastGatePassCard({required this.log});

  final GatePassLog log;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: ScannerTheme.panelDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.meeting_room_outlined,
                color: ScannerTheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                'Last gate pass scan',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: ScannerTheme.mutedText,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            log.fullName,
            style: theme.textTheme.titleLarge?.copyWith(
              color: ScannerTheme.text,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              Chip(label: Text(log.personRole.label)),
              Chip(label: Text(log.status.label)),
              if (log.teacherBusinessType != null)
                Chip(label: Text(log.teacherBusinessType!.label)),
              Chip(label: Text(log.syncStatus.label)),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Reason: ${log.reason}',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: ScannerTheme.mutedText,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            log.returnTime == null
                ? 'Logged out at ${log.exitTimeText} by ${log.scannedBy}.'
                : 'Returned at ${log.returnTimeText} after ${log.durationMinutes} minutes.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: ScannerTheme.mutedText,
            ),
          ),
        ],
      ),
    );
  }
}
