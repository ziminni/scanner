import 'package:flutter/material.dart';

import '../scanner_theme.dart';
import '../viewmodels/scanner_home_viewmodel.dart';

class HomeSyncStatus extends StatelessWidget {
  const HomeSyncStatus({
    super.key,
    required this.studentStatus,
    required this.teacherStatus,
    required this.onSyncStudents,
    required this.onSyncTeachers,
  });

  final PeopleSyncStatus studentStatus;
  final PeopleSyncStatus teacherStatus;
  final Future<void> Function() onSyncStudents;
  final Future<void> Function() onSyncTeachers;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: ScannerTheme.panelDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: ScannerTheme.primarySoft,
                  borderRadius: BorderRadius.circular(13),
                ),
                child: const Icon(
                  Icons.cloud_done_outlined,
                  color: ScannerTheme.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Offline Data Sync',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: ScannerTheme.text,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Download students and teachers for offline scanning.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: ScannerTheme.mutedText,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 560;
              final tiles = [
                _PeopleSyncTile(
                  status: studentStatus,
                  icon: Icons.school_outlined,
                  onSync: onSyncStudents,
                ),
                _PeopleSyncTile(
                  status: teacherStatus,
                  icon: Icons.badge_outlined,
                  onSync: onSyncTeachers,
                ),
              ];
              if (compact) {
                return Column(
                  children: [
                    tiles.first,
                    const SizedBox(height: 10),
                    tiles.last,
                  ],
                );
              }
              return Row(
                children: [
                  Expanded(child: tiles.first),
                  const SizedBox(width: 12),
                  Expanded(child: tiles.last),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class LoggedScanSyncStatus extends StatelessWidget {
  const LoggedScanSyncStatus({
    super.key,
    required this.status,
    required this.onSyncLoggedPeople,
  });

  final PeopleSyncStatus status;
  final Future<void> Function() onSyncLoggedPeople;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: ScannerTheme.panelDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: ScannerTheme.primarySoft,
                  borderRadius: BorderRadius.circular(13),
                ),
                child: const Icon(
                  Icons.sync_alt_outlined,
                  color: ScannerTheme.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Logged Scan Sync',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: ScannerTheme.text,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Offline scan logs automatically upload when the system goes online.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: ScannerTheme.mutedText,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _PeopleSyncTile(
            status: status,
            icon: Icons.fact_check_outlined,
            onSync: onSyncLoggedPeople,
          ),
        ],
      ),
    );
  }
}

class _PeopleSyncTile extends StatelessWidget {
  const _PeopleSyncTile({
    required this.status,
    required this.icon,
    required this.onSync,
  });

  final PeopleSyncStatus status;
  final IconData icon;
  final Future<void> Function() onSync;

  @override
  Widget build(BuildContext context) {
    final failed = status.error != null;
    final color = failed
        ? Colors.red.shade700
        : status.hasSynced
        ? ScannerTheme.primary
        : ScannerTheme.mutedText;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: ScannerTheme.surfaceSoft,
        border: Border.all(color: ScannerTheme.border),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        status.roleLabel,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: ScannerTheme.text,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    _SyncPill(label: status.statusLabel, color: color),
                  ],
                ),
                const SizedBox(height: 5),
                Row(
                  children: [
                    Text(
                      '${status.countLabel} • ',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: ScannerTheme.mutedText,
                      ),
                    ),
                    Expanded(
                      child: _AutoScrollingSyncText(
                        text: status.lastSyncLabel,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: ScannerTheme.mutedText,
                        ),
                      ),
                    ),
                  ],
                ),
                if (failed) ...[
                  const SizedBox(height: 4),
                  Text(
                    status.error!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: Colors.red.shade700),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          status.syncing
              ? const SizedBox.square(
                  dimension: 22,
                  child: CircularProgressIndicator(strokeWidth: 2.4),
                )
              : IconButton(
                  tooltip: 'Sync ${status.roleLabel.toLowerCase()}',
                  onPressed: onSync,
                  icon: const Icon(Icons.sync),
                ),
        ],
      ),
    );
  }
}

class _AutoScrollingSyncText extends StatefulWidget {
  const _AutoScrollingSyncText({required this.text, required this.style});

  final String text;
  final TextStyle? style;

  @override
  State<_AutoScrollingSyncText> createState() => _AutoScrollingSyncTextState();
}

class _AutoScrollingSyncTextState extends State<_AutoScrollingSyncText>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  Animation<double>? _animation;
  double _lastOverflow = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this)
      ..addStatusListener((status) {
        if (status != AnimationStatus.completed) return;
        Future<void>.delayed(const Duration(milliseconds: 900), () {
          if (!mounted || _animation == null) return;
          _controller
            ..reset()
            ..forward();
        });
      });
  }

  @override
  void didUpdateWidget(covariant _AutoScrollingSyncText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text || oldWidget.style != widget.style) {
      _lastOverflow = 0;
      _animation = null;
      _controller.stop();
      _controller.reset();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final painter = TextPainter(
          text: TextSpan(text: widget.text, style: widget.style),
          maxLines: 1,
          textDirection: Directionality.of(context),
        )..layout();
        final overflow = (painter.width - constraints.maxWidth).clamp(
          0.0,
          double.infinity,
        );

        if (overflow <= 0) {
          _controller.stop();
          return Text(
            widget.text,
            maxLines: 1,
            overflow: TextOverflow.clip,
            style: widget.style,
          );
        }

        if (_animation == null || overflow != _lastOverflow) {
          _lastOverflow = overflow;
          _controller.duration = Duration(
            milliseconds: (1600 + overflow * 28).round(),
          );
          _animation = Tween<double>(begin: 0, end: overflow + 10).animate(
            CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
          );
          _controller.forward(from: 0);
        }

        return ClipRect(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(-(_animation?.value ?? 0), 0),
                child: child,
              );
            },
            child: Text(
              widget.text,
              maxLines: 1,
              softWrap: false,
              style: widget.style,
            ),
          ),
        );
      },
    );
  }
}

class _SyncPill extends StatelessWidget {
  const _SyncPill({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withAlpha(24),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
