part of '../school_year_page.dart';

class _SchoolYearDetails extends StatelessWidget {
  const _SchoolYearDetails({required this.schoolYear, this.onArchive});

  final SchoolYear schoolYear;
  final VoidCallback? onArchive;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final terms = [
      (label: '1st Term', start: _fmt(0, true), end: _fmt(0, false)),
      (label: '2nd Term', start: _fmt(1, true), end: _fmt(1, false)),
      (label: '3rd Term', start: _fmt(2, true), end: _fmt(2, false)),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Divider(height: 1, color: theme.colorScheme.outlineVariant),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'TERM SCHEDULE',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 12,
                runSpacing: 10,
                children: [
                  for (final t in terms)
                    _TermChip(label: t.label, start: t.start, end: t.end),
                ],
              ),
              // Archive action — only for the active school year
              if (onArchive != null) ...[
                const SizedBox(height: 16),
                Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 16,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'New school year creation is locked until this year is archived.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    OutlinedButton.icon(
                      icon: const Icon(Icons.archive_outlined, size: 18),
                      label: const Text('Archive'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red.shade700,
                        side: BorderSide(color: Colors.red.shade300),
                      ),
                      onPressed: () => _confirmArchive(context),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  String? _fmt(int index, bool start) {
    final list = start ? schoolYear.termStarts : schoolYear.termEnds;
    final date = list.length > index ? list[index] : null;
    if (date == null) return null;
    return DateFormat('MMM d, yyyy').format(date);
  }

  Future<void> _confirmArchive(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Archive school year?'),
        content: Text(
          'This will mark ${schoolYear.name} as archived and allow you to create a new active school year.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton.icon(
            icon: const Icon(Icons.archive_outlined),
            label: const Text('Archive'),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
          ),
        ],
      ),
    );
    if (confirmed == true) onArchive?.call();
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Small reusable widgets
// ─────────────────────────────────────────────────────────────────────────────
